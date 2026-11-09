"""Generate the 13 illustrated seed-shop icons (self-contained Godot SVG assets)."""

from pathlib import Path


OUT = Path(__file__).resolve().parents[1] / "assets" / "seed_icons"


def ellipse(x, y, rx, ry, fill, stroke="#66513a", width=2, rotate=0):
    return (
        f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="{width}" '
        f'transform="rotate({rotate} {x} {y})"/>'
    )


def leaf(x, y, rx, ry, angle=0, fill="#5ca95c"):
    return (
        f'<g transform="rotate({angle} {x} {y})">'
        + ellipse(x, y, rx, ry, fill, "#367d4c", 2)
        + f'<path d="M{x-rx*0.65} {y+ry*0.25} Q{x} {y} {x+rx*0.72} {y-ry*0.25}" '
        'fill="none" stroke="#b2df79" stroke-width="1.7" opacity=".85"/>'
        "</g>"
    )


def path(d, fill="none", stroke="#735037", width=2):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'


def wrap(shapes, background="#f9edce"):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
        '<g stroke-linecap="round" stroke-linejoin="round">'
        f'<circle cx="64" cy="64" r="57" fill="{background}" stroke="#e2c99d" stroke-width="2"/>'
        '<circle cx="59" cy="56" r="48" fill="#fff9e7" opacity=".48"/>'
        '<ellipse cx="64" cy="105" rx="35" ry="7" fill="#99734d" opacity=".13"/>'
        + shapes
        + "</g></svg>"
    )


def wheat():
    parts = []
    for x, tip, lean in [(44, 32, -5), (63, 23, 0), (83, 35, 6)]:
        parts.append(path(f"M{x-lean} 104 Q{x-7} 72 {x} {tip+4}", stroke="#5f9b49", width=3.2))
        parts.append(leaf(x-9, 88, 15, 4.7, -37, "#73ae58"))
        parts.append(leaf(x+8, 78, 13, 4, 32, "#75b45d"))
        for j in range(5):
            y = tip + j * 8
            parts.append(ellipse(x-5, y+2, 5.2, 7, "#f0bb4c", "#b68138", 1.6, -23))
            parts.append(ellipse(x+5, y+2, 5.2, 7, "#ffe082", "#bb873d", 1.6, 23))
        parts.append(ellipse(x, tip-4, 4, 7, "#ffda6c", "#b68138", 1.5))
    return "".join(parts)


