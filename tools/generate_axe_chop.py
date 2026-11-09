"""Create the original, short cartoon axe/wood impact used by Ujang.

Run with: py -3 tools/generate_axe_chop.py
Uses only the Python standard library; there are no external sound licenses.
"""

from pathlib import Path
import math
import random
import struct
import wave


SAMPLE_RATE = 24000
DURATION = 0.32
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "axe_chop.wav"


def main() -> None:
    rng = random.Random(20261103)
    low_pass = 0.0
    samples = []
    for i in range(int(SAMPLE_RATE * DURATION)):
        t = i / SAMPLE_RATE
        noise = rng.uniform(-1, 1)
        low_pass += (noise - low_pass) * 0.12
        splinter = noise - low_pass
        # A resonant wooden knock, with a quick sharp crack and bark texture.
        knock = (
            0.67 * math.sin(2 * math.pi * (112 * t - 22 * t * t))
            + 0.36 * math.sin(2 * math.pi * 211 * t)
            + 0.16 * math.sin(2 * math.pi * 389 * t)
        ) * math.exp(-t * 19)
        crack = 0.80 * splinter * math.exp(-t * 73)
        bark = 0.35 * low_pass * math.exp(-t * 18)
        tail = 0.12 * noise * math.exp(-max(0, t - 0.035) * 33)
        attack = min(1.0, t / 0.0015)
        fade = min(1.0, (DURATION - t) / 0.018)
        samples.append((knock + crack + bark + tail) * attack * fade)

    gain = 0.91 / max(abs(x) for x in samples)
    pcm = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x * gain)) * 32767)) for x in samples)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SAMPLE_RATE)
        file.writeframes(pcm)
    print(f"Generated {OUTPUT}, {DURATION:.2f}s")


if __name__ == "__main__":
    main()
