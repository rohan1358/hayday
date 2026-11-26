"""Make readable product icons for the new village district inventory."""
from pathlib import Path

TARGET = Path(__file__).resolve().parents[1] / "assets" / "production_icons"
FRAME = '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><circle cx="64" cy="64" r="56" fill="{bg}" stroke="#d6a96b" stroke-width="3"/><ellipse cx="64" cy="105" rx="35" ry="7" fill="#775334" opacity=".17"/>{body}</svg>'
ICONS = {
    "surat_tetangga": ("#fff1c9", '<rect x="25" y="35" width="78" height="60" rx="9" fill="#f3b959" stroke="#97612d" stroke-width="4"/><path d="M27 42l37 28 37-28" fill="none" stroke="#fff6db" stroke-width="6" stroke-linecap="round"/><path d="M29 89l25-23m45 23L75 66" fill="none" stroke="#d8873a" stroke-width="4"/><path d="M72 38c6-11 20 0 0 15-20-15-6-26 0-15" fill="#ec737b"/>'),
    "hidangan_desa": ("#fff0d7", '<ellipse cx="64" cy="79" rx="39" ry="23" fill="#a76837" stroke="#784323" stroke-width="4"/><ellipse cx="64" cy="72" rx="34" ry="17" fill="#fff8e9" stroke="#ddb57b" stroke-width="4"/><ellipse cx="64" cy="70" rx="25" ry="9" fill="#e8994e"/><circle cx="50" cy="67" r="5" fill="#69a653"/><circle cx="75" cy="72" r="5" fill="#dd5c48"/><path d="M47 47q-4-8 3-13m15 10q-4-8 3-13m14 18q-4-8 3-13" fill="none" stroke="#b6a495" stroke-width="4" stroke-linecap="round"/>'),
    "wawasan": ("#e0f4ff", '<path d="M26 42q18-12 38 3v48q-20-14-38-4zM102 42Q84 30 64 45v48q20-14 38-4z" fill="#fdf8e3" stroke="#4d789a" stroke-width="4" stroke-linejoin="round"/><path d="M64 45v48M35 53q12-4 21 2m-21 12q12-4 21 2m37-16q-12-4-21 2m21 12q-12-4-21 2" fill="none" stroke="#80b5d1" stroke-width="3"/><path d="M63 20l4 10 10 3-10 4-4 10-4-10-10-4 10-3z" fill="#f8c84f" stroke="#c18736" stroke-width="2"/>'),
    "bunga_langka": ("#ffe8f3", '<path d="M64 92V58M64 80q-19-17-28-6 11 19 28 6m0-2q19-17 28-6-11 19-28 6" fill="#75b960" stroke="#498b49" stroke-width="3"/><circle cx="64" cy="47" r="12" fill="#ffdc5f"/><g fill="#dd79c6" stroke="#a65b9a" stroke-width="2"><ellipse cx="64" cy="28" rx="10" ry="17"/><ellipse cx="64" cy="66" rx="10" ry="17"/><ellipse cx="45" cy="47" rx="17" ry="10"/><ellipse cx="83" cy="47" rx="17" ry="10"/></g><circle cx="64" cy="47" r="9" fill="#ffe380" stroke="#c58a47" stroke-width="2"/>'),
    "paket_wisata": ("#e1f6f0", '<rect x="31" y="42" width="66" height="54" rx="8" fill="#e9af63" stroke="#8e633e" stroke-width="4"/><path d="M48 43v-8q16-16 32 0v8" fill="none" stroke="#8e633e" stroke-width="6"/><rect x="56" y="60" width="16" height="19" rx="3" fill="#68b9c1"/><path d="M36 68h16m24 0h17" stroke="#f7dc97" stroke-width="4"/><circle cx="64" cy="70" r="5" fill="#f9dc73"/>'),
    "piala_panen": ("#fff1c3", '<path d="M43 34h42v27q0 19-21 22-21-3-21-22z" fill="#f9c747" stroke="#a67630" stroke-width="4"/><path d="M43 42H28q0 24 17 24m40-24h15q0 24-17 24" fill="none" stroke="#a67630" stroke-width="5"/><path d="M64 81v16m-20 0h40" stroke="#a67630" stroke-width="7" stroke-linecap="round"/><path d="M64 43l4 8 9 1-7 7 2 9-8-4-8 4 2-9-7-7 9-1z" fill="#fff4c3"/>'),
}

for name, (background, body) in ICONS.items():
    (TARGET / f"{name}.svg").write_text(FRAME.format(bg=background, body=body), encoding="utf-8")
    print(name)
