"""Generate the original, seamless 120 BPM Treadlight prototype soundtrack.

Python 3 standard library only. No sampled or third-party music is used.
Run from any working directory: python tools/generate_music.py
"""
from array import array
from math import sin, pi, exp
from pathlib import Path
import random
import wave

RATE = 44100
BEAT = 0.5
LENGTH = 16.0
random.seed(120)
audio = [0.0] * int(RATE * LENGTH)


def add(start, duration, sample):
    first = int(start * RATE)
    for i in range(int(duration * RATE)):
        audio[(first + i) % len(audio)] += sample(i / RATE)


for beat in range(32):
    # Each quarter note has an audible attack; beat one of every bar is accented.
    strength = 0.62 if beat % 4 == 0 else 0.43
    add(beat * BEAT, 0.26,
        lambda t, a=strength: a * sin(2 * pi * (53 * t + 7 * (1 - exp(-28 * t)))) * exp(-19 * t))
    add(beat * BEAT, 0.055,
        lambda t, a=strength: a * 0.28 * sin(2 * pi * 1400 * t) * exp(-100 * t))
    # Quiet eighth-note hats and bass make the beat predictable without clutter.
    for half in range(2):
        add(beat * BEAT + half * 0.25, 0.04,
            lambda t: (random.random() * 2 - 1) * 0.04 * exp(-100 * t))
    root = [110.0, 87.3071, 130.8128, 97.9989][beat // 8]
    add(beat * BEAT, 0.42,
        lambda t, f=root: 0.12 * sin(2 * pi * f * t) * (1 - exp(-80 * t)) * exp(-9 * t))
    for eighth in range(2):
        note = root * [4, 6, 5, 8, 4, 5, 6, 10][(beat * 2 + eighth) % 8]
        add(beat * BEAT + eighth * 0.25, 0.7,
            lambda t, f=note: 0.055 * (sin(2 * pi * f * t) + 0.2 * sin(4 * pi * f * t)) * (1 - exp(-150 * t)) * exp(-7 * t))

target = Path(__file__).resolve().parents[1] / "campaign/audio/awakening.wav"
target.parent.mkdir(parents=True, exist_ok=True)
samples = array("h", (int(max(-1, min(1, x)) * 26000) for x in audio))
with wave.open(str(target), "wb") as out:
    out.setnchannels(1)
    out.setsampwidth(2)
    out.setframerate(RATE)
    out.writeframes(samples.tobytes())
print(f"Generated {target.name}: {LENGTH:g}s, 120 BPM, mono PCM16")