def corn():
    parts = [
        path("M64 105 Q57 84 64 48", stroke="#4a984b", width=5),
        path("M62 97 Q34 95 30 57 Q54 60 65 80 Z", "#4b9c58", "#317548", 2),
        path("M65 97 Q93 86 98 48 Q75 52 65 79 Z", "#72bb57", "#37774b", 2),
        path("M49 44 Q49 28 64 27 Q81 29 81 45 L80 84 Q72 99 61 96 Q49 86 49 44 Z",
             "#ffd35d", "#a98136", 2.7),
    ]
    for y in range(39, 88, 9):
        for x in (55, 64, 73):
            parts.append(ellipse(x, y+(x//9)%2, 3.6, 4.5, "#ffea89", "#ddad4c", .9))
    parts += [
        path("M58 97 Q40 77 43 55 Q53 61 61 82 Z", "#58a85b", "#367d4a", 2.2),
        path("M71 97 Q91 75 88 55 Q76 65 67 86 Z", "#7abd67", "#367d4a", 2.2),
        path("M56 35 Q60 31 65 33", stroke="#fff4bd", width=2.6),
    ]
    return "".join(parts)


def carrot():
    parts = [
        path("M63 56 Q43 50 51 20 Q64 30 67 52", "#4ea653", "#2e804a", 2.2),
        path("M65 55 Q72 21 91 24 Q88 46 70 58", "#73b65a", "#327b49", 2.2),
        path("M64 56 Q60 27 66 17 Q79 35 71 56", "#6dbd62", "#327b49", 2.2),
        path("M46 53 Q64 42 81 55 Q85 76 64 108 Q46 81 46 53 Z",
             "#f8923c", "#b35b2b", 3),
        path("M54 58 Q60 53 67 56", stroke="#ffc06a", width=4),
        path("M53 72 L63 69 M68 82 L78 79 M58 91 L66 88", stroke="#cf672e", width=2.7),
        path("M75 60 Q76 75 67 90", stroke="#ffd08b", width=3),
    ]
    return "".join(parts)


def cane():
    parts = []
    for x, height, color, tilt in [(45, 29, "#a1d06c", -3), (64, 22, "#b4d476", 2), (83, 33, "#8ac760", 3)]:
        parts.append(path(f"M{x} 104 L{x+tilt} {height}", stroke="#39884e", width=14))
        parts.append(path(f"M{x} 104 L{x+tilt} {height}", stroke=color, width=10))
        for y in (48, 68, 88):
            parts.append(path(f"M{x-5} {y} L{x+5} {y-3}", stroke="#6b9a4f", width=3))
        parts.append(path(f"M{x+tilt} {height+16} Q{x+22} {height-2} {x+36} {height+4}",
                          stroke="#4b9c4e", width=5))
        parts.append(path(f"M{x+tilt} {height+23} Q{x-15} {height-1} {x-25} {height+2}",
                          stroke="#6db85c", width=5))
    return "".join(parts)


def strawberry():
    parts = [
        path("M62 35 Q61 25 70 19", stroke="#397a46", width=4),
        leaf(50, 32, 17, 7, -23),
        leaf(76, 31, 17, 7, 23),
        path("M30 57 Q27 43 43 41 Q54 39 62 56 Q60 81 48 94 Q35 82 30 57 Z",
             "#f15f5f", "#ae3b47", 2.8),
        path("M61 53 Q61 35 79 38 Q94 39 98 57 Q93 88 78 102 Q65 84 61 53 Z",
             "#e54c58", "#a63543", 2.8),
        path("M29 46 Q41 35 56 47 L51 52 L43 49 L38 54 L35 51 Z",
             "#4b9e52", "#297747", 2),
        path("M61 44 Q78 33 94 46 L86 51 L79 46 L73 53 L68 49 Z",
             "#69b354", "#297747", 2),
    ]
    for x, y in [(42,58),(51,67),(39,74),(46,83),(73,58),(84,60),(77,73),(88,76),(79,87),(68,68)]:
        parts.append(ellipse(x, y, 1.7, 2.7, "#fff2bd", "#e7a366", .6, -20))
    parts += [
        path("M34 55 Q36 51 43 53", stroke="#ffb8a5", width=3),
        path("M69 52 Q72 47 79 49", stroke="#ff9e9c", width=3),
    ]
    return "".join(parts)


def soy():
    parts = [
        path("M34 101 Q60 79 68 29", stroke="#40894b", width=3.5),
        leaf(45, 48, 18, 8, 32),
        leaf(82, 34, 19, 9, -28),
        path("M32 78 Q23 60 36 52 Q50 48 59 66 Q60 80 48 88 Q37 86 32 78 Z",
             "#91bd62", "#497b45", 2.8),
        path("M65 81 Q59 62 73 53 Q87 50 94 66 Q99 79 85 93 Q72 95 65 81 Z",
             "#a6ca72", "#497b45", 2.8),
    ]
    for x, y in [(40,69),(49,77),(76,69),(86,78)]:
        parts.append(ellipse(x, y, 5, 6, "#d3dd95", "#7a9f53", 1.7, -18))
    parts.append(path("M37 57 Q31 61 35 70 M71 57 Q67 61 69 69", stroke="#dbeaa2", width=2))
    return "".join(parts)


def potato():
    parts = [
        ellipse(46, 77, 24, 30, "#c79460", "#875e3d", 3, -24),
        ellipse(85, 76, 23, 26, "#ba8957", "#875e3d", 3, 19),
        ellipse(65, 57, 25, 28, "#ddb17b", "#986c42", 3, -12),
        ellipse(55, 48, 9, 5, "#f1c994", "none", 0, -21),
        ellipse(36, 70, 8, 4, "#e4b47e", "none", 0, -28),
        ellipse(78, 64, 9, 4, "#e6bc87", "none", 0, 24),
    ]
    for x, y in [(40,80),(52,91),(57,62),(73,54),(76,87),(90,75),(67,73),(48,45)]:
        parts.append(ellipse(x, y, 2.3, 1.7, "#956039", "#a7794e", 1, 25))
    return "".join(parts)


def pumpkin():
    return "".join([
        path("M63 46 Q57 30 70 25", stroke="#476a3c", width=8),
        leaf(83, 36, 22, 8, -25),
        ellipse(65, 74, 39, 31, "#d97734", "#975122", 3),
        ellipse(47, 75, 22, 30, "#f39e43", "#c46c2b", 2),
        ellipse(81, 75, 22, 30, "#e98a34", "#be632c", 2),
        ellipse(64, 74, 19, 31, "#ffa64c", "#c46c2b", 2),
        path("M62 46 L64 96", stroke="#f9bd69", width=2.2),
        path("M38 60 Q43 51 49 50", stroke="#ffc46d", width=3),
        path("M67 48 Q65 43 65 38", stroke="#426e3c", width=4),
    ])


def rice():
    parts = []
    for x, offset in [(40, -8), (62, 0), (83, 6)]:
        parts.append(path(f"M{x+offset//4} 105 Q{x-4} 76 {x+offset} 36",
                          stroke="#58994d", width=3.1))
        parts.append(leaf(x-9, 81, 18, 4, -32, "#73b15a"))
        parts.append(leaf(x+9, 91, 19, 4, 30, "#6aaa58"))
        for i in range(6):
            y = 37 + i*8
            side = -1 if i%2==0 else 1
            px = x+offset + side*(7+i//2)
            parts.append(path(f"M{x+offset} {y+3} L{px} {y+4}",
                              stroke="#7a9a4e", width=1.5))
            parts.append(ellipse(px+side*3, y+4, 3.5, 5.1, "#e6ce71", "#b4a04e", 1.1, side*20))
    return "".join(parts)


def tomato():
    parts = [
        path("M63 53 Q61 37 68 27", stroke="#4b8e4d", width=4),
        leaf(51, 34, 17, 7, -24),
        leaf(82, 36, 15, 7, 26),
        ellipse(42, 80, 22, 21, "#e95c4f", "#b13b37", 2.7),
        ellipse(85, 79, 23, 23, "#dd4b42", "#aa3837", 2.7),
        ellipse(63, 65, 25, 24, "#f06b5e", "#ad3d38", 3),
    ]
    for x, y in [(42,61),(85,57),(63,42)]:
        parts.append(path(f"M{x} {y+4} l-13 -5 l9 -2 l4 -9 l3 10 l10 3 l-10 4 l-3 7 Z",
                          "#408c46", "#367543", 1.4))
    parts += [
        ellipse(53, 57, 8, 4, "#ffae91", "none", 0, -33),
        ellipse(32, 74, 5, 3, "#ff9b79", "none", 0, -40),
        ellipse(78, 70, 6, 4, "#ff9f87", "none", 0, -35),
    ]
    return "".join(parts)


def chili():
    return "".join([
        path("M62 35 Q59 23 69 23", stroke="#3d8c46", width=4),
        leaf(78, 32, 19, 7, 20),
        path("M39 50 Q54 38 68 50 Q80 63 72 79 Q65 98 36 105 Q55 89 49 75 Q45 65 39 50 Z",
             "#e9534c", "#ad3839", 2.9),
        path("M57 46 Q67 34 82 45 Q95 56 88 75 Q79 93 60 97 Q76 77 70 64 Z",
             "#d73842", "#a52e39", 2.9),
        path("M40 50 Q52 43 62 49 L59 56 L49 55 L44 59 Z",
             "#458f46", "#317b43", 2),
        path("M60 46 Q71 38 81 44 L79 52 L70 50 L65 54 Z",
             "#62a858", "#317b43", 2),
        path("M49 59 Q55 63 55 72", stroke="#ff9b78", width=3),
        path("M71 53 Q78 59 78 67", stroke="#f88a7e", width=3),
    ])


def coffee():
    parts = [
        path("M33 89 Q56 57 80 33", stroke="#4a874e", width=4),
        leaf(44, 49, 23, 8, -37, "#67aa55"),
        leaf(84, 47, 23, 8, 24, "#75b560"),
        ellipse(43, 76, 18, 23, "#915b39", "#65402e", 2.7, -27),
        ellipse(83, 76, 18, 23, "#a16c42", "#684530", 2.7, 25),
        ellipse(64, 66, 19, 25, "#ae7549", "#704a33", 3, -8),
    ]
    for x, y, ang in [(43,76,-27),(83,76,25),(64,66,-8)]:
        parts.append(path(f"M{x-3} {y-16} Q{x+7} {y-6} {x-2} {y+3} Q{x-9} {y+10} {x+3} {y+17}",
                          stroke="#553828", width=3.4))
    parts += [ellipse(52, 54, 4, 6, "#d7a078", "none", 0, -22)]
    return "".join(parts)


def pineapple():
    parts = [
        path("M63 48 Q50 26 39 26 Q41 49 58 58", "#5ea354", "#387c45", 2.2),
        path("M63 49 Q61 19 65 13 Q76 28 69 52", "#75b759", "#387c45", 2.2),
        path("M68 48 Q87 24 92 25 Q86 49 71 58", "#4c9750", "#387c45", 2.2),
        path("M53 51 Q47 33 55 24 Q67 43 64 52", "#82c567", "#387c45", 2),
        path("M45 52 Q64 43 83 52 Q97 75 84 99 Q64 116 45 99 Q31 75 45 52 Z",
             "#e9b746", "#a8752d", 3.2),
    ]
    # Pineapple's crosshatch must stay inside the fruit's outline.
    parts.append('<clipPath id="pineclip"><path d="M45 52 Q64 43 83 52 Q97 75 84 99 Q64 116 45 99 Q31 75 45 52 Z"/></clipPath>')
    parts.append('<g clip-path="url(#pineclip)" stroke="#cb8f36" stroke-width="3" opacity=".85">')
    for start in (22, 42, 62, 82, 102):
        parts.append(path(f"M{start} 42 L{start+64} 120", stroke="#cb8f36", width=3))
        parts.append(path(f"M{start+36} 40 L{start-30} 118", stroke="#c78a30", width=3))
    parts.append("</g>")
    for x,y in [(55,64),(74,68),(63,88),(80,91)]:
        parts.append(ellipse(x,y,2.3,2.2,"#ffe692","none",0))
    parts.append(path("M44 66 Q40 79 47 92", stroke="#ffd477", width=3))
    return "".join(parts)


def main():
    icons = {
        "gandum": wheat(),
        "jagung": corn(),
        "wortel": carrot(),
        "tebu": cane(),
        "stroberi": strawberry(),
        "kedelai": soy(),
        "kentang": potato(),
        "labu": pumpkin(),
        "padi": rice(),
        "tomat": tomato(),
        "cabai": chili(),
        "kopi": coffee(),
        "nanas": pineapple(),
    }
    OUT.mkdir(exist_ok=True)
    for name, art in icons.items():
        svg = wrap(art, "#e8efd7" if name in ("tebu", "kedelai", "padi") else "#f9edce")
        (OUT / f"{name}.svg").write_text(svg, encoding="utf-8")
    print(f"Wrote {len(icons)} illustrated seed icons to {OUT}")


if __name__ == "__main__":
    main()
