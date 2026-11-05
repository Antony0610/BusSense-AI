import os
from PIL import Image, ImageDraw, ImageFont

artifact_dir = r"C:\Users\Admin\.gemini\antigravity\brain\a60c6a03-0c93-459a-a20c-4a9cbbbce86e"
os.makedirs(artifact_dir, exist_ok=True)

SIZE = 512
SCALE = 4
CANVAS_SIZE = SIZE * SCALE  # 2048x2048

# Color Palette (Stitch)
COLOR_BG = (0, 38, 32)            # #002620 Deep Evergreen
COLOR_MINT = (108, 248, 187)      # #6CF8BB Electric Mint
COLOR_EMERALD = (0, 108, 73)      # #006C49 Vibrant Emerald
COLOR_FOREST = (18, 60, 53)       # #123C35 Forest Slate
COLOR_WHITE = (255, 255, 255)     # #FFFFFF Pure White
COLOR_MINT_LIGHT = (224, 255, 242) # #E0FFF2

def create_squircle_mask(size, radius):
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size, size)], radius=radius, fill=255)
    return mask

# ==============================================================================
# OPTION 1: Modern Transit Sensor
# ==============================================================================
def draw_option_1():
    img = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Squircle
    draw.rounded_rectangle([(0, 0), (CANVAS_SIZE, CANVAS_SIZE)], radius=440, fill=COLOR_BG)

    # 2. Subtle gradient / inner glow ring
    draw.rounded_rectangle([(40, 40), (CANVAS_SIZE-40, CANVAS_SIZE-40)], radius=400, outline=COLOR_FOREST, width=24)

    # 3. Radar Waves (Top)
    # Outer wave
    draw.arc([(CANVAS_SIZE//2 - 380, 240), (CANVAS_SIZE//2 + 380, 760)], start=210, end=330, fill=COLOR_EMERALD, width=36)
    # Inner wave
    draw.arc([(CANVAS_SIZE//2 - 240, 360), (CANVAS_SIZE//2 + 240, 680)], start=210, end=330, fill=COLOR_MINT, width=44)
    # Pulse dot at antenna tip
    draw.ellipse([(CANVAS_SIZE//2 - 28, 510), (CANVAS_SIZE//2 + 28, 566)], fill=COLOR_MINT)

    # 4. Minimalist Bus Silhouette
    bus_left = CANVAS_SIZE // 2 - 460
    bus_right = CANVAS_SIZE // 2 + 460
    bus_top = 620
    bus_bottom = 1620
    bus_radius = 160

    # Bus Body
    draw.rounded_rectangle([(bus_left, bus_top), (bus_right, bus_bottom)], radius=bus_radius, fill=COLOR_FOREST, outline=COLOR_MINT, width=28)

    # Windshield (Large panoramic)
    ws_left = bus_left + 64
    ws_right = bus_right - 64
    ws_top = bus_top + 80
    ws_bottom = bus_top + 460
    draw.rounded_rectangle([(ws_left, ws_top), (ws_right, ws_bottom)], radius=90, fill=COLOR_BG, outline=COLOR_MINT, width=20)

    # Driver & Route Indicator bar inside windshield
    draw.rounded_rectangle([(CANVAS_SIZE//2 - 160, ws_top + 40), (CANVAS_SIZE//2 + 160, ws_top + 90)], radius=24, fill=COLOR_MINT)

    # Two minimalist headlights
    hl_y = bus_top + 570
    draw.ellipse([(bus_left + 90, hl_y), (bus_left + 210, hl_y + 120)], fill=COLOR_MINT)
    draw.ellipse([(bus_right - 210, hl_y), (bus_right - 90, hl_y + 120)], fill=COLOR_MINT)

    # Sleek Center Emblem / Sensor Badge on grille
    draw.rounded_rectangle([(CANVAS_SIZE//2 - 110, hl_y + 20), (CANVAS_SIZE//2 + 110, hl_y + 100)], radius=40, fill=COLOR_EMERALD)
    draw.ellipse([(CANVAS_SIZE//2 - 20, hl_y + 40), (CANVAS_SIZE//2 + 20, hl_y + 80)], fill=COLOR_MINT)

    # Lower Bumper / Air Dam
    draw.rounded_rectangle([(bus_left + 120, bus_bottom - 240), (bus_right - 120, bus_bottom - 160)], radius=36, fill=COLOR_BG, outline=COLOR_MINT, width=16)

    # Wheels (Subtle bottom tabs)
    wheel_w = 90
    wheel_h = 100
    draw.rounded_rectangle([(bus_left + 80, bus_bottom - 30), (bus_left + 80 + wheel_w, bus_bottom + wheel_h)], radius=30, fill=COLOR_MINT)
    draw.rounded_rectangle([(bus_right - 80 - wheel_w, bus_bottom - 30), (bus_right - 80, bus_bottom + wheel_h)], radius=30, fill=COLOR_MINT)

    # Downsample with Lanczos
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    res.save(os.path.join(artifact_dir, "icon_option_1.png"), "PNG")
    print("Option 1 generated.")

# ==============================================================================
# OPTION 2: Minimalist Monogram "B"
# ==============================================================================
def draw_option_2():
    img = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background Squircle
    draw.rounded_rectangle([(0, 0), (CANVAS_SIZE, CANVAS_SIZE)], radius=440, fill=COLOR_BG)
    draw.rounded_rectangle([(40, 40), (CANVAS_SIZE-40, CANVAS_SIZE-40)], radius=400, outline=COLOR_FOREST, width=24)

    # Vertical Transit Spine (Left bar of 'B')
    spine_x1 = 520
    spine_x2 = 720
    spine_y1 = 440
    spine_y2 = 1600
    draw.rounded_rectangle([(spine_x1, spine_y1), (spine_x2, spine_y2)], radius=100, fill=COLOR_WHITE)

    # Upper Loop of 'B' (Transit Loop 1)
    # Outer arc
    draw.pieslice([(580, 440), (1540, 1080)], start=270, end=90, fill=COLOR_MINT)
    # Inner hole
    draw.pieslice([(720, 580), (1360, 940)], start=270, end=90, fill=COLOR_BG)

    # Lower Loop of 'B' (Transit Loop 2 - slightly larger)
    draw.pieslice([(580, 960), (1600, 1600)], start=270, end=90, fill=COLOR_MINT)
    draw.pieslice([(720, 1100), (1420, 1460)], start=270, end=90, fill=COLOR_BG)

    # Connection patch to cleanly fuse spine & loops
    draw.rectangle([(spine_x2 - 40, 440), (spine_x2 + 40, 1600)], fill=COLOR_BG)
    draw.rounded_rectangle([(spine_x1, spine_y1), (spine_x2, spine_y2)], radius=100, fill=COLOR_WHITE)

    # Accent Sensor Dot in Top Loop
    draw.ellipse([(1000, 710), (1090, 800)], fill=COLOR_EMERALD)

    # Accent Bus Arrow in Bottom Loop
    draw.polygon([(1000, 1280), (1080, 1230), (1080, 1330)], fill=COLOR_EMERALD)

    # Downsample
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    res.save(os.path.join(artifact_dir, "icon_option_2.png"), "PNG")
    print("Option 2 generated.")

# ==============================================================================
# OPTION 3: Geometric Radar Node
# ==============================================================================
def draw_option_3():
    img = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background Squircle
    draw.rounded_rectangle([(0, 0), (CANVAS_SIZE, CANVAS_SIZE)], radius=440, fill=COLOR_BG)
    draw.rounded_rectangle([(40, 40), (CANVAS_SIZE-40, CANVAS_SIZE-40)], radius=400, outline=COLOR_FOREST, width=24)

    center = CANVAS_SIZE // 2

    # Outer Pulse Ring
    r3 = 700
    draw.ellipse([(center - r3, center - r3), (center + r3, center + r3)], outline=COLOR_FOREST, width=32)

    # Middle Radar Ring
    r2 = 500
    draw.ellipse([(center - r2, center - r2), (center + r2, center + r2)], outline=COLOR_EMERALD, width=44)

    # Radar Sweep wedge (semi-transparent feel)
    draw.pieslice([(center - r2 + 22, center - r2 + 22), (center + r2 - 22, center + r2 - 22)], start=290, end=350, fill=COLOR_FOREST)

    # Inner Active Ring
    r1 = 320
    draw.ellipse([(center - r1, center - r1), (center + r1, center + r1)], fill=COLOR_EMERALD, outline=COLOR_MINT, width=28)

    # Center Hub
    draw.ellipse([(center - 160, center - 160), (center + 160, center + 160)], fill=COLOR_MINT)

    # Center Minimal Bus Glyph (Deep Forest)
    b_w = 90
    b_h = 130
    draw.rounded_rectangle([(center - b_w, center - b_h), (center + b_w, center + b_h)], radius=32, fill=COLOR_BG)
    # Windshield
    draw.rounded_rectangle([(center - b_w + 16, center - b_h + 16), (center + b_w - 16, center - 20)], radius=16, fill=COLOR_MINT)
    # Headlights
    draw.ellipse([(center - b_w + 20, center + 30), (center - b_w + 46, center + 56)], fill=COLOR_MINT)
    draw.ellipse([(center + b_w - 46, center + 30), (center + b_w - 20, center + 56)], fill=COLOR_MINT)

    # Orbiting Satellite / Beacon dots on rings
    draw.ellipse([(center + 480, center - 140), (center + 540, center - 80)], fill=COLOR_MINT)
    draw.ellipse([(center - 680, center + 180), (center - 630, center + 230)], fill=COLOR_EMERALD)

    # Downsample
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    res.save(os.path.join(artifact_dir, "icon_option_3.png"), "PNG")
    print("Option 3 generated.")

draw_option_1()
draw_option_2()
draw_option_3()

