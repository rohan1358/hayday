"""Draw distinct, compact SVG food illustrations for every kitchen recipe.

The artwork uses the same warm, outlined style as the existing seed-shop icons.
Run from any directory with: py tools/generate_production_icons.py
"""

from pathlib import Path

from generate_seed_icons import ellipse, leaf, path, wrap


OUT = Path(__file__).resolve().parents[1] / "assets" / "production_icons"


def rounded(x, y, w, h, r, fill, stroke="#765337", width=2.4):
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'
    )


def bread():
    return "".join([
        ellipse(64, 101, 43, 9, "#fff8e7", "#d9bd91", 2),
        path("M29 69 Q28 49 44 41 Q60 26 78 41 Q98 48 99 69 L95 91 Q64 103 33 91 Z", "#c98543", "#875332", 3),
        path("M35 70 Q34 54 49 48 Q60 36 76 48 Q92 53 92 70 L89 84 Q62 93 39 84 Z", "#f7c778", "#a8753c", 2),
        path("M47 55 Q42 69 48 77 M65 48 Q60 64 66 78 M82 56 Q77 66 81 74", stroke="#b78040", width=3),
        path("M42 85 Q61 93 85 85", stroke="#ffe2a1", width=3),
    ])


def popcorn():
    parts = [
        path("M39 54 L89 54 L82 105 L46 105 Z", "#f2ece0", "#b25d4c", 3),
        path("M43 60 L50 60 L54 101 L49 101 Z", "#e96c5c", "none", 0),
        path("M58 60 L65 60 L67 101 L61 101 Z", "#e96c5c", "none", 0),
        path("M76 60 L84 60 L79 101 L73 101 Z", "#e96c5c", "none", 0),
    ]
    for x, y, radius in [(39, 47, 12), (55, 40, 12), (70, 38, 12), (87, 47, 11), (64, 52, 13), (46, 54, 10), (81, 56, 10)]:
        parts.append(ellipse(x, y, radius, radius * .82, "#fff0b4", "#ce9d57", 2))
    for x, y in [(51, 43), (69, 46), (83, 53), (43, 51)]:
        parts.append(ellipse(x, y, 3, 2.4, "#ffd16b", "none", 0))
    parts.append(path("M44 67 L83 67", stroke="#f9debd", width=2))
    return "".join(parts)


def carrot_juice():
    return "".join([
        path("M70 53 L80 23 L93 18", stroke="#da7260", width=5),
        path("M39 50 L91 50 L84 106 Q64 114 46 106 Z", "#f7ae48", "#8c6b49", 3),
        path("M44 56 L86 56 L81 99 Q64 107 49 99 Z", "#f38c37", "none", 0),
        ellipse(65, 51, 26, 7, "#ffdf92", "#9a7049", 2),
        ellipse(65, 51, 19, 3, "#f39a3b", "none", 0),
        path("M49 64 Q50 88 55 95", stroke="#ffca74", width=4),
        path("M64 84 Q58 71 63 66 M66 66 Q80 71 64 84", "#fff1bd", "#d58b3d", 1.5),
        leaf(73, 64, 7, 3, -28, "#59aa60"),
    ])


def cheese():
    return "".join([
        ellipse(66, 104, 44, 8, "#f7f0e1", "#d4b995", 2),
        path("M28 65 L84 38 L100 88 L47 104 Z", "#f3b845", "#a97634", 3),
        path("M28 65 L84 38 L97 62 L45 91 Z", "#ffe080", "#b98c3e", 2),
        path("M45 91 L97 62 L100 88 L47 104 Z", "#df9e31", "#b07832", 2),
        ellipse(65, 66, 7, 5, "#e9aa3c", "#c38a35", 1, -20),
        ellipse(84, 56, 5, 4, "#ebac39", "#c58a35", 1),
        ellipse(51, 77, 4, 3.5, "#e5a83b", "none", 0),
        ellipse(73, 88, 6, 4, "#bd8027", "none", 0, -12),
        ellipse(90, 79, 3, 5, "#c78a2e", "none", 0),
    ])


