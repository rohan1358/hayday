package com.kebunceria.farm

import android.provider.Settings
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Source
import com.google.firebase.firestore.SetOptions
import java.security.MessageDigest
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject

/** Registers an anonymous player and stores their app-scoped Android identifier in Firestore. */
class FarmUserFirestorePlugin(godot: Godot) : GodotPlugin(godot) {
    companion object {
        private const val TAG = "FarmUserFirestore"
        private val USER_READY = SignalInfo("user_ready", String::class.java)
        private val USER_ERROR = SignalInfo("user_error", String::class.java)
        private val TREES_SAVED = SignalInfo("cut_down_trees_saved", String::class.java)
        private val TREES_ERROR = SignalInfo("cut_down_trees_error", String::class.java)
        private val TREES_CONFLICT = SignalInfo("cut_down_trees_conflict", String::class.java)
        private val USER_TREES_UPDATED = SignalInfo("user_tree_count_updated", String::class.java)
    }

    private var starting = false
    private var userId: String? = null
    private var userListener: ListenerRegistration? = null

    override fun getPluginName() = "FarmUserFirestore"

    override fun getPluginSignals() = setOf(
        USER_READY, USER_ERROR, TREES_SAVED, TREES_ERROR,
        TREES_CONFLICT, USER_TREES_UPDATED
    )

    private fun localDeviceId(): String {
        val context = godot.context.applicationContext
        val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
        if (androidId.isNullOrBlank()) return ""
        val input = "$androidId:${context.packageName}"
        return MessageDigest.getInstance("SHA-256")
            .digest(input.toByteArray(Charsets.UTF_8))
            .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
    }

    @UsedByGodot
    fun getDeviceId(): String = try {
        localDeviceId()
    } catch (error: Exception) {
        Log.e(TAG, "Device ID generation failed", error)
        ""
    }

    @UsedByGodot
    fun initializeUser() {
        if (starting || userId != null) return
        starting = true

        try {
            val context = godot.context.applicationContext
            if (FirebaseApp.getApps(context).isEmpty()) {
                FirebaseApp.initializeApp(context)
            }
            val auth = FirebaseAuth.getInstance()
            val currentUser = auth.currentUser
            if (currentUser != null) {
                registerUser(currentUser.uid)
            } else {
                auth.signInAnonymously()
                    .addOnSuccessListener { result ->
                        val uid = result.user?.uid
                        if (uid.isNullOrBlank()) {
                            failInitialization("Firebase tidak mengembalikan User ID.")
                        } else {
                            registerUser(uid)
                        }
                    }
                    .addOnFailureListener { error ->
                        failInitialization("Firebase Authentication gagal.", error)
                    }
            }
        } catch (error: Exception) {
            failInitialization("Firebase gagal diinisialisasi.", error)
        }
    }

    private fun registerUser(uid: String) {
        try {
            val context = godot.context.applicationContext
            val androidId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            if (androidId.isNullOrBlank()) {
                failInitialization("Device ID Android tidak tersedia.")
                return
            }
            val deviceId = localDeviceId()
            val users = FirebaseFirestore.getInstance().collection("User")
            // Look up both current hashed IDs and older installations that stored
            // ANDROID_ID directly. Reuse their Firestore document when found.
            // A server lookup is mandatory to avoid duplicate registration.
            users.whereIn("DeviceID", listOf(deviceId, androidId)).get(Source.SERVER)
                .addOnSuccessListener { matches ->
                    val existing = matches.documents
                        .sortedWith(compareBy({ it.getString("DeviceID") != deviceId }, { it.id }))
                        .firstOrNull()
                    if (matches.size() > 1) {
                        Log.w(TAG, "Multiple legacy users have this DeviceID; reusing ${existing?.id}. Manual reconciliation needed.")
                    }
                    // The device-based ID serializes first-time registrations from separate
                    // anonymous Firebase sessions on the same device.
                    val document = users.document(existing?.id ?: deviceId)
                    loadUserDocument(document.id, deviceId, androidId)
                }
                .addOnFailureListener { error ->
                    failInitialization("Gagal memeriksa DeviceID di Firestore. Periksa izin query User.", error)
                }
        } catch (error: Exception) {
            failInitialization("Gagal menyiapkan data pengguna.", error)
        }
    }

