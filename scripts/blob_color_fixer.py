#!/usr/bin/env python3
import sys
import colorsys

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    return '#{:02x}{:02x}{:02x}'.format(int(r * 255), int(g * 255), int(b * 255))

def shift_hue(hex_str, shift_amount):
    r, g, b = hex_to_rgb(hex_str)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    h = (h + shift_amount) % 1.0
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return rgb_to_hex(r, g, b)

def get_hues(hex_list):
    hues = []
    for hex_str in hex_list:
        r, g, b = hex_to_rgb(hex_str)
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        hues.append(h)
    return hues

def is_monotone(hues, threshold=0.1):
    # Calculate the maximum distance between any two hues on the color wheel
    if not hues: return False
    min_h = min(hues)
    max_h = max(hues)
    diff = min(max_h - min_h, 1.0 - (max_h - min_h))
    return diff < threshold

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 blob_color_fixer.py <path_to_wal_colors>")
        sys.exit(1)
        
    filepath = sys.argv[1]
    
    try:
        with open(filepath, 'r') as f:
            colors = [line.strip() for line in f if line.strip()]
    except Exception as e:
        print(f"Error reading colors: {e}")
        sys.exit(1)
        
    if len(colors) < 16:
        print("Not enough colors found in file.")
        sys.exit(1)
        
    # Check hue variance of accent colors (indices 1-6)
    accents = colors[1:7]
    hues = get_hues(accents)
    
    if is_monotone(hues, 0.15):
        print("Detected monotone palette. Generating vibrant complementary colors...")
        base_accent = accents[-1] # Usually the last accent is the brightest
        
        # Generate new colors
        comp = shift_hue(base_accent, 0.5)
        ana1 = shift_hue(base_accent, 0.083)
        ana2 = shift_hue(base_accent, -0.083)
        split1 = shift_hue(base_accent, 0.416)
        split2 = shift_hue(base_accent, -0.416)
        
        new_accents = [base_accent, comp, ana1, ana2, split1, split2]
        
        # Replace normal and bright accents
        for i in range(6):
            colors[i+1] = new_accents[i]
            colors[i+9] = new_accents[i]
            
        with open(filepath, 'w') as f:
            for color in colors:
                f.write(f"{color}\n")
        print("Colors successfully enhanced.")
    else:
        print("Palette is already diverse enough.")

if __name__ == "__main__":
    main()