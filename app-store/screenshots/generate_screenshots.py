"""
Your Date Genie — App Store Connect screenshot generator
Output: 6 PNGs at 1320 x 2868 px (iPhone 6.9" — iPhone 16 Pro Max)
Color: sRGB, no alpha. Apple-compliant.

Brand tokens straight from website/claude-design-bundle/project/colors_and_type.css
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math

# ---------- Canvas ----------
W, H = 1320, 2868  # iPhone 6.9" portrait — Apple spec

# ---------- Brand tokens (from colors_and_type.css) ----------
WINE         = (74, 14, 16)     # --ydg-wine-bg #4A0E10
WINE_DEEP    = (59, 10, 12)     # --ydg-wine-deep #3B0A0C
WINE_HIGH    = (90, 20, 22)     # --ydg-wine #5A1416
BONE         = (244, 239, 231)  # --ydg-bone #F4EFE7
CREAM        = (239, 231, 218)  # --ydg-cream #EFE7DA
BRASS        = (200, 146, 74)   # --ydg-brass #C8924A
CHAMPAGNE    = (212, 168, 90)   # --ydg-champagne #D4A85A
CHAMPAGNE_SOFT = (232, 201, 136)# --ydg-champagne-soft
INK          = (26, 23, 20)     # --ydg-ink
INK_SOFT     = (43, 39, 34)     # --ydg-ink-soft
GRAPHITE     = (91, 84, 77)     # --ydg-graphite
BLUSH        = (232, 200, 184)  # --ydg-blush

# ---------- Fonts ----------
FONT_DISPLAY = "/usr/share/fonts/truetype/google-fonts/Lora-Variable.ttf"
FONT_DISPLAY_IT = "/usr/share/fonts/truetype/google-fonts/Lora-Italic-Variable.ttf"
FONT_UI      = "/usr/share/fonts/truetype/google-fonts/Poppins-Medium.ttf"
FONT_UI_REG  = "/usr/share/fonts/truetype/google-fonts/Poppins-Regular.ttf"
FONT_UI_LIGHT= "/usr/share/fonts/truetype/google-fonts/Poppins-Light.ttf"
FONT_UI_BOLD = "/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf"
FONT_SC      = "/usr/share/fonts/truetype/google-fonts/Poppins-Light.ttf"  # small caps stand-in

def F(path, size):
    return ImageFont.truetype(path, size)

# ---------- Helpers ----------
def vertical_gradient(width, height, top, bottom):
    """Smooth vertical gradient between two RGB colors."""
    base = Image.new("RGB", (1, height))
    px = base.load()
    for y in range(height):
        t = y / max(1, height - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        px[0, y] = (r, g, b)
    return base.resize((width, height), Image.LANCZOS)

def radial_glow(width, height, center, radius, color, intensity=0.35):
    """Soft radial glow blended over background."""
    layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    steps = 40
    for i in range(steps, 0, -1):
        rr = int(radius * (i / steps))
        alpha = int(255 * intensity * (1 - i / steps) ** 2)
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr),
                  fill=(color[0], color[1], color[2], alpha))
    return layer.filter(ImageFilter.GaussianBlur(80))

def text_w(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]

def text_h(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[3] - bbox[1]

def wrap_lines(draw, text, font, max_w):
    """Greedy word wrap."""
    words = text.split()
    lines, cur = [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if text_w(draw, test, font) <= max_w:
            cur = test
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines

def draw_eyebrow(draw, text, x, y, font, color=CHAMPAGNE):
    """Small-caps style label with brass color and tracking."""
    spaced = "  ".join(list(text.upper()))
    draw.text((x, y), spaced, font=font, fill=color)
    return text_w(draw, spaced, font)

def draw_centered_block(img, lines_data, top_y):
    """lines_data = [(text, font, color, gap_after)]"""
    draw = ImageDraw.Draw(img)
    y = top_y
    for text, font, color, gap in lines_data:
        tw = text_w(draw, text, font)
        x = (W - tw) // 2
        # Subtle text shadow for depth on wine bg
        if color != INK:
            draw.text((x + 2, y + 3), text, font=font, fill=(0, 0, 0, 80))
        draw.text((x, y), text, font=font, fill=color)
        bbox = draw.textbbox((x, y), text, font=font)
        y = bbox[3] + gap
    return y

def rounded_rect(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)

# ---------- Device frame ----------
def draw_phone_frame(img, top_y, scale=1.0, screen_renderer=None, screen_args=None):
    """
    Draw iPhone-style device frame, return (frame_top, frame_bottom).
    screen_renderer is a function(canvas, x, y, w, h) that paints inside the screen.
    """
    # iPhone 16 Pro Max physical aspect 19.5:9
    # Frame width on canvas
    pad_h = int(120 * scale)
    frame_w = int(W - pad_h * 2)
    # Screen aspect 19.5:9 => h/w = 2.166...
    screen_aspect = 2.165
    frame_aspect = screen_aspect * 1.005  # tiny bezel
    frame_h = int(frame_w * frame_aspect)

    fx = (W - frame_w) // 2
    fy = top_y

    draw = ImageDraw.Draw(img)

    # Outer phone body — dark obsidian with brass hairline
    body = (14, 11, 9)
    bezel = (28, 22, 18)
    rounded_rect(draw, (fx, fy, fx + frame_w, fy + frame_h),
                 radius=int(78 * scale), fill=body)

    # Brass hairline edge
    rounded_rect(draw, (fx + 2, fy + 2, fx + frame_w - 2, fy + frame_h - 2),
                 radius=int(76 * scale), fill=None,
                 outline=(180, 134, 70), width=2)

    # Inner screen
    bezel_pad = int(18 * scale)
    sx = fx + bezel_pad
    sy = fy + bezel_pad
    sw = frame_w - bezel_pad * 2
    sh = frame_h - bezel_pad * 2

    # Screen background
    screen = Image.new("RGB", (sw, sh), WINE)
    sdraw = ImageDraw.Draw(screen)

    if screen_renderer:
        screen_renderer(screen, sdraw, screen_args or {})

    # Mask screen to rounded corners
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=int(62 * scale), fill=255)
    img.paste(screen, (sx, sy), mask)

    # Dynamic Island
    di_w = int(280 * scale)
    di_h = int(70 * scale)
    di_x = sx + (sw - di_w) // 2
    di_y = sy + int(28 * scale)
    rounded_rect(draw, (di_x, di_y, di_x + di_w, di_y + di_h),
                 radius=int(di_h / 2), fill=(8, 6, 5))

    return fy, fy + frame_h

# ---------- Mock screen renderers ----------
def status_bar(draw, x, y, w, color=BONE):
    """Status bar with time + signal/battery glyphs."""
    f_time = F(FONT_UI_BOLD, 36)
    draw.text((x + 60, y), "9:41", font=f_time, fill=color)
    # Simplified right side: signal bars + wifi + battery
    bx = x + w - 60
    by = y + 6
    # battery
    draw.rounded_rectangle((bx - 80, by + 4, bx, by + 28), radius=6, outline=color, width=3)
    draw.rectangle((bx - 76, by + 8, bx - 20, by + 24), fill=color)
    draw.rectangle((bx + 2, by + 10, bx + 6, by + 22), fill=color)
    # wifi (3 arcs)
    wx = bx - 130
    for i in range(3):
        r = 8 + i * 6
        draw.arc((wx - r, by + 18 - r, wx + r, by + 18 + r), 220, 320, fill=color, width=3)
    # signal dots
    sx = bx - 200
    for i in range(4):
        h = 6 + i * 5
        draw.rectangle((sx + i * 9, by + 26 - h, sx + i * 9 + 6, by + 26), fill=color)

def home_indicator(draw, x, y, w, color=(255, 255, 255, 180)):
    cx = x + w // 2
    draw.rounded_rectangle((cx - 100, y, cx + 100, y + 8), radius=4, fill=BONE)

def draw_ornament(draw, cx, cy, width, color):
    """Vintage menu-card-style horizontal ornament: line-dot-diamond-dot-line."""
    half = width // 2
    # Outer hairlines
    draw.rectangle((cx - half, cy - 1, cx - 60, cy + 1), fill=color)
    draw.rectangle((cx + 60, cy - 1, cx + half, cy + 1), fill=color)
    # Dots
    draw.ellipse((cx - 56, cy - 4, cx - 48, cy + 4), fill=color)
    draw.ellipse((cx + 48, cy - 4, cx + 56, cy + 4), fill=color)
    # Diamond
    pts = [(cx - 22, cy), (cx, cy - 14), (cx + 22, cy), (cx, cy + 14)]
    draw.polygon(pts, outline=color, width=2)
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=color)


def screen_home(canvas, draw, args):
    """Screen 1 — Clean reveal card (timeline + chips, no chat bubble)"""
    sw, sh = canvas.size

    # Deep wine gradient
    g = vertical_gradient(sw, sh, (90, 20, 22), (42, 9, 11))
    canvas.paste(g, (0, 0))
    glow = radial_glow(sw, sh, (sw // 2, 280), 500, CHAMPAGNE, 0.20)
    canvas.paste(glow, (0, 0), glow)

    status_bar(draw, 0, 50, sw)

    # Brand eyebrow + date
    f_eye = F(FONT_UI_LIGHT, 26)
    eyebrow = "Y O U R   D A T E   G E N I E"
    tw = text_w(draw, eyebrow, f_eye)
    draw.text(((sw - tw) // 2, 220), eyebrow, font=f_eye, fill=CHAMPAGNE)

    f_date = F(FONT_DISPLAY_IT, 34)
    date = "Wednesday, May 20"
    dw = text_w(draw, date, f_date)
    draw.text(((sw - dw) // 2, 265), date, font=f_date, fill=BLUSH)

    # Ornament
    draw_ornament(draw, sw // 2, 340, 380, CHAMPAGNE)

    # ---- Reveal card ----
    card_top = 400
    card_pad = 80
    cx1 = card_pad
    cx2 = sw - card_pad
    card_h = 1380

    overlay = Image.new("RGBA", (cx2 - cx1, card_h), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle((0, 0, cx2 - cx1, card_h), radius=40,
                         fill=(244, 239, 231, 18),
                         outline=(212, 168, 90, 200), width=2)
    canvas.paste(overlay, (cx1, card_top), overlay)

    inner_x = cx1 + 60
    cy = card_top + 60

    # Small section label
    f_label = F(FONT_UI_LIGHT, 22)
    draw.text((inner_x, cy), "T O N I G H T ' S   P L A N", font=f_label, fill=CHAMPAGNE)
    cy += 60

    # Hero title — italic serif, two lines
    f_plan_title = F(FONT_DISPLAY_IT, 84)
    draw.text((inner_x, cy), "Three stops,", font=f_plan_title, fill=BONE)
    cy += 100
    draw.text((inner_x, cy), "one Brooklyn night.", font=f_plan_title, fill=BONE)
    cy += 130

    # Lede line
    f_lede = F(FONT_DISPLAY_IT, 32)
    draw.text((inner_x, cy),
              "Curated around your night,",
              font=f_lede, fill=BLUSH)
    cy += 46
    draw.text((inner_x, cy),
              "down to the last scoop.",
              font=f_lede, fill=BLUSH)
    cy += 90

    # Personalization chips (proof of personalization)
    f_chip = F(FONT_UI, 26)
    chip_pad = 32
    chips = ["Nut-free", "Shellfish-free", "$$", "Brooklyn"]
    cxx = inner_x
    chip_y = cy
    for label in chips:
        cw = text_w(draw, label, f_chip) + chip_pad * 2
        if cxx + cw > cx2 - 40:
            cxx = inner_x
            chip_y += 76
        draw.rounded_rectangle((cxx, chip_y, cxx + cw, chip_y + 60),
                               radius=30, outline=CHAMPAGNE, width=2)
        draw.text((cxx + chip_pad, chip_y + 14), label, font=f_chip, fill=CHAMPAGNE)
        cxx += cw + 16
    cy = chip_y + 110

    # Timeline with 3 stops
    rail_x = inner_x + 14
    stops = [
        ("7:00", "Aurora Trattoria",     "Greenpoint • slow Italian"),
        ("8:30", "Pierogi Bar",          "Polish dessert hop"),
        ("9:30", "Brooklyn Bridge walk", "Skyline finish"),
    ]
    f_time = F(FONT_DISPLAY, 38)
    f_name = F(FONT_DISPLAY, 44)
    f_meta = F(FONT_DISPLAY_IT, 28)

    row_h = 180
    for i, (time, name, meta) in enumerate(stops):
        # Timeline dot
        draw.ellipse((rail_x - 14, cy + 14, rail_x + 14, cy + 42),
                     fill=CHAMPAGNE)
        # Rail line (only if not last)
        if i < len(stops) - 1:
            draw.rectangle((rail_x - 2, cy + 42, rail_x + 2, cy + row_h - 8),
                           fill=(212, 168, 90, 140))

        # Time
        draw.text((rail_x + 50, cy + 10), time, font=f_time, fill=CHAMPAGNE)
        # Name
        draw.text((rail_x + 50, cy + 60), name, font=f_name, fill=BONE)
        # Meta
        draw.text((rail_x + 50, cy + 118), meta, font=f_meta, fill=BLUSH)

        cy += row_h

    # ---- CTA below card ----
    btn_y = card_top + card_h + 60
    btn_w = 620
    btn_h = 120
    btn_x = (sw - btn_w) // 2
    draw.rounded_rectangle((btn_x, btn_y, btn_x + btn_w, btn_y + btn_h),
                           radius=60, fill=CHAMPAGNE)
    f_btn = F(FONT_UI_BOLD, 40)
    bt = "Lock In Tonight"
    bw = text_w(draw, bt, f_btn)
    draw.text(((sw - bw) // 2, btn_y + 36), bt, font=f_btn, fill=WINE_DEEP)

    home_indicator(draw, 0, sh - 30, sw)


def screen_setup(canvas, draw, args):
    """Screen 2 — Setup / personalization (mood, budget, allergies, interests)"""
    sw, sh = canvas.size
    g = vertical_gradient(sw, sh, (88, 18, 20), (50, 11, 13))
    canvas.paste(g, (0, 0))
    glow = radial_glow(sw, sh, (200, 600), 450, CHAMPAGNE, 0.16)
    canvas.paste(glow, (0, 0), glow)

    status_bar(draw, 0, 50, sw)

    # Header
    f_eye = F(FONT_UI_LIGHT, 24)
    draw.text((90, 220), "S T E P   2   O F   4", font=f_eye, fill=CHAMPAGNE)

    f_h = F(FONT_DISPLAY_IT, 76)
    draw.text((90, 270), "Tell us about", font=f_h, fill=BONE)
    draw.text((90, 352), "you two.", font=f_h, fill=BONE)

    # ---- Helpers for sectioned form ----
    f_section = F(FONT_UI_LIGHT, 24)           # small-caps section label
    f_section_val = F(FONT_DISPLAY_IT, 36)     # italic selected-summary
    f_chip = F(FONT_UI, 26)

    def section_label(text, y, color=CHAMPAGNE):
        spaced = "   ".join(list(text.upper()))
        draw.text((90, y), spaced, font=f_section, fill=color)

    def chip_row(items, y, max_x=sw - 90, start_x=90, chip_h=68, gap_x=18, gap_y=18):
        """Render chips, wrapping. items = [(label, active)]. Returns final y."""
        cx = start_x
        cy = y
        for label, active in items:
            pad_x = 36
            tw = text_w(draw, label, f_chip)
            cw = tw + pad_x * 2
            if cx + cw > max_x:
                cx = start_x
                cy += chip_h + gap_y
            fill = CHAMPAGNE if active else None
            outline_col = CHAMPAGNE if active else (212, 168, 90, 140)
            text_color = WINE_DEEP if active else BLUSH
            draw.rounded_rectangle((cx, cy, cx + cw, cy + chip_h),
                                   radius=chip_h // 2, fill=fill,
                                   outline=CHAMPAGNE, width=2)
            draw.text((cx + pad_x, cy + 18), label, font=f_chip, fill=text_color)
            cx += cw + gap_x
        return cy + chip_h

    # Brass hairline between sections
    def hairline(y):
        draw.rectangle((90, y, sw - 90, y + 1), fill=(212, 168, 90, 90))

    # ---- Section 1: MOOD ----
    sy = 500
    section_label("Mood", sy)
    sy += 50
    mood_chips = [
        ("Romantic", True), ("Cozy", True),
        ("Adventurous", False), ("Lively", False),
    ]
    sy = chip_row(mood_chips, sy) + 60
    hairline(sy)
    sy += 50

    # ---- Section 2: BUDGET ----
    section_label("Budget", sy)
    sy += 60
    # Track
    track_x1, track_x2 = 90, sw - 90
    track_y = sy + 14
    draw.rounded_rectangle((track_x1, track_y, track_x2, track_y + 10),
                           radius=5, fill=(232, 200, 184, 70))
    fill_to = track_x1 + int((track_x2 - track_x1) * 0.55)
    draw.rounded_rectangle((track_x1, track_y, fill_to, track_y + 10),
                           radius=5, fill=CHAMPAGNE)
    knob_r = 22
    draw.ellipse((fill_to - knob_r, track_y - knob_r + 5,
                  fill_to + knob_r, track_y + knob_r + 5),
                 fill=BONE, outline=CHAMPAGNE, width=3)
    # Tick labels
    f_tick = F(FONT_UI_LIGHT, 22)
    draw.text((track_x1, track_y + 40), "$", font=f_tick, fill=BLUSH)
    draw.text((track_x1 + (track_x2 - track_x1) // 3 - 10, track_y + 40), "$$", font=f_tick, fill=CHAMPAGNE)
    draw.text((track_x1 + 2 * (track_x2 - track_x1) // 3 - 18, track_y + 40), "$$$", font=f_tick, fill=BLUSH)
    draw.text((track_x2 - 40, track_y + 40), "$$$$", font=f_tick, fill=BLUSH)
    sy = track_y + 100
    hairline(sy)
    sy += 50

    # ---- Section 3: ALLERGIES ----
    section_label("Allergies & Dietary", sy)
    sy += 50
    allergy_chips = [
        ("Nuts", True), ("Dairy", False),
        ("Shellfish", True), ("Gluten", False),
        ("Vegetarian", False),
    ]
    sy = chip_row(allergy_chips, sy) + 60
    hairline(sy)
    sy += 50

    # ---- Section 4: INTERESTS ----
    section_label("Interests", sy)
    sy += 50
    interest_chips = [
        ("Foodie", True), ("Live Music", True),
        ("Art", False), ("Outdoors", True),
        ("Nightlife", False),
    ]
    sy = chip_row(interest_chips, sy) + 40

    # ---- Bottom CTA ----
    btn_y = sh - 260
    btn_h = 120
    draw.rounded_rectangle((90, btn_y, sw - 90, btn_y + btn_h),
                           radius=60, fill=CHAMPAGNE)
    f_btn = F(FONT_UI_BOLD, 40)
    btxt = "Continue"
    bw = text_w(draw, btxt, f_btn)
    draw.text(((sw - bw) // 2, btn_y + 34), btxt, font=f_btn, fill=WINE_DEEP)

    home_indicator(draw, 0, sh - 30, sw)


def screen_magic(canvas, draw, args):
    """Screen 3 — AI generating / wishes granted"""
    sw, sh = canvas.size
    g = vertical_gradient(sw, sh, (90, 20, 22), (40, 8, 10))
    canvas.paste(g, (0, 0))
    glow = radial_glow(sw, sh, (sw // 2, sh // 2), 700, CHAMPAGNE, 0.35)
    canvas.paste(glow, (0, 0), glow)

    status_bar(draw, 0, 50, sw)

    # Sparkle / orb in center
    cx, cy = sw // 2, sh // 2 - 200
    for r, alpha in [(260, 30), (200, 60), (140, 100), (90, 180), (50, 255)]:
        ov = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
        od = ImageDraw.Draw(ov)
        od.ellipse((cx - r, cy - r, cx + r, cy + r),
                   fill=(232, 201, 136, alpha))
        canvas.paste(ov, (0, 0), ov)

    # Sparkle accents
    for ax, ay, sr in [(cx - 280, cy - 220, 18),
                       (cx + 290, cy - 80, 24),
                       (cx - 180, cy + 240, 20),
                       (cx + 240, cy + 200, 16)]:
        for i in range(4):
            angle = i * 90
            rr = sr * (1.4 if i % 2 == 0 else 1.0)
            ex = ax + rr * math.cos(math.radians(angle))
            ey = ay + rr * math.sin(math.radians(angle))
            draw.line((ax, ay, ex, ey), fill=CHAMPAGNE_SOFT, width=3)

    # Caption below
    f_eye = F(FONT_UI_LIGHT, 26)
    cap_y = cy + 380
    eyebrow = "G R A N T I N G   Y O U R   W I S H"
    ew = text_w(draw, eyebrow, f_eye)
    draw.text(((sw - ew) // 2, cap_y), eyebrow, font=f_eye, fill=CHAMPAGNE)

    f_h = F(FONT_DISPLAY_IT, 90)
    head = "Curating the night…"
    hw = text_w(draw, head, f_h)
    draw.text(((sw - hw) // 2, cap_y + 70), head, font=f_h, fill=BONE)

    # Progress dots
    dot_y = cap_y + 280
    for i in range(3):
        col = CHAMPAGNE if i < 2 else (212, 168, 90, 100)
        draw.ellipse((sw // 2 - 60 + i * 50 - 10,
                      dot_y - 10,
                      sw // 2 - 60 + i * 50 + 10,
                      dot_y + 10),
                     fill=col)

    # Three line items appearing
    items = [
        ("✓", "Found a quiet Italian table at 7"),
        ("✓", "Mapped the gallery walk after"),
        ("◦", "Reserving the gelato stop…"),
    ]
    iy = dot_y + 130
    f_item = F(FONT_UI_REG, 34)
    f_check = F(FONT_UI_BOLD, 40)
    for mark, text in items:
        mark_color = CHAMPAGNE if mark == "✓" else BLUSH
        draw.text((130, iy), mark, font=f_check, fill=mark_color)
        draw.text((200, iy + 5), text, font=f_item, fill=BONE)
        iy += 90

    home_indicator(draw, 0, sh - 30, sw)


def screen_itinerary(canvas, draw, args):
    """Screen 4 — The itinerary"""
    sw, sh = canvas.size
    g = vertical_gradient(sw, sh, (78, 16, 18), (40, 8, 10))
    canvas.paste(g, (0, 0))

    status_bar(draw, 0, 50, sw)

    # Title block
    f_eye = F(FONT_UI_LIGHT, 24)
    draw.text((90, 230), "S A T U R D A Y   •   M E T U C H E N", font=f_eye, fill=CHAMPAGNE)

    f_h = F(FONT_DISPLAY_IT, 80)
    draw.text((90, 280), "Your night,", font=f_h, fill=BONE)
    draw.text((90, 370), "in three acts.", font=f_h, fill=BONE)

    # Three stop cards
    stops = [
        ("01", "7:00", "Trattoria Solare",  "A slow Italian dinner. Tucked-away table.", "Italian • $$"),
        ("02", "8:45", "Studio One Gallery", "A late opening — photography, free pours.", "Gallery • Free"),
        ("03", "9:30", "Gelato Sole",        "Two scoops. Pistachio and a cherry swirl.",  "Dessert • $"),
    ]

    cy = 590
    card_h = 380
    pad = 70
    for num, time, name, blurb, meta in stops:
        # Card
        overlay = Image.new("RGBA", (sw - pad * 2, card_h - 40), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.rounded_rectangle((0, 0, sw - pad * 2, card_h - 40), radius=32,
                             fill=(212, 168, 90, 22),
                             outline=(212, 168, 90, 110), width=2)
        canvas.paste(overlay, (pad, cy), overlay)

        # Num badge
        f_num = F(FONT_DISPLAY_IT, 50)
        draw.text((pad + 40, cy + 30), num, font=f_num, fill=CHAMPAGNE)

        # Time
        f_time = F(FONT_UI, 32)
        tw = text_w(draw, time, f_time)
        draw.text((sw - pad - 40 - tw, cy + 42), time, font=f_time, fill=BLUSH)

        # Name
        f_name = F(FONT_DISPLAY, 54)
        draw.text((pad + 40, cy + 110), name, font=f_name, fill=BONE)

        # Blurb
        f_blurb = F(FONT_DISPLAY_IT, 32)
        draw.text((pad + 40, cy + 180), blurb, font=f_blurb, fill=BLUSH)

        # Meta
        f_meta = F(FONT_UI_LIGHT, 26)
        draw.text((pad + 40, cy + 240), meta, font=f_meta, fill=CHAMPAGNE)

        cy += card_h - 40 + 30

    home_indicator(draw, 0, sh - 30, sw)


def screen_share(canvas, draw, args):
    """Screen 5 — Share / send"""
    sw, sh = canvas.size
    g = vertical_gradient(sw, sh, (88, 18, 20), (45, 10, 12))
    canvas.paste(g, (0, 0))
    glow = radial_glow(sw, sh, (sw // 2, sh // 2 - 100), 500, CHAMPAGNE, 0.22)
    canvas.paste(glow, (0, 0), glow)

    status_bar(draw, 0, 50, sw)

    # Envelope illustration center
    ex_w, ex_h = 520, 360
    ex = (sw - ex_w) // 2
    ey = 380
    # envelope body
    draw.rounded_rectangle((ex, ey, ex + ex_w, ey + ex_h),
                           radius=24, fill=CHAMPAGNE)
    # flap
    flap_pts = [(ex, ey), (ex + ex_w // 2, ey + 180), (ex + ex_w, ey)]
    draw.polygon(flap_pts, fill=(180, 134, 70))
    # heart wax seal
    seal_cx, seal_cy = ex + ex_w // 2, ey + 160
    draw.ellipse((seal_cx - 60, seal_cy - 60, seal_cx, seal_cy),
                 fill=WINE_HIGH)
    draw.ellipse((seal_cx, seal_cy - 60, seal_cx + 60, seal_cy),
                 fill=WINE_HIGH)
    draw.polygon([(seal_cx - 60, seal_cy - 30),
                  (seal_cx + 60, seal_cy - 30),
                  (seal_cx, seal_cy + 60)], fill=WINE_HIGH)

    # Eyebrow & headline
    f_eye = F(FONT_UI_LIGHT, 26)
    e = "S H A R E D   W I T H   J O R D A N"
    ew = text_w(draw, e, f_eye)
    draw.text(((sw - ew) // 2, ey + ex_h + 80), e, font=f_eye, fill=CHAMPAGNE)

    f_h = F(FONT_DISPLAY_IT, 80)
    h_lines = ["Sent.", "Saturday's locked."]
    yy = ey + ex_h + 140
    for line in h_lines:
        lw = text_w(draw, line, f_h)
        draw.text(((sw - lw) // 2, yy), line, font=f_h, fill=BONE)
        yy += 95

    # Two action buttons
    btn1_y = yy + 90
    btn_pad = 90
    # Primary
    draw.rounded_rectangle((btn_pad, btn1_y, sw - btn_pad, btn1_y + 120),
                           radius=60, fill=CHAMPAGNE)
    f_btn = F(FONT_UI_BOLD, 40)
    bt1 = "Open the Itinerary"
    bw = text_w(draw, bt1, f_btn)
    draw.text(((sw - bw) // 2, btn1_y + 38), bt1, font=f_btn, fill=WINE_DEEP)

    # Secondary
    btn2_y = btn1_y + 150
    draw.rounded_rectangle((btn_pad, btn2_y, sw - btn_pad, btn2_y + 120),
                           radius=60, outline=CHAMPAGNE, width=3)
    bt2 = "Send again later"
    bw = text_w(draw, bt2, f_btn)
    draw.text(((sw - bw) // 2, btn2_y + 38), bt2, font=f_btn, fill=CHAMPAGNE)

    home_indicator(draw, 0, sh - 30, sw)


def screen_library(canvas, draw, args):
    """Screen 6 — Library of date ideas"""
    sw, sh = canvas.size
    g = vertical_gradient(sw, sh, (90, 20, 22), (43, 9, 11))
    canvas.paste(g, (0, 0))

    status_bar(draw, 0, 50, sw)

    f_eye = F(FONT_UI_LIGHT, 26)
    draw.text((90, 230), "Y O U R   L I B R A R Y", font=f_eye, fill=CHAMPAGNE)

    f_h = F(FONT_DISPLAY_IT, 80)
    draw.text((90, 280), "12 nights,", font=f_h, fill=BONE)
    draw.text((90, 370), "ready when you are.", font=f_h, fill=BONE)

    # Grid of tiles
    tiles = [
        ("Pasta + Gelato",      "Metuchen", BLUSH),
        ("Rooftop Jazz",        "Hoboken",  CHAMPAGNE_SOFT),
        ("Sunset & Sushi",      "JC",       BLUSH),
        ("Wine + Watercolors",  "Manhattan",CHAMPAGNE_SOFT),
        ("Bookstore Crawl",     "Brooklyn", BLUSH),
        ("Dim Sum Sunday",      "Flushing", CHAMPAGNE_SOFT),
    ]
    cols = 2
    cw = (sw - 90 * 2 - 40) // cols
    ch = 360
    sx = 90
    sy = 580
    for i, (name, place, accent) in enumerate(tiles):
        r = i // cols
        c = i % cols
        x = sx + c * (cw + 40)
        y = sy + r * (ch + 40)
        overlay = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        od.rounded_rectangle((0, 0, cw, ch), radius=32,
                             fill=(212, 168, 90, 22),
                             outline=(212, 168, 90, 110), width=2)
        canvas.paste(overlay, (x, y), overlay)

        # Decorative dot
        draw.ellipse((x + 30, y + 30, x + 70, y + 70), fill=accent)

        # Title
        f_n = F(FONT_DISPLAY, 42)
        # word-wrap name
        lines = wrap_lines(draw, name, f_n, cw - 60)
        ly = y + 110
        for ln in lines:
            draw.text((x + 30, ly), ln, font=f_n, fill=BONE)
            ly += 56

        # Place
        f_p = F(FONT_UI_LIGHT, 28)
        draw.text((x + 30, y + ch - 70), place, font=f_p, fill=CHAMPAGNE)

    home_indicator(draw, 0, sh - 30, sw)


# ---------- Composer ----------
def compose_screenshot(headline, subtitle, screen_renderer, filename, headline_size=120):
    img = Image.new("RGB", (W, H), WINE)

    # Background: deep wine with brass radial glow at top
    bg = vertical_gradient(W, H, (61, 11, 13), (32, 7, 9))
    img.paste(bg, (0, 0))

    # Brass glow upper-left
    glow1 = radial_glow(W, H, (200, 350), 700, CHAMPAGNE, 0.22)
    img.paste(glow1, (0, 0), glow1)
    # Subtler glow lower-right
    glow2 = radial_glow(W, H, (W - 200, H - 600), 800, BRASS, 0.12)
    img.paste(glow2, (0, 0), glow2)

    draw = ImageDraw.Draw(img)

    # Eyebrow at very top
    f_eye = F(FONT_UI_LIGHT, 30)
    eyebrow = "Y O U R   D A T E   G E N I E"
    ew = text_w(draw, eyebrow, f_eye)
    draw.text(((W - ew) // 2, 160), eyebrow, font=f_eye, fill=CHAMPAGNE)

    # Headline — display serif, italic, bone
    f_head = F(FONT_DISPLAY_IT, headline_size)
    head_lines = wrap_lines(draw, headline, f_head, W - 160)
    hy = 240
    for line in head_lines:
        lw = text_w(draw, line, f_head)
        draw.text(((W - lw) // 2, hy), line, font=f_head, fill=BONE)
        hy += int(headline_size * 1.15)

    # Subtitle — UI light, blush
    f_sub = F(FONT_UI_LIGHT, 42)
    sub_lines = wrap_lines(draw, subtitle, f_sub, W - 240)
    sy = hy + 30
    for line in sub_lines:
        lw = text_w(draw, line, f_sub)
        draw.text(((W - lw) // 2, sy), line, font=f_sub, fill=BLUSH)
        sy += 60

    # Brass hairline divider
    div_y = sy + 80
    draw.rectangle(((W - 120) // 2, div_y, (W + 120) // 2, div_y + 2), fill=CHAMPAGNE)

    # Device frame begins below header block
    phone_top = div_y + 100
    draw_phone_frame(img, phone_top, scale=1.0, screen_renderer=screen_renderer)

    # Ensure no alpha
    final = img.convert("RGB")
    final.save(filename, "PNG", optimize=True)
    return filename


# ---------- Run ----------
OUT_DIR = "/sessions/serene-practical-lovelace/mnt/yourdategenie-main/app-store/screenshots/iphone-6.9"
os.makedirs(OUT_DIR, exist_ok=True)

screens = [
    ("01_plan_tonight.png",   "Plan tonight's date.",          "Your night, granted in seconds.",                  screen_home,       120),
    ("02_built_around_you.png","Built around you two.",        "Mood, budget, allergies, interests — we plan around all of it.", screen_setup,  118),
    ("03_wishes_granted.png", "Wishes granted.",                "A tailored itinerary in seconds.",                 screen_magic,      130),
    ("04_three_acts.png",     "Pasta. Art. Late-night gelato.", "Every detail mapped, beat by beat.",               screen_itinerary, 100),
    ("05_send_in_one_tap.png","Send it in one tap.",            "Share the plan, lock the reservation, show up.",   screen_share,     118),
    ("06_never_run_out.png",  "Never run out of date ideas.",   "Your personal genie, in your pocket.",             screen_library,   108),
]

print(f"Writing screenshots to: {OUT_DIR}")
for fname, head, sub, renderer, size in screens:
    path = os.path.join(OUT_DIR, fname)
    compose_screenshot(head, sub, renderer, path, headline_size=size)
    sz = os.path.getsize(path)
    print(f"  ✓ {fname}  ({sz // 1024} KB)")

print("\nDone.")