    private fun loadUserDocument(canonicalUserId: String, deviceId: String, legacyAndroidId: String) {
        val document = FirebaseFirestore.getInstance().collection("User").document(canonicalUserId)
        // Read the server value before the game is allowed to synchronize tree progress.
        // Only initialize the count when it is missing or invalid.
        FirebaseFirestore.getInstance().runTransaction { transaction ->
                val snapshot = transaction.get(document)
                if (snapshot.exists() && snapshot.getString("DeviceID") !in setOf(deviceId, legacyAndroidId)) {
                    throw IllegalStateException("DeviceID telah digunakan oleh pengguna berbeda.")
                }
                val storedCount = snapshot.getLong("CutDownTreesAmount")
                val count = storedCount?.coerceIn(0L, Int.MAX_VALUE.toLong())?.toInt() ?: 0
                val changes = mutableMapOf<String, Any>()
                if (snapshot.getString("DeviceID") != deviceId) {
                    changes["DeviceID"] = deviceId
                }
                if (storedCount == null || storedCount != count.toLong()) {
                    changes["CutDownTreesAmount"] = count
                }
                if (changes.isNotEmpty()) {
                    transaction.set(document, changes, SetOptions.merge())
                }
                JSONObject()
                    .put("uid", canonicalUserId)
                    .put("DeviceID", deviceId)
                    .put("LastRewardRequestID", snapshot.getString("LastRewardRequestID") ?: "")
                    .put("CutDownTreesAmount", count)
                    .toString()
            }
                .addOnSuccessListener { userJson ->
                    userId = canonicalUserId
                    starting = false
                    Log.i(TAG, "User/$canonicalUserId loaded from Firestore")
                    emitSignal(USER_READY, userJson)
                    watchUserTrees(canonicalUserId)
                }
                .addOnFailureListener { error ->
                    failInitialization("Gagal memuat data pengguna dari Firestore.", error)
                }
    }

    @UsedByGodot
    fun updateCutDownTreesAmount(amount: Int, expectedAmount: Int) {
        val uid = userId
        if (uid == null || amount < 0 || expectedAmount < 0) {
            emitSignal(TREES_ERROR, "Pengguna belum siap atau jumlah pohon tidak valid.")
            return
        }

        try {
            val document = FirebaseFirestore.getInstance().collection("User").document(uid)
            FirebaseFirestore.getInstance().runTransaction { transaction ->
                val actual = transaction.get(document).getLong("CutDownTreesAmount") ?: 0L
                if (actual != expectedAmount.toLong()) {
                    Pair(false, actual)
                } else {
                    transaction.set(document, mapOf("CutDownTreesAmount" to amount), SetOptions.merge())
                    Pair(true, amount.toLong())
                }
            }.addOnSuccessListener { result ->
                    if (result.first) {
                        Log.i(TAG, "User/$uid CutDownTreesAmount saved: $amount")
                        emitSignal(TREES_SAVED, amount.toString())
                    } else {
                        // An admin may have reset the count during an in-flight write.
                        emitSignal(TREES_CONFLICT, result.second.toString())
                    }
                }
                .addOnFailureListener { error ->
                    Log.e(TAG, "CutDownTreesAmount write failed", error)
                    emitSignal(TREES_ERROR, treeWriteError(error))
                }
        } catch (error: Exception) {
            Log.e(TAG, "CutDownTreesAmount write failed", error)
            emitSignal(TREES_ERROR, treeWriteError(error))
        }
    }

    /** Observe admin edits to the tree count without requiring a game restart. */
    @UsedByGodot
    fun refreshUserTrees() {
        val uid = userId ?: return
        FirebaseFirestore.getInstance().collection("User").document(uid)
            .get(Source.SERVER)
            .addOnSuccessListener { snapshot ->
                if (snapshot.exists()) publishUserTrees(snapshot)
            }
            .addOnFailureListener { error ->
                Log.w(TAG, "Could not refresh the user's tree count", error)
            }
    }

    private fun publishUserTrees(snapshot: com.google.firebase.firestore.DocumentSnapshot) {
        emitSignal(USER_TREES_UPDATED, JSONObject()
            .put("CutDownTreesAmount", snapshot.getLong("CutDownTreesAmount") ?: 0L)
            .put("LastRewardRequestID", snapshot.getString("LastRewardRequestID") ?: "")
            .toString())
    }

    /** Observe admin edits to the tree count without requiring a game restart. */
    private fun watchUserTrees(uid: String) {
        userListener?.remove()
        userListener = FirebaseFirestore.getInstance().collection("User").document(uid)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.e(TAG, "User tree listener failed", error)
                    return@addSnapshotListener
                }
                if (snapshot == null || !snapshot.exists() ||
                    snapshot.metadata.hasPendingWrites() || snapshot.metadata.isFromCache) return@addSnapshotListener
                publishUserTrees(snapshot)
            }
    }

    private fun treeWriteError(error: Exception): String {
        return if (error.message.orEmpty().contains("PERMISSION_DENIED")) {
            "Firestore menolak perubahan CutDownTreesAmount (PERMISSION_DENIED). Periksa Firestore Rules."
        } else {
            "Jumlah pohon gagal disimpan ke Firestore: ${error.localizedMessage ?: "kesalahan tidak diketahui"}"
        }
    }

    private fun failInitialization(message: String, error: Exception? = null) {
        starting = false
        if (error != null) Log.e(TAG, message, error) else Log.e(TAG, message)
        val details = error?.message.orEmpty()
        val explanation = when {
            details.contains("CONFIGURATION_NOT_FOUND") ->
                "Firebase Authentication belum dikonfigurasi (CONFIGURATION_NOT_FOUND). Aktifkan provider Anonymous di Firebase Console."
            details.contains("OPERATION_NOT_ALLOWED") ->
                "Login Anonymous belum diaktifkan di Firebase Authentication."
            else -> message
        }
        emitSignal(USER_ERROR, explanation)
    }
}
