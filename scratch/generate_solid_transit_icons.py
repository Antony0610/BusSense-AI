import os
from PIL import Image, ImageDraw

artifact_dir = r"C:\Users\Admin\.gemini\antigravity\brain\a60c6a03-0c93-459a-a20c-4a9cbbbce86e"
os.makedirs(artifact_dir, exist_ok=True)

SIZE = 512
SCALE = 4
CANVAS_SIZE = SIZE * SCALE  # 2048x2048

# Solid Aesthetic Palette (Inspired by Citymapper, Transit App, SBB)
COLOR_DEEP_EVERGREEN = (0, 38, 32)      # #002620 Solid Deep Kerala Evergreen
COLOR_EMERALD_SOLID = (0, 92, 62)       # #005C3E Solid Punchy Emerald
COLOR_MINT = (108, 248, 187)            # #6CF8BB Electric Mint
COLOR_WHITE = (255, 255, 255)           # #FFFFFF Chalk White
COLOR_OFFWHITE = (245, 250, 247)        # #F5FAF7
COLOR_DARK_GLASS = (10, 30, 26)         # Deep contrast glass

# ==============================================================================
# SOLID OPTION A: "The City Transit Bus" (Inspired by Citymapper / Chalo)
# Solid Evergreen background with a bold, clean, friendly white bus face and mint headlights
# ==============================================================================
def draw_solid_option_a():
    img = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Solid Background Squircle
    draw.rounded_rectangle([(0, 0), (CANVAS_SIZE, CANVAS_SIZE)], radius=460, fill=COLOR_DEEP_EVERGREEN)

    # 2. Main Bus Body (Bold, clean, solid chalk white)
    b_left = 460
    b_right = CANVAS_SIZE - 460
    b_top = 460
    b_bottom = 1580
    draw.rounded_rectangle([(b_left, b_top), (b_right, b_bottom)], radius=200, fill=COLOR_WHITE)

    # 3. Windshield (Deep evergreen rounded cutout for maximum contrast)
    ws_left = b_left + 70
    ws_right = b_right - 70
    ws_top = b_top + 90
    ws_bottom = b_top + 520
    draw.rounded_rectangle([(ws_left, ws_top), (ws_right, ws_bottom)], radius=90, fill=COLOR_DEEP_EVERGREEN)

    # 4. Destination / Telemetry Sign inside windshield (Electric Mint pill)
    draw.rounded_rectangle([(CANVAS_SIZE//2 - 200, ws_top + 50), (CANVAS_SIZE//2 + 200, ws_top + 130)], radius=36, fill=COLOR_MINT)

    # 5. Dual Headlights (Solid Electric Mint circles)
    hl_y = b_top + 680
    hl_r = 85
    # Left headlight
    draw.ellipse([(b_left + 100, hl_y), (b_left + 100 + hl_r*2, hl_y + hl_r*2)], fill=COLOR_MINT)
    # Right headlight
    draw.ellipse([(b_right - 100 - hl_r*2, hl_y), (b_right - 100, hl_y + hl_r*2)], fill=COLOR_MINT)

    # 6. Sleek Minimal Grille / Radar Sensor (Deep Evergreen pill)
    draw.rounded_rectangle([(CANVAS_SIZE//2 - 140, hl_y + 40), (CANVAS_SIZE//2 + 140, hl_y + 130)], radius=45, fill=COLOR_DEEP_EVERGREEN)

    # 7. Lower Air Bumper / Transit Track (Deep Evergreen bar)
    draw.rounded_rectangle([(b_left + 120, b_bottom - 180), (b_right - 120, b_bottom - 110)], radius=35, fill=COLOR_DEEP_EVERGREEN)

    # 8. Wheels (Solid deep evergreen tabs)
    draw.rounded_rectangle([(b_left + 110, b_bottom - 20), (b_left + 260, b_bottom + 120)], radius=40, fill=COLOR_WHITE)
    draw.rounded_rectangle([(b_right - 260, b_bottom - 20), (b_right - 110, b_bottom + 120)], radius=40, fill=COLOR_WHITE)

    # Downsample with Lanczos
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    res.save(os.path.join(artifact_dir, "icon_solid_a_citymapper_style.png"), "PNG")
    print("Solid Option A generated.")

# ==============================================================================
# SOLID OPTION B: "The Transit Line Curve" (Inspired by Transit App / Metro)
# Solid Emerald background with a continuous bold white transit line and mint hub node
# ==============================================================================
def draw_solid_option_b():
    img = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Solid Background Squircle (Vibrant Deep Emerald)
    draw.rounded_rectangle([(0, 0), (CANVAS_SIZE, CANVAS_SIZE)], radius=460, fill=COLOR_EMERALD_SOLID)

    # 2. Continuous Bold Transit Track (Clean sweeping curve from bottom-left to top-right)
    # Outer white track
    draw.arc([(260, 260), (CANVAS_SIZE - 260, CANVAS_SIZE - 260)], start=135, end=315, fill=COLOR_WHITE, width=180)
    
    # Bottom horizontal straight track coming in
    draw.line([(320, 1620), (960, 1620)], fill=COLOR_WHITE, width=180)
    # Smooth corner joint
    draw.arc([(500, 1160), (1420, 2080)], start=180, end=270, fill=COLOR_WHITE, width=180)

    # Top diagonal straight track exiting
    draw.line([(1080, 420), (1720, 420)], fill=COLOR_WHITE, width=180)
    draw.arc([(620, -40), (1540, 880)], start=0, end=90, fill=COLOR_WHITE, width=180)

    # 3. Intersecting Central Station Node (Electric Mint solid circle)
    center_x = CANVAS_SIZE // 2
    center_y = CANVAS_SIZE // 2
    node_r = 260
    draw.ellipse([(center_x - node_r, center_y - node_r), (center_x + node_r, center_y + node_r)], fill=COLOR_MINT)

    # Inner core dot in deep emerald
    inner_r = 130
    draw.ellipse([(center_x - inner_r, center_y - inner_r), (center_x + inner_r, center_y + inner_r)], fill=COLOR_DEEP_EVERGREEN)

    # 4. Forward Transit Arrow at terminal
    arrow_size = 90
    draw.polygon([(1700, 420), (1560, 310), (1560, 530)], fill=COLOR_MINT)

    # Downsample
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    res.save(os.path.join(artifact_dir, "icon_solid_b_transit_curve.png"), "PNG")
    print("Solid Option B generated.")

# ==============================================================================
# SOLID OPTION C: "The Nordic Rail / Metro Monogram" (Inspired by SBB / Tokyo Metro)
# Solid Deep Evergreen with crisp geometric transit arrows and clean bus front
# ==============================================================================
def draw_solid_option_c():
    img = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Solid Background Squircle
    draw.rounded_rectangle([(0, 0), (CANVAS_SIZE, CANVAS_SIZE)], radius=460, fill=COLOR_DEEP_EVERGREEN)

    # 2. Bold Geometric Transit Monogram (Stylized 'B' formed by forward bus arrow & return loop)
    # Vertical rail spine
    draw.rounded_rectangle([(440, 420), (660, 1620)], radius=80, fill=COLOR_WHITE)

    # Top loop (Forward mobility wing) in solid Electric Mint
    draw.rounded_rectangle([(660, 420), (1540, 960)], radius=140, fill=COLOR_MINT)
    # Inner cutout for clean negative space
    draw.rounded_rectangle([(840, 580), (1360, 800)], radius=70, fill=COLOR_DEEP_EVERGREEN)

    # Bottom loop (Return loop) in solid Chalk White
    draw.rounded_rectangle([(660, 1080), (1600, 1620)], radius=140, fill=COLOR_WHITE)
    # Inner cutout
    draw.rounded_rectangle([(840, 1240), (1420, 1460)], radius=70, fill=COLOR_DEEP_EVERGREEN)

    # Clean center accent: Mint passenger beacon inside bottom cutout
    draw.ellipse([(1080, 1310), (1180, 1390)], fill=COLOR_MINT)

    # Downsample
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    res.save(os.path.join(artifact_dir, "icon_solid_c_nordic_transit.png"), "PNG")
    print("Solid Option C generated.")

draw_solid_option_a()
draw_solid_option_b()
draw_solid_option_c()

