import os
from PIL import Image, ImageDraw

base_res = r"d:\Bus_Sense_Ai\apps\mobile\android\app\src\main\res"
artifact_dir = r"C:\Users\Admin\.gemini\antigravity\brain\a60c6a03-0c93-459a-a20c-4a9cbbbce86e"
source_icon_path = os.path.join(artifact_dir, "icon_option_1.png")

# Open high-res source icon
src = Image.open(source_icon_path).convert('RGBA')

# Target resolutions for standard Android mipmaps
densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in densities.items():
    folder_path = os.path.join(base_res, folder)
    os.makedirs(folder_path, exist_ok=True)
    
    # 1. Square / rounded squircle icon
    icon_resized = src.resize((size, size), Image.Resampling.LANCZOS)
    icon_resized.save(os.path.join(folder_path, "ic_launcher.png"), "PNG")
    
    # 2. Round icon (masked inside a circle)
    round_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([(0, 0), (size, size)], fill=255)
    round_img.paste(icon_resized, (0, 0), mask)
    round_img.save(os.path.join(folder_path, "ic_launcher_round.png"), "PNG")
    print(f"Generated {folder}: {size}x{size}")

# 3. Generate adaptive icon foreground (432x432 with 260x260 centered icon)
drawable_dir = os.path.join(base_res, "drawable")
os.makedirs(drawable_dir, exist_ok=True)
fg = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
inner_size = 280
offset = (432 - inner_size) // 2
inner_icon = src.resize((inner_size, inner_size), Image.Resampling.LANCZOS)
fg.paste(inner_icon, (offset, offset), inner_icon)
fg.save(os.path.join(drawable_dir, "ic_launcher_foreground.png"), "PNG")
print("Generated adaptive foreground.")

# 4. Generate values/ic_launcher_background.xml
values_dir = os.path.join(base_res, "values")
os.makedirs(values_dir, exist_ok=True)
bg_xml = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#002620</color>
</resources>
'''
with open(os.path.join(values_dir, "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
    f.write(bg_xml)

# 5. Generate mipmap-anydpi-v26 adaptive icon XML files
anydpi_dir = os.path.join(base_res, "mipmap-anydpi-v26")
os.makedirs(anydpi_dir, exist_ok=True)

adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
'''
with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
    f.write(adaptive_xml)

with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
    f.write(adaptive_xml)

print("Android launcher icon assets installed successfully!")

