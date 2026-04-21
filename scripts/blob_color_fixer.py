#!/usr/bin/env python3
"""
blob_color_fixer.py — Detects monotone/bland wal color palettes and replaces
accent colors with vibrant, harmonically-spread alternatives.
"""

import sys
import math
import colorsys
from dataclasses import dataclass

MIN_SATURATION      = 0.65
MIN_LIGHTNESS       = 0.40
MAX_LIGHTNESS       = 0.70
HUE_THRESHOLD       = 0.15
SAT_THRESHOLD       = 0.35
HUE_VARIANCE_THRESHOLD = 0.15
ACCENT_SLICE        = slice(1, 7)
BRIGHT_OFFSET       = 8

HUE_SHIFTS: list[float] = [
    0.0,
    0.5,
    0.083,
   -0.083,
    0.416,
   -0.416,
]

@dataclass(frozen=True)
class HLS:
    h: float
    l: float
    s: float


def hex_to_rgb(hex_str: str) -> tuple[float, float, float]:
    hex_str = hex_str.lstrip("#")
    return tuple(int(hex_str[i : i + 2], 16) / 255.0 for i in (0, 2, 4))  # type: ignore[return-value]


def rgb_to_hex(r: float, g: float, b: float) -> str:
    return "#{:02x}{:02x}{:02x}".format(int(r * 255), int(g * 255), int(b * 255))


def hex_to_hls(hex_str: str) -> HLS:
    h, l, s = colorsys.rgb_to_hls(*hex_to_rgb(hex_str))
    return HLS(h, l, s)


def vibrant_shift(hex_str: str, hue_shift: float) -> str:
    """Return *hex_str* with its hue rotated by *hue_shift* and vibrancy enforced."""
    hls = hex_to_hls(hex_str)
    h = (hls.h + hue_shift) % 1.0
    s = max(hls.s, MIN_SATURATION)
    l = min(max(hls.l, MIN_LIGHTNESS), MAX_LIGHTNESS)
    return rgb_to_hex(*colorsys.hls_to_rgb(h, l, s))


def palette_is_bland(accents: list[str]) -> bool:
    """Return True when accent colors are too similar, clustered, or too desaturated."""
    stats = [hex_to_hls(c) for c in accents]
    hues  = [hls.h for hls in stats]
    sats  = [hls.s for hls in stats]

    raw_spread = max(hues) - min(hues)
    hue_spread = min(raw_spread, 1.0 - raw_spread)
    avg_sat    = sum(sats) / len(sats)

    if hue_spread < HUE_THRESHOLD or avg_sat < SAT_THRESHOLD:
        return True

    mean_sin = sum(math.sin(2 * math.pi * h) for h in hues) / len(hues)
    mean_cos = sum(math.cos(2 * math.pi * h) for h in hues) / len(hues)
    hue_variance = 1.0 - math.sqrt(mean_sin ** 2 + mean_cos ** 2)
    if hue_variance < HUE_VARIANCE_THRESHOLD:
        return True

    return False


def most_saturated(accents: list[str]) -> str:
    return max(accents, key=lambda c: hex_to_hls(c).s)


def load_colors(filepath: str) -> list[str]:
    try:
        with open(filepath) as f:
            colors = [line.strip() for line in f if line.strip()]
    except OSError as exc:
        sys.exit(f"Error reading '{filepath}': {exc}")

    if len(colors) < 16:
        sys.exit(f"Expected ≥ 16 colors in '{filepath}', found {len(colors)}.")

    return colors


def save_colors(filepath: str, colors: list[str]) -> None:
    try:
        with open(filepath, "w") as f:
            f.write("\n".join(colors) + "\n")
    except OSError as exc:
        sys.exit(f"Error writing '{filepath}': {exc}")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("Usage: blob_color_fixer.py <path_to_wal_colors>")

    filepath = sys.argv[1]
    colors   = load_colors(filepath)
    accents  = colors[ACCENT_SLICE]

    if not palette_is_bland(accents):
        print("Palette is already vibrant and diverse — nothing to do.")
        return

    print("Monotone / bland palette detected. Generating vibrant harmony…")

    base        = most_saturated(accents)
    new_accents = [vibrant_shift(base, shift) for shift in HUE_SHIFTS]

    for i, color in enumerate(new_accents):
        colors[i + 1]                  = color
        colors[i + 1 + BRIGHT_OFFSET]  = color

    save_colors(filepath, colors)
    print("Done — colors enhanced and written back to file.")


if __name__ == "__main__":
    main()