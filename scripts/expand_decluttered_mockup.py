#!/usr/bin/env python3
"""Expand YDG_decluttered_mockup.html with all shipped iOS screens."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "YDG_decluttered_mockup.html"


def chips(items, on=None):
    on = on or set()
    parts = []
    for label in items:
        cls = "chip on" if label in on else "chip"
        parts.append(f'<span class="{cls}">{label}</span>')
    return '<div class="chips" style="gap:6px;">' + "".join(parts) + "</div>"


def frame(cap, body):
    return (
        f'<div class="frame"><div class="cap">{cap}</div>'
        f'<div class="phone"><div class="screen">{body}</div></div></div>'
    )


def stat(l, c="", r=""):
    return f'<div class="stat"><span>{l}</span><span>{c}</span><span>{r}</span></div>'


def cta(t, mb="13px"):
    return f'<div class="cta" style="margin-bottom:{mb};">{t}</div>'


def tabbar(active="Home"):
    tabs = [("Home", "⌂"), ("Dates", "♥"), ("Notes", "✉"), ("You", "◔")]
    out = ['<div class="tabbar">']
    for name, icon in tabs:
        cls = "tab on" if name == active else "tab"
        out.append(f'<div class="{cls}"><div class="ic">{icon}</div>{name}</div>')
    out.append("</div>")
    return "".join(out)


ACT0_EXTRA = (
    frame("<b>00a · Intro 1/4</b>", stat("←", "1 of 4") + '<div class="h-display" style="font-size:21px;margin:40px 0 10px;">Date nights<br><span style="color:var(--gold)">shouldn\'t feel like work.</span></div><div class="muted note">You\'re busy. Connection matters.</div>' + cta("Next"))
    + frame("<b>00a2 · Intro 3/4</b>", stat("←", "3 of 4") + '<div class="h-display" style="font-size:21px;margin:40px 0 10px;">Tell us once.<br><span style="color:var(--gold)">We plan forever.</span></div>' + cta("Next"))
    + frame("<b>00a3 · Intro 4/4</b>", stat("←", "4 of 4") + '<div class="h-display" style="font-size:21px;margin:40px 0 10px;">One tap to<br><span style="color:var(--gold)">lock it in.</span></div>' + cta("Get started"))
    + frame("<b>00c2 · Sign up</b>", '<div class="h-display center" style="font-size:20px;margin:16px 0 8px;">Create Account</div><div class="card" style="margin-bottom:6px;padding:9px;"><span class="dim note">First name · Last name · Email · Password</span></div>' + cta("Create Account"))
    + frame("<b>00c3 · Forgot password</b>", stat("←", "Reset", "") + '<div class="h-display" style="font-size:19px;margin:24px 0 8px;">Reset password</div><div class="card" style="padding:10px;margin-bottom:14px;"><span class="dim note">Email</span></div>' + cta("Send reset link"))
)

ACT1_EXTRA = (
    frame("<b>07b · Step 6 · Extras</b>", stat("←", "6 of 6") + '<div class="label" style="margin:12px 0 6px;">Relationship stage</div>' + chips(["New", "Dating", "Established", "Rekindling"], {"Established"}) + '<div class="card" style="display:flex;justify-content:space-between;margin:12px 0;"><span class="cream note">Gift suggestions</span><div class="toggle"></div></div><div class="card" style="display:flex;justify-content:space-between;margin-bottom:12px;"><span class="cream note">Conversation starters</span><div class="toggle"></div></div>' + cta("Continue"))
    + frame("<b>07c · Finish later</b>", '<div class="pill" style="margin:12px 0;">Pick up where you left off · Step 4 of 6</div><div class="center" style="margin-bottom:auto;"><span class="link">Finish later</span></div>' + cta("Continue setup"))
    + frame("<b>08a · Home tutorial 1/3</b>", '<div style="position:absolute;inset:0;background:rgba(0,0,0,.65);display:flex;flex-direction:column;justify-content:flex-end;"><div style="background:var(--bg);border-radius:20px 20px 0 0;padding:20px;"><div class="h-display center" style="font-size:18px;margin-bottom:8px;">Approve tonight\'s plan</div><div class="muted note center" style="margin-bottom:14px;">Home shows a finished plan — tap Lock it in.</div>' + cta("Next", "8px") + '<div class="center"><span class="link">Skip intro</span></div></div></div>')
    + frame("<b>08b · Home tutorial 2/3</b>", '<div style="position:absolute;inset:0;background:rgba(0,0,0,.65);display:flex;flex-direction:column;justify-content:flex-end;"><div style="background:var(--bg);border-radius:20px 20px 0 0;padding:20px;"><div class="h-display center" style="font-size:18px;">Your dates live in Dates</div>' + cta("Next", "8px") + '</div></div>')
    + frame("<b>08c · Home tutorial 3/3</b>", '<div style="position:absolute;inset:0;background:rgba(0,0,0,.65);display:flex;flex-direction:column;justify-content:flex-end;"><div style="background:var(--bg);border-radius:20px 20px 0 0;padding:20px;"><div class="h-display center" style="font-size:18px;">Notes & You — re-homed</div>' + cta("Got it!", "8px") + '</div></div>')
)

ACT1B = (
    '  <h2 id="act1b">Act 1b · Date planning questionnaire</h2>\n  <div class="ssub">When user taps I\'ll plan it — real QuestionnaireOptions from iOS.</div>\n  <div class="row">\n'
    + frame("<b>DP1 · Date type</b>", stat("✕", "Plan", "") + '<div class="label" style="margin:12px 0 6px;">Date type</div>' + chips(["First Date", "Anniversary", "Casual", "Romantic", "Adventure"], {"Romantic"}) + '<div class="label" style="margin:12px 0 6px;">Occasion</div>' + chips(["Just Because", "Birthday", "Celebration"], {"Just Because"}) + cta("Continue"))
    + frame("<b>DP2 · When & energy</b>", stat("←", "2/6", "") + '<div class="card" style="padding:10px;margin:12px 0;"><span class="cream note">Sat Jun 14 · 7 PM</span></div>' + chips(["Chill", "Balanced", "Active", "High Energy"], {"Balanced"}) + cta("Continue"))
    + frame("<b>DP3 · Location</b>", stat("←", "3/6", "") + '<div class="card" style="padding:10px;margin:12px 0;"><span class="cream note">📍 Metuchen, NJ</span></div>' + chips(["Walkable", "Neighborhood", "City-wide", "Metro"], {"Neighborhood"}) + cta("Continue"))
    + frame("<b>DP4 · Food</b>", stat("←", "4/6", "") + chips(["Italian", "Japanese", "Mexican", "Indian"], {"Italian"}) + '<div class="label" style="margin:12px 0 6px;">Dietary</div>' + chips(["Vegetarian", "Vegan", "Gluten-free", "None"], {"None"}) + cta("Continue"))
    + frame("<b>DP5 · Dealbreakers</b>", stat("←", "5/6", "") + chips(["Loud", "Crowds", "Heights", "Late nights"], {"Crowds"}) + cta("Continue"))
    + frame("<b>DP6 · Budget</b>", stat("←", "6/6", "") + chips(["$", "$$", "$$$", "$$$$"], {"$$"}) + cta("✦ Create the night"))
    + "\n  </div>\n"
)

ACT2_EXTRA = (
    frame("<b>09a · Free plan counter</b>", stat("genie", "", "🔔") + '<div class="pill" style="margin:10px 0;">2 of 3 free plans left</div><div class="card"><div class="cream note">Pasta · gallery</div></div>' + cta("Lock it in") + tabbar("Home"))
    + frame("<b>11f · Magical loading</b>", '<div style="text-align:center;flex:1;display:flex;flex-direction:column;justify-content:center;"><div style="font-size:36px;color:var(--gold);margin-bottom:12px;">✦</div><div class="h-display">Planning your night…</div></div>')
    + frame("<b>12 · Plan result</b> · all quick actions ⭐", stat("Close", "Plan", "Share") + '<div class="chips" style="margin:12px 0;"><span class="pill">Route</span><span class="pill">Calendar</span><span class="pill">Playlist</span><span class="pill">Gifts</span></div><div class="chips" style="margin-bottom:auto;"><span class="pill">Reserve</span><span class="pill">Photo</span><span class="pill">Share</span><span class="pill">Delete</span></div>' + cta("Lock it in"))
    + frame("<b>12a · Reservation</b>", stat("✕", "Reserve", "") + '<div class="card" style="margin:12px 0 8px;display:flex;justify-content:space-between;"><span class="cream note">OpenTable</span><span class="cta-sm">Book</span></div><div class="card" style="display:flex;justify-content:space-between;"><span class="cream note">Resy</span><span class="ghost">Book</span></div><div class="card" style="margin-top:8px;display:flex;justify-content:space-between;"><span class="cream note">Call</span><span class="ghost">📞</span></div>')
    + frame("<b>12b · Regenerate</b>", stat("✕", "Options", "") + '<div class="card" style="margin:12px 0;border:1px solid var(--gold);"><div class="cream note">Plan A</div></div><div class="center" style="margin-bottom:auto;"><span class="link">🔄 Regenerate</span></div>' + cta("View plan"))
    + frame("<b>12c · Paywall 3rd plan</b>", stat("✕", "", "") + '<div class="h-display center" style="font-size:18px;margin:20px 0;">3 free plans used</div><div class="pricecard" style="margin-bottom:8px;"><div><div class="cream note">Yearly</div><div class="dim note">$99.99/yr</div></div><span class="cta-sm">Trial</span></div><div class="pricecard alt"><div><div class="cream note">Monthly</div><div class="dim note">$14.99/mo</div></div></div>')
    + frame("<b>16a · Undo</b>", '<div style="background:var(--surface2);padding:10px;border-radius:10px;margin:14px 0;display:flex;justify-content:space-between;"><span class="cream note">Plan saved</span><span class="link">Undo</span></div>' + tabbar("Home"))
    + frame("<b>12d · Move to past</b>", cta("Move to Past Dates"))
)

ACT9 = (
    '  <h2 id="act9">Act 9 · Partner planning (optional)</h2>\n  <div class="row">\n'
    + frame("<b>P1 · Hub</b>", '<div class="seg" style="margin:12px 0;"><span style="color:var(--gold);border-bottom:2px solid var(--gold);padding-bottom:6px;margin-right:12px;">Invite</span><span style="color:var(--dim);margin-right:12px;">Pending</span><span style="color:var(--dim);">Past</span></div><div class="link" style="margin-bottom:auto;">Continue solo</div>' + cta("New partner plan"))
    + frame("<b>P2–4 · Invite steps</b>", stat("", "Step 2/3", "") + '<div class="card" style="padding:10px;margin:12px 0;"><span class="cream note">Maya · Sat 7 PM</span></div>' + cta("Send invite"))
    + frame("<b>P5 · Invited</b>", '<div style="text-align:center;flex:1;display:flex;flex-direction:column;justify-content:center;"><div style="font-size:32px;margin-bottom:12px;">🎉</div><div class="h-display">Invite sent</div></div>' + cta("Done"))
    + frame("<b>P6 · Waiting</b>", '<div class="h-display" style="margin:16px 0;">Waiting for Maya</div><div class="link">Send reminder</div>' + cta("Cancel"))
    + frame("<b>P7 · Join</b>", '<div class="h-display center" style="font-size:19px;margin:24px 0;">John invited you</div>' + cta("Join & rank"))
    + frame("<b>P8 · Generating</b>", '<div style="text-align:center;flex:1;display:flex;flex-direction:column;justify-content:center;"><div class="h-display">Building 3 options…</div></div>')
    + frame("<b>P9 · Block/unlink</b>", '<div class="ghost" style="margin:14px 0;">Unlink partner</div><div class="ghost">Block partner</div><div class="link" style="margin-top:auto;">Report concern</div>')
    + frame("<b>P10 · Report</b>", chips(["Harassment", "Inappropriate", "Spam", "Safety", "Other"], {"Safety"}) + cta("Submit"))
    + "\n  </div>\n"
)

ACT10 = (
    '  <h2 id="act10">Act 10 · Remaining shipped screens</h2>\n  <div class="row">\n'
    + frame("<b>F15 · Sparks gen</b>", chips(["Light", "Deep", "Bold"], {"Deep"}) + cta("Generate deck"))
    + frame("<b>F16 · Saved playlists</b>", stat("←", "Playlists", "") + '<div class="card" style="margin:12px 0;"><div class="cream note">Saturday night · 12 songs</div></div>')
    + frame("<b>F17 · Gift unwrap</b>", '<div style="text-align:center;flex:1;display:flex;flex-direction:column;justify-content:center;"><div style="font-size:40px;">🎁</div><div class="h-display">Tap to unwrap</div></div>')
    + frame("<b>F18 · Memory gallery</b>", '<div class="card" style="margin:12px 0;padding:0;overflow:hidden;"><div class="imgph" style="height:60px;"></div><div style="padding:8px;"><div class="cream note">Gallery night</div></div></div><div class="fab">+</div>' + tabbar("Dates"))
    + frame("<b>F19 · Add memory</b>", stat("Cancel", "Add", "Save") + '<div class="imgph" style="height:70px;border-radius:10px;margin:12px 0;"></div><div class="card" style="padding:10px;"><span class="dim note">Caption…</span></div>' + cta("Save"))
    + frame("<b>F20 · Past Magic</b>", '<div class="card" style="margin:12px 0;"><div class="cream note">Jazz date · May 12</div></div>')
    + frame("<b>F21 · Saved plans</b>", '<div class="card" style="margin:12px 0;"><div class="cream note">Sunset hike · saved</div></div>')
    + frame("<b>F22 · Event detail</b>", '<div class="imgph" style="height:80px;border-radius:10px;margin:12px 0;"></div><div class="h-display" style="font-size:17px;">Wine walk</div>' + cta("Add to plan"))
    + frame("<b>F23 · Explore radius</b>", '<div class="label">Within 15 miles</div><div style="height:4px;background:var(--surface);margin:8px 0 12px;"><div style="width:60%;height:100%;background:var(--gold);"></div></div><div class="card"><div class="cream note">Nonna\'s</div></div>')
    + frame("<b>F24 · Relationship story</b>", '<div class="card" style="margin:14px 0;"><div class="cream note">312 days · 14 dates · 6 memories</div></div>' + tabbar("You"))
    + frame("<b>F25 · Edit account</b>", stat("Cancel", "Account", "Save") + '<div class="card" style="padding:10px;margin:12px 0;"><span class="cream note">John Arora · you@email.com</span></div>')
    + frame("<b>F26 · Subscription</b>", '<div class="pricecard" style="margin:12px 0;"><div><div class="cream note">Annual $99.99</div></div><span class="cta-sm">Trial</span></div><div class="link">Restore purchases</div>')
    + frame("<b>F27 · Partner share</b>", '<div class="card" style="margin:12px 0;"><div class="cream note">Pasta plan</div></div>' + cta("Send to Maya"))
    + frame("<b>F28 · Swap stop</b>", '<div class="card" style="margin:12px 0;border:1px solid var(--gold);"><div class="cream note">Rooftop bar</div></div>' + cta("Use this stop"))
    + "\n  </div>\n"
)

JOURNEY = (
    '  <h2 id="journey">Journey mode</h2>\n  <div style="display:flex;gap:24px;flex-wrap:wrap;align-items:flex-start;">\n'
    '    <div class="phone" style="width:262px;"><div id="journeyScreen" class="screen" style="height:556px;"></div></div>\n'
    '    <div><div id="journeyLabel" style="color:#D6AE54;font-family:\'Playfair Display\',serif;font-size:18px;margin-bottom:8px;">Splash</div>\n'
    '    <div id="journeyStep" style="color:#8a837a;font-size:13px;margin-bottom:16px;">Step 1</div>\n'
    '    <button class="jbtn" id="journeyPrev">← Prev</button> <button class="jbtn" id="journeyNext">Next →</button></div>\n  </div>\n'
)

JS = """
<script>
const journeySteps=[
{label:'Splash',html:'<div style="height:100%;display:flex;flex-direction:column;justify-content:center;align-items:center;text-align:center;"><div style="font-size:30px;color:var(--gold);margin-bottom:16px;">✦</div><div class="h-display">Your Date Genie</div></div>'},
{label:'Auth',html:'<div class="h-display" style="margin:20px 0;">Welcome Back</div><div class="cta" style="margin-top:auto;margin-bottom:13px;">Sign In</div>'},
{label:'Prefs',html:'<div class="h-display" style="margin:20px 0;">Your vibe?</div><div class="chips"><span class="chip on">Romantic</span></div><div class="cta" style="margin-top:auto;margin-bottom:13px;">Continue</div>'},
{label:'Home',html:'<div class="h-display" style="margin:12px 0;">Tonight for you & Maya</div><div class="card"><div class="cream note">Pasta plan</div></div><div class="cta" style="margin-top:auto;margin-bottom:13px;">Lock it in</div>'},
{label:'Locked in',html:'<div style="text-align:center;flex:1;display:flex;flex-direction:column;justify-content:center;"><div style="font-size:36px;">💛</div><div class="h-display">Saturday is set</div></div>'},
{label:'Sign out',html:'<div style="text-align:center;flex:1;display:flex;flex-direction:column;justify-content:center;"><div class="h-display">Sign out?</div><div class="cta" style="background:#8a3030;color:#fff;margin-top:12px;">Sign Out</div></div>'}
];
let ji=0;const js=document.getElementById('journeyScreen'),jl=document.getElementById('journeyLabel'),jst=document.getElementById('journeyStep');
function rj(){const s=journeySteps[ji];js.innerHTML=s.html;jl.textContent=s.label;jst.textContent='Step '+(ji+1)+' of '+journeySteps.length;}
document.getElementById('journeyNext').onclick=()=>{if(ji<journeySteps.length-1){ji++;rj();}};
document.getElementById('journeyPrev').onclick=()=>{if(ji>0){ji--;rj();}};
rj();
</script>
"""


def main():
    text = HTML.read_text(encoding="utf-8")
    text = text.replace("$3.33/mo · best value", "$99.99/yr · best value")
    text = text.replace("$5.99/mo", "$14.99/mo")

    if "act1b" not in text:
        text = text.replace(
            '<button class="jbtn" onclick="document.getElementById(\'act8\').scrollIntoView({behavior:\'smooth\'})">All features</button>',
            '<button class="jbtn" onclick="document.getElementById(\'act1b\').scrollIntoView({behavior:\'smooth\'})">Date questionnaire</button>\n  <button class="jbtn" onclick="document.getElementById(\'act9\').scrollIntoView({behavior:\'smooth\'})">Partner flow</button>\n  <button class="jbtn" onclick="document.getElementById(\'act10\').scrollIntoView({behavior:\'smooth\'})">More screens</button>\n  <button class="jbtn" onclick="document.getElementById(\'journey\').scrollIntoView({behavior:\'smooth\'})">Journey mode</button>\n  <button class="jbtn" onclick="document.getElementById(\'act8\').scrollIntoView({behavior:\'smooth\'})">All features</button>',
        )

    if "00a · Intro 1/4" not in text:
        idx = text.find("  <!-- ============ ACT 1")
        if idx > 0:
            text = text[:idx] + ACT0_EXTRA + text[idx:]

    marker1 = "  <!-- ============ ACT 2"
    if "07b · Step 6" not in text:
        text = text.replace(marker1, ACT1_EXTRA + ACT1B + marker1)

    if "11f · Magical loading" not in text:
        text = text.replace(
            '<div class="frame"><div class="cap"><b>11b · Plan together</b>',
            ACT2_EXTRA + '<div class="frame"><div class="cap"><b>11b · Plan together</b>',
        )

    foot = '  <div class="foot">'
    if 'id="act9"' not in text:
        text = text.replace(foot, ACT9 + ACT10 + JOURNEY + foot)

    if "journeySteps" not in text:
        text = text.replace("</body>", JS + "\n</body>")

    text = text.replace("<b>01 · Splash</b>", "<b>01 · Welcome</b> · splash in Act 0 only")
    text = text.replace("scroll Acts 0 → 8", "scroll Acts 0 → 10 + Journey mode")
    text = text.replace("All current iOS features in Act 8.", "All shipped screens in Acts 8–10.")

    HTML.write_text(text, encoding="utf-8")
    print("Frames:", text.count("<div class=\"frame\">"))


if __name__ == "__main__":
    main()
