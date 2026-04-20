#!/usr/bin/env python3
import sys
import colorsys

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) / 255.0 for i in (0, 2, 4))

def rgb_to_hex(r, g, b):
    return '#{:02x}{:02x}{:02x}'.format(int(r * 255), int(g * 255), int(b * 255))

def shift_hue_and_saturate(hex_str, shift_amount):
    r, g, b = hex_to_rgb(hex_str)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    h = (h + shift_amount) % 1.0
    s = max(s, 0.65) # Force vibrancy
    l = min(max(l, 0.4), 0.7) # Ensure it's not too dark or overly washed out
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return rgb_to_hex(r, g, b)

def get_hls_stats(hex_list):
    hues = []
    sats = []
    for hex_str in hex_list:
        r, g, b = hex_to_rgb(hex_str)
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        hues.append(h)
        sats.append(s)
    return hues, sats

def is_monotone_or_bland(hues, sats, hue_threshold=0.15, sat_threshold=0.35):
    if not hues or not sats: return False
    
    # Calculate hue variance
    min_h = min(hues)
    max_h = max(hues)
    hue_diff = min(max_h - min_h, 1.0 - (max_h - min_h))
    
    # Calculate average saturation
    avg_s = sum(sats) / len(sats)
    
    return hue_diff < hue_threshold or avg_s < sat_threshold

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
        
    # Check hue variance and saturation of accent colors (indices 1-6)
    accents = colors[1:7]
    hues, sats = get_hls_stats(accents)
    
    if is_monotone_or_bland(hues, sats, hue_threshold=0.15, sat_threshold=0.35):
        print("Detected monotone or bland palette. Generating vibrant complementary colors...")
        
        # Pick the most saturated accent as the base
        base_accent = accents[-1]
        max_sat = 0
        for i, sat in enumerate(sats):
            if sat > max_sat:
                max_sat = sat
                base_accent = accents[i]
                
        # Generate new colors with forced vibrancy
        comp = shift_hue_and_saturate(base_accent, 0.5)
        ana1 = shift_hue_and_saturate(base_accent, 0.083)
        ana2 = shift_hue_and_saturate(base_accent, -0.083)
        split1 = shift_hue_and_saturate(base_accent, 0.416)
        split2 = shift_hue_and_saturate(base_accent, -0.416)
        
        # The base accent itself also gets saturated if it was too bland
        r, g, b = hex_to_rgb(base_accent)
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        if s < 0.65:
            base_vibrant = shift_hue_and_saturate(base_accent, 0.0)
        else:
            base_vibrant = base_accent
            
        new_accents = [base_vibrant, comp, ana1, ana2, split1, split2]
        
        # Replace normal and bright accents
        for i in range(6):
            colors[i+1] = new_accents[i]
            colors[i+9] = new_accents[i]
            
        with open(filepath, 'w') as f:
            for color in colors:
                f.write(f"{color}\n")
        print("Colors successfully enhanced.")
    else:
        print("Palette is already vibrant and diverse enough.")

if __name__ == "__main__":
    main()