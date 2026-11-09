"""Render Kebun Ceria's first-launch Theora video from existing game art.

Run: py tools/build_opening_video.py
Requires Pillow and imageio_ffmpeg; no external art or music is used.
"""

from __future__ import annotations

import math
import subprocess
import tempfile
import wave
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "video" / "kebun_ceria_opening.ogv"
SIZE = (540, 960)
FPS = 20
DURATION = 8.0
FRAMES = int(FPS * DURATION)

FONT_BOLD = "C:/Windows/Fonts/trebucbd.ttf"
FONT_REGULAR = "C:/Windows/Fonts/trebuc.ttf"


def smooth(x: float) -> float:
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def sprite(asset: str, width: int) -> Image.Image:
    image = Image.open(ROOT / asset).convert("RGBA")
    bbox = image.getbbox()
    image = image.crop(bbox)
    height = round(image.height * width / image.width)
    return image.resize((width, height), Image.Resampling.LANCZOS)


ART = {
    "barn": sprite("assets/art_v2/village_barn.png", 350),
    "tree": sprite("assets/art_v2/apple_tree.png", 178),
    "wheat_left": sprite("assets/art_v2/wheat_plot_ready.png", 232),
    "wheat_right": sprite("assets/art_v2/wheat_plot_ready.png", 195),
    "cow": sprite("assets/art_v3/cow_pen.png", 206),
    "flowers": sprite("assets/art_v2/flower_garden.png", 162),
    "tower": sprite("assets/art_v6/water_tower.png", 102),
}


def base_background() -> Image.Image:
    image = Image.new("RGB", SIZE)
    pixels = ImageDraw.Draw(image)
    start, end = (142, 214, 208), (242, 240, 178)
    for y in range(SIZE[1]):
        blend = min(1.0, y / 820)
        color = tuple(round(start[c] * (1 - blend) + end[c] * blend) for c in range(3))
        pixels.line((0, y, SIZE[0], y), fill=color)
    return image.convert("RGBA")


BACKGROUND = base_background()
TITLE_FONT = ImageFont.truetype(FONT_BOLD, 72)
CERIA_FONT = ImageFont.truetype(FONT_BOLD, 91)
SUBTITLE_FONT = ImageFont.truetype(FONT_BOLD, 22)
SMALL_FONT = ImageFont.truetype(FONT_REGULAR, 22)
BOTTOM_FONT = ImageFont.truetype(FONT_BOLD, 23)


def cloud(draw: ImageDraw.ImageDraw, x: int, y: int, scale: float, alpha: int = 164) -> None:
    fill = (255, 255, 241, alpha)
    for x1, y1, x2, y2 in [(-58, 0, 49, 32), (-28, -23, 27, 31), (10, -11, 69, 32)]:
        draw.ellipse((x + x1 * scale, y + y1 * scale, x + x2 * scale, y + y2 * scale), fill=fill)


def paste_at(image: Image.Image, item: Image.Image, center_x: float, center_y: float, visibility: float) -> None:
    if visibility <= 0:
        return
    rise = int((1.0 - visibility) * 42)
    x = round(center_x - item.width / 2)
    y = round(center_y - item.height / 2 + rise)
    if visibility < 0.995:
        item = item.copy()
        item.putalpha(item.getchannel("A").point(lambda a: round(a * visibility)))
    image.alpha_composite(item, (x, y))


