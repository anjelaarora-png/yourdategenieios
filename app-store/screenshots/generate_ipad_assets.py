"""
iPad 13" App Store assets — 2064×2758 screenshots + optional how-to cards.
Run capture_ipad_screenshots.sh first for fresh iPad Pro 13" captures.
"""

import os
import sys

# Reuse iPhone generator helpers
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import generate_screenshots as gen
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.abspath(__file__))
CAPTURES_DIR = os.path.join(ROOT, "..", "..", "_ios_screenshots", "ipad")
OUT_DIR = os.path.join(ROOT, "ipad-13")
HOWTO_DIR = os.path.join(ROOT, "ipad-how-to-use")
EXTRAS_DIR = os.path.join(OUT_DIR, "extras")

# iPad 13" App Store screenshot spec
gen.W = 2100
gen.H = 2800
gen.EXPORT_W = 2064
gen.EXPORT_H = 2752

SX = gen.W / 1320
SY = gen.H / 2868


def make_ipad_capture(name):
    path = os.path.join(CAPTURES_DIR, name)
    if not os.path.isfile(path):
        raise FileNotFoundError(f"Missing iPad capture: {path}")

    def render(canvas, draw, args):
        sw, sh = canvas.size
        real = Image.open(path).convert("RGB")
        rw, rh = real.size
        target_aspect = sw / sh
        src_aspect = rw / rh
        if src_aspect > target_aspect:
            new_w = int(rh * target_aspect)
            left = (rw - new_w) // 2
            real = real.crop((left, 0, left + new_w, rh))
        else:
            new_h = int(rw / target_aspect)
            top = (rh - new_h) // 2
            real = real.crop((0, top, rw, top + new_h))
        real = real.resize((sw, sh), Image.LANCZOS)
        canvas.paste(real, (0, 0))

    return render


def draw_ipad_screen(img, top_y, screen_renderer):
    """iPad screen inset (no phone bezel — full tablet UI)."""
    pad = int(80 * SX)
    frame_w = gen.W - pad * 2
    frame_h = int(gen.H - top_y - pad * 0.6)
    fx = pad
    fy = top_y

    sw, sh = frame_w, frame_h
    screen = Image.new("RGB", (sw, sh), gen.WINE)
    sdraw = ImageDraw.Draw(screen)
    if screen_renderer:
        screen_renderer(screen, sdraw, {})

    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=int(36 * SX), fill=255)
    img.paste(screen, (fx, fy), mask)

    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(
        (fx - 2, fy - 2, fx + sw + 2, fy + sh + 2),
        radius=int(38 * SX),
        outline=(180, 134, 70),
        width=3,
    )
    return fy + sh


