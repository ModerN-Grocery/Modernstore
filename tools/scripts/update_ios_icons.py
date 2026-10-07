import json
import os
from PIL import Image

def update_icon_set(source_img, appicon_dir):
    contents_path = os.path.join(appicon_dir, 'Contents.json')
    if not os.path.exists(contents_path):
        print(f"Skipping {appicon_dir}, no Contents.json")
        return
        
    with open(contents_path, 'r') as f:
        data = json.load(f)
        
    images_meta = data.get('images', [])
    print(f"Updating {len(images_meta)} icons in {appicon_dir}...")
    
    for item in images_meta:
        filename = item.get('filename')
        if not filename:
            continue
            
        size_str = item.get('size')  # e.g. "20x20", "83.5x83.5"
        scale_str = item.get('scale', '1x')  # e.g. "1x", "2x", "3x"
        
        w_str, h_str = size_str.split('x')
        base_w = float(w_str)
        base_h = float(h_str)
        scale = float(scale_str.replace('x', ''))
        
        pixel_w = int(round(base_w * scale))
        pixel_h = int(round(base_h * scale))
        
        resized = source_img.resize((pixel_w, pixel_h), Image.Resampling.LANCZOS)
        
        out_path = os.path.join(appicon_dir, filename)
        if pixel_w == 1024 and pixel_h == 1024:
            resized_rgb = resized.convert('RGB')
            resized_rgb.save(out_path, format='PNG')
        else:
            resized.save(out_path, format='PNG')
            
    print(f"Finished updating {appicon_dir}!")

def main():
    icon_source_path = 'assets/New Icon.png'
    if not os.path.exists(icon_source_path):
        print(f"Error: {icon_source_path} does not exist!")
        return
        
    source_img = Image.open(icon_source_path).convert('RGBA')
    
    # Update both AppIcon and AppIcon-user
    update_icon_set(source_img, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    update_icon_set(source_img, 'ios/Runner/Assets.xcassets/AppIcon-user.appiconset')
    print("All iOS app icons updated successfully with New Icon.png!")

if __name__ == '__main__':
    main()