def title_board(image: Image.Image, elapsed: float) -> None:
    appear = smooth((elapsed - 1.35) / 0.85)
    if appear <= 0:
        return
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    shift = round(26 * (1 - appear))
    bounds = (39, 151 + shift, 501, 344 + shift)
    draw.rounded_rectangle((42, 158 + shift, 503, 351 + shift), radius=35, fill=(56, 104, 54, 64))
    draw.rounded_rectangle(bounds, radius=33, fill="#fffae9", outline="#e1b86e", width=5)
    draw.rounded_rectangle((53, 163 + shift, 487, 332 + shift), radius=24, outline="#f3e7bb", width=2)
    draw.text((270, 184 + shift), "SELAMAT DATANG DI", font=SUBTITLE_FONT, fill="#987a4c", anchor="mm")
    draw.text((270, 244 + shift), "KEBUN", font=TITLE_FONT, fill="#2e754b", anchor="mm", stroke_width=1, stroke_fill="#2e754b")
    draw.text((270, 308 + shift), "CERIA", font=CERIA_FONT, fill="#efaf45", anchor="mm", stroke_width=2, stroke_fill="#a87032")
    # Foliage corners tie the title card into the farm scene.
    for cx, cy, direction in [(69, 183 + shift, 1), (470, 314 + shift, -1)]:
        draw.ellipse((cx - 13, cy - 12, cx + 10, cy + 1), fill="#7cac69")
        leaf_x0, leaf_x1 = sorted((cx - 5 * direction, cx + 16 * direction))
        draw.ellipse((leaf_x0, cy - 5, leaf_x1, cy + 14), fill="#a2c97c")
        draw.ellipse((cx - 1, cy - 2, cx + 5, cy + 4), fill="#f2b667")
    if appear < 1:
        layer.putalpha(layer.getchannel("A").point(lambda a: round(a * appear)))
    image.alpha_composite(layer)


def caption(image: Image.Image, elapsed: float) -> None:
    appear = smooth((elapsed - 3.3) / 0.9)
    if appear <= 0:
        return
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    rise = round((1 - appear) * 15)
    draw.rounded_rectangle((24, 853 + rise, 516, 934 + rise), radius=29, fill=(37, 109, 72, 242))
    draw.text((270, 884 + rise), "Tanam mimpi, panen bahagia!", font=BOTTOM_FONT, fill="#fff8e0", anchor="mm")
    draw.text((270, 909 + rise), "Petualangan kebunmu dimulai di sini", font=SMALL_FONT, fill="#e6f6cb", anchor="mm")
    if appear < 1:
        layer.putalpha(layer.getchannel("A").point(lambda a: round(a * appear)))
    image.alpha_composite(layer)


def render(t: float) -> Image.Image:
    image = BACKGROUND.copy()
    draw = ImageDraw.Draw(image, "RGBA")

    # Warm sunrise with animated wisps of cloud.
    sun_r = 66 + 8 * math.sin(t * 0.5)
    draw.ellipse((432 - sun_r, 109 - sun_r, 432 + sun_r, 109 + sun_r), fill=(255, 247, 198, 92))
    draw.ellipse((390, 67, 473, 150), fill=(255, 231, 138, 233))
    cloud(draw, int(-8 + t * 4), 86, 1.12)
    cloud(draw, int(350 - t * 3), 363, 0.91, 95)
    cloud(draw, int(480 - t * 5), 48, 0.67, 95)

    draw.ellipse((-185, 367, 340, 716), fill="#a9d788")
    draw.ellipse((156, 332, 765, 744), fill="#bedf92")
    draw.ellipse((-164, 451, 711, 1130), fill="#88c96b")
    draw.ellipse((-70, 600, 596, 1200), fill="#90cb6f")
    draw.ellipse((10, 550, 528, 1005), fill=(131, 180, 92, 48))

    for i in range(38):
        px = (i * 173 + 21) % 540
        py = 456 + ((i * 133) % 402)
        if (px - 270) ** 2 / (230**2) + (py - 660) ** 2 / (215**2) < 0.7:
            continue
        flicker = 1 + 0.12 * math.sin(t * 2 + i)
        r = 2.4 * flicker
        if i % 4 == 0:
            draw.ellipse((px-r, py-r, px+r, py+r), fill="#fff0bb")
            draw.ellipse((px-1, py-1, px+1, py+1), fill="#efaf6a")
        else:
            draw.line((px, py, px+4, py-7), fill="#438c54", width=2)
            draw.line((px+4, py-7, px+7, py-4), fill="#438c54", width=2)

    # Gentle camera-like vertical drift keeps original 2D art moving on screen.
    motion = math.sin(t * 1.2) * 3.2
    shadow = ImageDraw.Draw(image, "RGBA")
    shadow.ellipse((92, 689, 457, 808), fill=(43, 91, 43, 41))
    objects = [
        ("tree", 115, 575, 0.40),
        ("tower", 463, 506, 0.75),
        ("barn", 280, 572, 0.25),
        ("cow", 429, 711, 1.05),
        ("flowers", 107, 770, 1.16),
        ("wheat_right", 384, 796, 1.48),
        ("wheat_left", 222, 780, 1.35),
    ]
    for name, x, y, start in objects:
        paste_at(image, ART[name], x, y + motion, smooth((t - start) / 0.8))

    title_board(image, t)
    caption(image, t)

    # Small floating golden fireflies; deterministic path for repeatable renders.
    fx = ImageDraw.Draw(image, "RGBA")
    for i in range(13):
        px = 27 + ((i * 89) % 485) + math.sin(t * 0.8 + i * 1.7) * 12
        py = 376 + ((i * 69) % 450) - t * (4 + i % 3)
        opacity = round(55 + 65 * (0.5 + math.sin(t * 2 + i) * 0.5))
        fx.ellipse((px-2, py-2, px+2, py+2), fill=(255, 246, 188, opacity))

    return image.convert("RGB")