def butter():
    return "".join([
        ellipse(64, 102, 44, 11, "#f9f6ec", "#cdbda2", 2),
        path("M37 65 L72 50 L97 60 L62 75 Z", "#fff3a0", "#bfa35c", 2.4),
        path("M37 65 L62 75 L62 99 L37 88 Z", "#e5b951", "#ac8543", 2.4),
        path("M62 75 L97 60 L97 83 L62 99 Z", "#f7d86d", "#bd9b52", 2.4),
        path("M42 68 L72 55", stroke="#fff9ce", width=3),
        path("M27 54 Q36 52 46 54 L60 59 L60 63 L44 61 L27 60 Z", "#cdd8d0", "#7c8c82", 1.8),
        path("M22 52 L29 53 L29 61 L22 59 Z", "#a77948", "#7d5835", 2),
    ])


def sweet_bread():
    return "".join([
        ellipse(66, 103, 42, 9, "#fff7e5", "#d8b990", 2),
        path("M29 79 Q27 56 47 46 Q60 37 76 43 Q99 47 100 74 Q104 95 81 99 L51 99 Q29 96 29 79 Z", "#c98049", "#8e5634", 3),
        path("M38 64 Q49 47 66 50 Q86 50 91 69 Q88 79 78 76 Q67 90 57 77 Q46 87 38 75 Z", "#f6d3a1", "#a56c4a", 2),
        path("M46 66 Q53 57 63 64 Q70 71 76 62 M48 82 Q62 91 79 81", stroke="#fff4d8", width=5),
        ellipse(56, 63, 2, 2, "#e37a7d", "none", 0),
        ellipse(72, 72, 2.4, 2.4, "#e78a6e", "none", 0),
        ellipse(81, 58, 2.2, 2.2, "#79b968", "none", 0),
        ellipse(57, 87, 2.3, 2.3, "#77b267", "none", 0),
    ])


def chips():
    parts = [ellipse(64, 105, 42, 9, "#fff6df", "#d9b98a", 2)]
    for x, y, angle in [(41, 72, -24), (65, 60, 15), (85, 71, 29), (55, 85, 18), (80, 87, -20)]:
        parts.append(
            f'<g transform="rotate({angle} {x} {y})">'
            + path(f"M{x-15} {y-8} Q{x-9} {y-19} {x+2} {y-13} Q{x+19} {y-14} {x+16} {y+3} Q{x+9} {y+17} {x-7} {y+13} Q{x-19} {y+7} {x-15} {y-8} Z", "#f9d16a", "#b98737", 2.4)
            + path(f"M{x-10} {y-4} Q{x+2} {y-10} {x+10} {y+4}", stroke="#ffeaa1", width=2)
            + "</g>"
        )
    return "".join(parts)


def cake():
    return "".join([
        ellipse(66, 104, 43, 9, "#fff7e8", "#d8b990", 2),
        path("M30 66 L81 40 L99 64 L99 93 L55 107 L30 91 Z", "#edc68b", "#a5784b", 2.9),
        path("M30 66 L81 40 L99 64 L55 87 Z", "#fff2df", "#b58c6d", 2.3),
        path("M55 87 L99 64 L99 73 L55 96 Z", "#f8a4a1", "none", 0),
        path("M30 76 L55 96 L55 102 L30 85 Z", "#f4a5a1", "none", 0),
        path("M30 64 Q46 59 53 61 Q65 45 78 44 Q86 43 97 64 L99 67 L81 49 L55 89 L29 69 Z", "#fff9ed", "#bda18b", 1.5),
        ellipse(78, 40, 8, 7, "#e9585a", "#ac4142", 2),
        path("M78 34 Q77 27 84 24", stroke="#39894b", width=3),
        path("M62 71 L70 65", stroke="#d38e83", width=2),
    ])


def bacon():
    return "".join([
        ellipse(64, 102, 45, 12, "#fff9ea", "#d6bb97", 2),
        path("M33 38 Q44 30 53 41 Q65 55 56 67 Q46 82 59 94 L47 99 Q28 82 37 67 Q46 53 33 46 Z", "#c55b51", "#8e4a3e", 2.8),
        path("M44 39 Q54 49 47 65 Q39 79 53 93", stroke="#f6bf9b", width=6),
        path("M70 30 Q88 40 80 59 Q70 72 89 87 L82 100 Q62 93 63 77 Q66 64 73 55 Q78 43 66 37 Z", "#d67461", "#924e43", 2.8),
        path("M73 35 Q89 49 73 67 Q67 80 82 93", stroke="#ffcfad", width=6),
        path("M37 86 Q44 91 47 97", stroke="#f8e0b8", width=2),
    ])