def compose_ipad_screenshot(headline, subtitle, capture_name, filename, headline_size=120):
    img = Image.new("RGB", (gen.W, gen.H), gen.WINE)
    bg = gen.vertical_gradient(gen.W, gen.H, (61, 11, 13), (32, 7, 9))
    img.paste(bg, (0, 0))
    glow = gen.radial_glow(gen.W, gen.H, (gen.W // 2, int(300 * SY)), int(700 * SX), gen.CHAMPAGNE, 0.18)
    img.paste(glow, (0, 0), glow)

    draw = ImageDraw.Draw(img)
    hs = int(headline_size * SX * 0.95)

    f_eye = gen.F(gen.FONT_UI_LIGHT, int(28 * SX))
    eyebrow = "Y O U R   D A T E   G E N I E"
    ew = gen.text_w(draw, eyebrow, f_eye)
    draw.text(((gen.W - ew) // 2, int(120 * SY)), eyebrow, font=f_eye, fill=gen.CHAMPAGNE)

    f_head = gen.F(gen.FONT_DISPLAY_IT, hs)
    head_lines = gen.wrap_lines(draw, headline, f_head, gen.W - int(200 * SX))
    hy = int(190 * SY)
    for line in head_lines:
        lw = gen.text_w(draw, line, f_head)
        draw.text(((gen.W - lw) // 2, hy), line, font=f_head, fill=gen.BONE)
        hy += int(hs * 1.12)

    f_sub = gen.F(gen.FONT_UI_LIGHT, int(38 * SX))
    sub_lines = gen.wrap_lines(draw, subtitle, f_sub, gen.W - int(280 * SX))
    sy = hy + int(24 * SY)
    for line in sub_lines:
        lw = gen.text_w(draw, line, f_sub)
        draw.text(((gen.W - lw) // 2, sy), line, font=f_sub, fill=gen.BLUSH)
        sy += int(52 * SY)

    div_y = sy + int(50 * SY)
    draw.rectangle(
        ((gen.W - int(140 * SX)) // 2, div_y, (gen.W + int(140 * SX)) // 2, div_y + 2),
        fill=gen.CHAMPAGNE,
    )

    draw_ipad_screen(img, div_y + int(70 * SY), make_ipad_capture(capture_name))
    gen.export_png(img, filename)
    return filename


def configure_output_dirs():
    global OUT_DIR, HOWTO_DIR, EXTRAS_DIR
    bundle = os.environ.get("YDG_SCREENSHOT_BUNDLE")
    if not bundle:
        return
    OUT_DIR = os.path.join(bundle, "ipad-13")
    HOWTO_DIR = os.path.join(bundle, "ipad-how-to-use")
    EXTRAS_DIR = os.path.join(OUT_DIR, "extras")


def main():
    configure_output_dirs()
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(HOWTO_DIR, exist_ok=True)
    os.makedirs(EXTRAS_DIR, exist_ok=True)

    screens = [
        ("01_plan_tonight.png", "Plan tonight's date.", "Your night, curated before you ask.", "cap_02_home_plan.png", 118),
        ("02_built_around_you.png", "Built around you two.", "Mood, budget, allergies, interests — we plan around all of it.", "cap_03_questionnaire.png", 115),
        ("03_wishes_granted.png", "Wishes granted.", "A tailored itinerary in seconds.", "cap_04_plan_options.png", 125),
        ("04_three_acts.png", "Pasta. Art. Late-night gelato.", "Every detail mapped, beat by beat.", "cap_05_plan_detail.png", 98),
        ("05_send_in_one_tap.png", "Send it in one tap.", "Share the plan, lock the reservation, show up.", "cap_06_partner_share.png", 112),
        ("06_never_run_out.png", "Never run out of date ideas.", "Your personal genie, in your pocket.", "cap_07_dates.png", 105),
        ("07_one_tap_away.png", "One tap away.", "Your finished date plan starts here.", "cap_01_home.png", 112),
        ("08_genie_at_work.png", "The Genie is thinking.", "Real venues. Verified. Ready in seconds.", "cap_09_generating.png", 115),
        ("09_every_romantic_detail.png", "Every romantic detail.", "Love notes, gifts, and playlists — built into every plan.", "cap_08_convo.png", 102),
        ("10_plan_together.png", "Plan together.", "Three curated options. Pick your perfect match.", "cap_04b_plan_options.png", 98),
    ]

    extras = [
        ("11_memory_gallery.png", "Every date, preserved.", "Polaroid memories that grow with every night out.", "cap_10_memories.png", 108),
        ("12_playlist.png", "Soundtrack the night.", "Curated playlists matched to your date vibe.", "cap_11_playlist.png", 112),
        ("13_gift_finder.png", "Gifts that actually fit.", "Thoughtful picks tuned to your person and your plan.", "cap_12_gift_finder.png", 105),
        ("14_see_every_stop.png", "See every stop.", "Venues, timing, and directions — your whole night in one scroll.", "cap_05_plan_detail.png", 110),
    ]

    print(f"Writing iPad screenshots to: {OUT_DIR}")
    for fname, head, sub, cap, size in screens:
        path = os.path.join(OUT_DIR, fname)
        compose_ipad_screenshot(head, sub, cap, path, headline_size=size)
        im = Image.open(path)
        print(f"  ✓ {fname}  {im.size[0]}×{im.size[1]}")

    print(f"\nWriting iPad feature extras to: {EXTRAS_DIR}")
    for fname, head, sub, cap, size in extras:
        path = os.path.join(EXTRAS_DIR, fname)
        compose_ipad_screenshot(head, sub, cap, path, headline_size=size)
        im = Image.open(path)
        print(f"  ✓ extras/{fname}  {im.size[0]}×{im.size[1]}")

    print(f"\nExport size: {gen.EXPORT_W}×{gen.EXPORT_H} px (iPad 13\" App Store Connect)")


if __name__ == "__main__":
    main()