def create_jingle(path: Path) -> None:
    """A gentle, locally synthesized plucked-note intro; no licensed recording."""
    sample_rate = 22050
    notes = [
        (0.25, 523.25, 0.45), (0.66, 659.25, 0.45),
        (1.11, 783.99, 0.48), (1.58, 1046.50, 1.05),
        (2.75, 783.99, 0.38), (3.13, 880.00, 0.43),
        (3.54, 1046.50, 0.95), (4.70, 783.99, 0.42),
        (5.12, 659.25, 0.44), (5.55, 783.99, 0.55),
        (6.16, 1046.50, 1.25),
    ]
    samples = bytearray()
    for i in range(round(DURATION * sample_rate)):
        t = i / sample_rate
        result = 0.0
        for start, frequency, length in notes:
            pos = t - start
            if 0 <= pos < length:
                envelope = min(1.0, pos * 38) * (1 - smooth(pos / length)) ** 1.5
                result += envelope * (
                    math.sin(2 * math.pi * frequency * pos)
                    + 0.23 * math.sin(4 * math.pi * frequency * pos)
                )
        # Volume is intentionally quiet under a game's first-time welcome.
        pcm = max(-32768, min(32767, int(result * 4000)))
        samples.extend(pcm.to_bytes(2, "little", signed=True))
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(samples)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    (ROOT / "build").mkdir(exist_ok=True)
    render(3.7).save(ROOT / "build" / "opening_preview.png")
    with tempfile.TemporaryDirectory() as directory:
        jingle = Path(directory) / "intro.wav"
        create_jingle(jingle)
        command = [
            imageio_ffmpeg.get_ffmpeg_exe(), "-hide_banner", "-loglevel", "error", "-y",
            "-f", "rawvideo", "-pixel_format", "rgb24", "-video_size", "540x960",
            "-framerate", str(FPS), "-i", "pipe:0", "-i", str(jingle),
            "-map", "0:v:0", "-map", "1:a:0",
            "-c:v", "libtheora", "-q:v", "7", "-pix_fmt", "yuv420p",
            "-c:a", "libvorbis", "-q:a", "3", "-shortest", str(OUTPUT),
        ]
        with subprocess.Popen(command, stdin=subprocess.PIPE) as process:
            assert process.stdin is not None
            for frame_index in range(FRAMES):
                process.stdin.write(render(frame_index / FPS).tobytes())
                if frame_index % 40 == 0:
                    print(f"Rendering frame {frame_index + 1}/{FRAMES}", flush=True)
            process.stdin.close()
            exit_code = process.wait()
            if exit_code != 0:
                raise RuntimeError(f"ffmpeg exited with code {exit_code}")
    print(f"Opening video: {OUTPUT} ({OUTPUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
