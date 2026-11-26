package com.kebunceria.farm

import android.util.Log
import android.content.pm.ApplicationInfo
import android.os.Build
import com.google.firebase.FirebaseApp
import com.google.firebase.remoteconfig.ConfigUpdate
import com.google.firebase.remoteconfig.ConfigUpdateListener
import com.google.firebase.remoteconfig.ConfigUpdateListenerRegistration
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigException
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject
import org.json.JSONArray

/** Makes Firebase's activated Remote Config values available to GDScript. */
class FarmRemoteConfigPlugin(godot: Godot) : GodotPlugin(godot) {
    companion object {
        private const val TAG = "FarmRemoteConfig"
        private const val ALLOW_EMULATOR_KEY = "AllowEmulator"
        private const val ALLOW_ALL_REGION_KEY = "AllowAllRegion"
        private const val ALLOWED_REGION_KEY = "AllowedRegion"
        private const val COOLDOWN_TREES_KEY = "CooldownCutDownTrees"
        private const val DEFAULT_TREE_COOLDOWN = "{\"min\":60,\"max\":120}"
        private const val SPAWN_TREES_KEY = "CooldownSpawnTrees"
        private const val DEFAULT_SPAWN_COOLDOWN = "{\"min\":300,\"max\":600}"
        private const val MAX_STANDING_TREES_KEY = "MaxStandingTrees"
        private const val DEFAULT_MAX_STANDING_TREES = 200L
        private const val MAX_DAILY_FREE_TREE_CUTS_KEY = "MaxDailyFreeTreeCuts"
        private const val DEFAULT_MAX_DAILY_FREE_TREE_CUTS = 3L
        private val CONFIG_READY = SignalInfo("config_ready", String::class.java)
        private val FLAGS = arrayOf(
            "EnableAdmob",
            "EnableAdmobBanner",
            "EnableAdmobInterstisial",
            "EnableAdmobIntermediaryBonus",
            "EnableAdmobReward",
            "EnableAdmobNativeAdvance",
            "EnableAdmobOpeningApp",
            ALLOW_EMULATOR_KEY,
            ALLOW_ALL_REGION_KEY
        )
    }

    private val config: FirebaseRemoteConfig? = try {
        // The Google Services Gradle plugin installs the Firebase initialization provider.
        val context = godot.context.applicationContext
        if (FirebaseApp.getApps(context).isEmpty()) {
            FirebaseApp.initializeApp(context)
        }
        val debugBuild = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        FirebaseRemoteConfig.getInstance().apply {
            setConfigSettingsAsync(
                FirebaseRemoteConfigSettings.Builder()
                    .setFetchTimeoutInSeconds(12L)
                    .setMinimumFetchIntervalInSeconds(if (debugBuild) 0L else 3600L)
                    .build()
            )
            setDefaultsAsync(FLAGS.associateWith { false } + mapOf(
                ALLOWED_REGION_KEY to "[]",
                COOLDOWN_TREES_KEY to DEFAULT_TREE_COOLDOWN,
                SPAWN_TREES_KEY to DEFAULT_SPAWN_COOLDOWN,
                MAX_STANDING_TREES_KEY to DEFAULT_MAX_STANDING_TREES,
                MAX_DAILY_FREE_TREE_CUTS_KEY to DEFAULT_MAX_DAILY_FREE_TREE_CUTS
            ))
        }
    } catch (e: Exception) {
        Log.e(TAG, "Firebase initialization failed", e)
        null
    }

    private var updateRegistration: ConfigUpdateListenerRegistration? = null

    override fun getPluginName() = "FarmRemoteConfig"

