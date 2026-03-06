#!/usr/bin/env python3
"""Convert a PNG image to a cowsay .cow file using ANSI 256-color + unicode half-blocks."""

import argparse
import sys
from pathlib import Path

from PIL import Image


def _build_xterm_palette():
    """Build RGB values for xterm-256 colors (indices 16-255)."""
    palette = {}
    # 6x6x6 color cube (indices 16-231)
    levels = [0, 0x5F, 0x87, 0xAF, 0xD7, 0xFF]
    for i in range(216):
        r = levels[i // 36]
        g = levels[(i // 6) % 6]
        b = levels[i % 6]
        palette[16 + i] = (r, g, b)
    # Grayscale ramp (indices 232-255)
    for i in range(24):
        v = 8 + 10 * i
        palette[232 + i] = (v, v, v)
    return palette


PALETTE = _build_xterm_palette()


def nearest_xterm(r, g, b):
    """Find the nearest xterm-256 color index for an RGB value."""
    best_idx = 16
    best_dist = float("inf")
    for idx, (pr, pg, pb) in PALETTE.items():
        dist = (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
        if dist < best_dist:
            best_dist = dist
            best_idx = idx
    return best_idx


def is_transparent(pixel):
    """Check if a pixel is fully or nearly transparent."""
    if len(pixel) < 4:
        return False
    return pixel[3] < 32


def png_to_cow(png_path, cow_path, mirror=True, max_height=None):
    img = Image.open(png_path).convert("RGBA")

    if mirror:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)

    # Trim transparent borders before scaling
    pixels = img.load()
    w, h = img.size
    left = top = float("inf")
    right = bottom = 0
    for y in range(h):
        for x in range(w):
            if not is_transparent(pixels[x, y]):
                left = min(left, x)
                right = max(right, x)
                top = min(top, y)
                bottom = max(bottom, y)

    if left > right:
        print(f"Error: image is fully transparent: {png_path}", file=sys.stderr)
        sys.exit(1)

    img = img.crop((left, top, right + 1, bottom + 1))
    w, h = img.size

    # Scale down if needed (max_height is in terminal rows, each = 2 pixels)
    if max_height is not None:
        max_px_height = max_height * 2
        if h > max_px_height:
            scale = max_px_height / h
            new_w = max(1, int(w * scale))
            new_h = max_px_height
            img = img.resize((new_w, new_h), Image.LANCZOS)

    pixels = img.load()
    w, h = img.size

    # Pad height to even number (we process 2 rows at a time)
    if h % 2 != 0:
        h += 1

    # Build lines using half-block characters.
    # Each output character represents 2 vertical pixels:
    #   ▄ (U+2584): fg = bottom pixel, bg = top pixel
    #   ▀ (U+2580): fg = top pixel, bg = default
    #   ' ' with bg color when both pixels are the same

    lines = []
    for y in range(0, h, 2):
        line = ""
        last_fg = -1
        last_bg = -1

        for x in range(w):
            if y < img.size[1]:
                top_px = pixels[x, y]
                top_trans = is_transparent(top_px)
            else:
                top_trans = True
                top_px = (0, 0, 0, 0)

            if y + 1 < img.size[1]:
                bot_px = pixels[x, y + 1]
                bot_trans = is_transparent(bot_px)
            else:
                bot_trans = True
                bot_px = (0, 0, 0, 0)

            if top_trans and bot_trans:
                if last_bg != -2:
                    line += "\\e[49m"
                    last_bg = -2
                line += " "
                last_fg = -1
            elif top_trans:
                bot_color = nearest_xterm(*bot_px[:3])
                if last_bg != -2:
                    line += "\\e[49m"
                    last_bg = -2
                if last_fg != bot_color:
                    line += f"\\e[38;5;{bot_color}m"
                    last_fg = bot_color
                line += "\\N{U+2584}"
            elif bot_trans:
                top_color = nearest_xterm(*top_px[:3])
                if last_bg != -2:
                    line += "\\e[49m"
                    last_bg = -2
                if last_fg != top_color:
                    line += f"\\e[38;5;{top_color}m"
                    last_fg = top_color
                line += "\\N{U+2580}"
            else:
                top_color = nearest_xterm(*top_px[:3])
                bot_color = nearest_xterm(*bot_px[:3])
                if top_color == bot_color:
                    if last_bg != top_color:
                        line += f"\\e[48;5;{top_color}m"
                        last_bg = top_color
                    line += " "
                else:
                    if last_bg != top_color:
                        line += f"\\e[48;5;{top_color}m"
                        last_bg = top_color
                    if last_fg != bot_color:
                        line += f"\\e[38;5;{bot_color}m"
                        last_fg = bot_color
                    line += "\\N{U+2584}"

        # Reset at end of line
        line += "\\e[49m\\e[39m"
        lines.append(line)

    # Strip trailing blank lines
    while lines:
        stripped = lines[-1].replace("\\e[49m", "").replace("\\e[39m", "").strip()
        if not stripped:
            lines.pop()
        else:
            break

    # Build cow file
    indent = " " * 11
    cow = 'binmode STDOUT, ":utf8";\n'
    cow += "$the_cow =<<EOC;\n"
    cow += f"{indent}$thoughts\n"
    cow += f"{indent} $thoughts\n"
    cow += f"{indent}  $thoughts\n"
    cow += f"{indent}   $thoughts\n"

    for line in lines:
        cow += line + "\n"

    cow += "\nEOC\n"

    Path(cow_path).write_text(cow)


def main():
    parser = argparse.ArgumentParser(description="Convert PNG to cowsay .cow file")
    parser.add_argument("input", help="Input PNG file")
    parser.add_argument("output", help="Output .cow file")
    parser.add_argument(
        "--max-height",
        type=int,
        default=None,
        help="Maximum height in terminal rows (each row = 2 pixels)",
    )
    parser.add_argument(
        "--no-mirror",
        action="store_true",
        help="Don't mirror the image horizontally",
    )
    args = parser.parse_args()
    png_to_cow(args.input, args.output, mirror=not args.no_mirror, max_height=args.max_height)


if __name__ == "__main__":
    main()