def goat_yogurt():
    return "".join([
        ellipse(65, 105, 43, 9, "#fff5e5", "#d9bc99", 2),
        path("M37 56 L93 56 L85 103 Q65 111 46 103 Z", "#e7f2eb", "#8ba99b", 3),
        path("M42 61 L88 61 L82 98 Q64 105 49 98 Z", "#fffdf1", "none", 0),
        ellipse(65, 56, 28, 9, "#fffef6", "#8ba99b", 2),
        path("M43 56 Q56 51 66 57 Q80 49 87 55", stroke="#e2e5d7", width=2),
        ellipse(55, 55, 6, 5, "#b56ab2", "#7f518f", 1),
        ellipse(75, 51, 5, 5, "#a968b0", "#76528b", 1),
        leaf(63, 43, 12, 5, 18, "#63a864"),
        path("M58 81 Q64 87 71 81", stroke="#b8d5d0", width=2.5),
        ellipse(57, 76, 2.5, 2.5, "#b3cfcb", "none", 0),
        ellipse(74, 76, 2.5, 2.5, "#b3cfcb", "none", 0),
    ])


def tomato_sauce():
    return "".join([
        ellipse(64, 107, 35, 7, "#f9efdf", "none", 0),
        rounded(52, 24, 24, 13, 3, "#f7cb75", "#99683c", 2.7),
        path("M51 38 L77 38 L77 48 Q95 56 91 78 L87 101 Q65 109 41 101 L37 78 Q33 56 51 48 Z", "#c85042", "#893c37", 3),
        path("M47 62 Q40 75 48 93", stroke="#ec7a65", width=4),
        rounded(48, 63, 34, 27, 8, "#ffedc2", "#c58a64", 1.8),
        ellipse(66, 77, 10, 9, "#e55246", "#ae4540", 1.8),
        path("M66 70 L62 67 L64 73 L58 72 L63 76 L68 72 L73 74 L70 68 Z", "#519354", "none", 0),
    ])


def sambal():
    return "".join([
        ellipse(64, 108, 38, 6, "#f9efdf", "none", 0),
        rounded(36, 49, 56, 54, 12, "#d6463c", "#923b35", 2.9),
        rounded(34, 39, 60, 16, 5, "#f1c16b", "#956c44", 2.9),
        path("M43 61 Q36 83 47 93", stroke="#ec816b", width=4),
        rounded(45, 66, 39, 24, 7, "#ffedbd", "#b87949", 1.6),
        path("M53 80 Q61 69 73 71 Q81 76 67 84 Q61 87 53 85 Q67 80 63 78 Z", "#e34b42", "#9b4039", 1.5),
        path("M69 73 Q69 67 75 67", stroke="#4c9350", width=2.5),
        ellipse(78, 78, 2.5, 2.5, "#f6c76a", "none", 0),
    ])


def pineapple_jam():
    return "".join([
        ellipse(65, 107, 39, 7, "#f8efde", "none", 0),
        rounded(38, 45, 54, 60, 12, "#efa93d", "#a87540", 2.8),
        path("M44 53 L86 53 L84 96 Q65 103 46 96 Z", "#f6c95c", "none", 0),
        rounded(36, 35, 58, 16, 4, "#8bbf86", "#538451", 2.8),
        rounded(45, 65, 38, 26, 7, "#fff2cb", "#cba06a", 1.8),
        path("M57 73 Q65 66 74 73 Q79 81 72 87 Q65 93 57 86 Q51 81 57 73 Z", "#ebbf4a", "#a87d34", 1.7),
        path("M65 72 Q60 60 55 62 M65 72 Q65 59 68 59 M65 72 Q76 63 78 65", stroke="#559654", width=2.6),
        path("M57 78 L73 86 M73 76 L57 86", stroke="#d3a143", width=1.7),
    ])


def main():
    icons = {
        "roti": bread(),
        "popcorn": popcorn(),
        "jus_wortel": carrot_juice(),
        "keju": cheese(),
        "mentega": butter(),
        "roti_manis": sweet_bread(),
        "keripik_kentang": chips(),
        "kue": cake(),
        "bacon": bacon(),
        "yogurt_kambing": goat_yogurt(),
        "saus_tomat": tomato_sauce(),
        "sambal": sambal(),
        "selai_nanas": pineapple_jam(),
    }
    OUT.mkdir(exist_ok=True)
    for name, artwork in icons.items():
        (OUT / f"{name}.svg").write_text(wrap(artwork, "#fff0d5"), encoding="utf-8")
    print(f"Wrote {len(icons)} production icons to {OUT}")


if __name__ == "__main__":
    main()