    override fun getPluginSignals() = setOf(CONFIG_READY)

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        val product = Build.PRODUCT.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        return fingerprint.startsWith("generic") || fingerprint.startsWith("unknown") ||
            model.contains("google_sdk") || model.contains("emulator") || model.contains("android sdk built for") ||
            hardware.contains("goldfish") || hardware.contains("ranchu") || hardware.contains("vbox") ||
            product.contains("sdk") || product.contains("emulator") || product.contains("simulator") ||
            manufacturer.contains("genymotion") ||
            (Build.BRAND.startsWith("generic", ignoreCase = true) && Build.DEVICE.startsWith("generic", ignoreCase = true))
    }

    @UsedByGodot
    fun getConfigJson(): String {
        val data = JSONObject()
        data.put("IsEmulator", isEmulator())
        for (key in FLAGS) {
            // The master switch is optional. Distinguish an unpublished key
            // from an explicit remote false so each format can work alone.
            if (key == "EnableAdmob" &&
                config?.getValue(key)?.source != FirebaseRemoteConfig.VALUE_SOURCE_REMOTE
            ) {
                continue
            }
            data.put(key, config?.getBoolean(key) ?: false)
        }
        val allowedRegion = config?.getString(ALLOWED_REGION_KEY).orEmpty()
        data.put(ALLOWED_REGION_KEY, runCatching { JSONArray(allowedRegion) }.getOrElse { JSONArray() })
        val cooldown = config?.getString(COOLDOWN_TREES_KEY).orEmpty()
        data.put(COOLDOWN_TREES_KEY, runCatching { JSONObject(cooldown) }.getOrElse { JSONObject(DEFAULT_TREE_COOLDOWN) })
        val spawnCooldown = config?.getString(SPAWN_TREES_KEY).orEmpty()
        data.put(SPAWN_TREES_KEY, runCatching { JSONObject(spawnCooldown) }.getOrElse { JSONObject(DEFAULT_SPAWN_COOLDOWN) })
        val maxStandingTrees = config?.getString(MAX_STANDING_TREES_KEY)?.toDoubleOrNull()?.takeIf { it.isFinite() }
        data.put(MAX_STANDING_TREES_KEY, maxStandingTrees ?: DEFAULT_MAX_STANDING_TREES.toDouble())
        val maxDailyFreeTreeCuts = config?.getString(MAX_DAILY_FREE_TREE_CUTS_KEY)?.toDoubleOrNull()?.takeIf { it.isFinite() }
        data.put(MAX_DAILY_FREE_TREE_CUTS_KEY, maxDailyFreeTreeCuts ?: DEFAULT_MAX_DAILY_FREE_TREE_CUTS.toDouble())
        return data.toString()
    }

    @UsedByGodot
    fun refresh() {
        val remote = config ?: run {
            emitSignal(CONFIG_READY, getConfigJson())
            return
        }
        if (updateRegistration == null) {
            updateRegistration = remote.addOnConfigUpdateListener(object : ConfigUpdateListener {
                override fun onUpdate(update: ConfigUpdate) {
                    if (update.updatedKeys.none { it in FLAGS || it == ALLOWED_REGION_KEY || it == COOLDOWN_TREES_KEY || it == SPAWN_TREES_KEY || it == MAX_STANDING_TREES_KEY || it == MAX_DAILY_FREE_TREE_CUTS_KEY }) return
                    Log.i(TAG, "Real-time config changed: ${update.updatedKeys}")
                    remote.activate().addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            Log.i(TAG, "Real-time config activated: ${getConfigJson()}")
                            emitSignal(CONFIG_READY, getConfigJson())
                        } else {
                            Log.w(TAG, "Failed to activate real-time config", task.exception)
                        }
                    }
                }

                override fun onError(error: FirebaseRemoteConfigException) {
                    Log.w(TAG, "Real-time config listener failed", error)
                }
            })
        }
        remote.fetchAndActivate().addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                Log.w(TAG, "Fetch failed; retaining last activated values", task.exception)
            } else {
                Log.i(TAG, "Initial config activated: ${getConfigJson()}")
            }
            // Even offline, previously activated values (if any) stay available.
            emitSignal(CONFIG_READY, getConfigJson())
        }
    }

    override fun onMainDestroy() {
        updateRegistration?.remove()
        updateRegistration = null
        super.onMainDestroy()
    }
}
