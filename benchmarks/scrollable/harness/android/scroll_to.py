"""The scroll-to test on the Cards screen (the benchmark's advanced mode):
where a list lands when told to scroll far, past cards it has never
measured, and whether its content jumps while the finger drags back through
cards it has never drawn.

  ANDROID_SERIAL=<device> python3 scroll_to.py <app> <out-dir> [--drags N] [--chat]

  app  dartnative | kotlin | legendlist | flashlist | flatlist

With --chat, the same test on the Chat screen (the DartNative and Kotlin
apps built for it): its "Scroll" bar button scrolls to the next message of
the apps' chat scroll targets, up the history from where the thread opens:
996, 600, 598, 300 and 0 (the oldest), each asked to rest with its top at
the top of the list. A message is found by its time, which no other
message shares, and its top is read from its sender's name, the bubble's
first line; the first scroll, a few rows from the newest message the
thread opens at, calibrates where that line sits. There is no scroll to
the newest message, since the thread opens there. The drags are 400 px,
as a message can be taller than half the screen; after the last scroll,
which leaves the oldest message at the top, they go back down the thread,
towards the newer messages.

Each app's Cards screen has a "Scroll" bar button that scrolls, animated,
to the next card of the same sequence (the apps' scroll targets), down the
list from where it opens: cards 1, 400, 402, 700 and 950. The test reads
the screen through Android's accessibility tree (`uiautomator dump`), which
every app fills with its own text views:

- Calibration. The first scroll, to card 1, lands among cards every list has
  already measured, so it shows where a card's title "Item #1" sits when
  the card is at the top of the list.

- The scrolls. Then the list is asked to scroll card 400, 402, 700 and 950
  to its top: three far scrolls of hundreds of cards, past cards it has
  never measured, and one short scroll of two cards. After each, the title
  of the target card should sit where card 1's did; the difference is how
  far the list landed from where it was asked to, in pixels. A positive
  difference means the card is lower than asked and the cards before it
  show above it; a negative one means it is higher and its top is cut off.
  A card that stops so low that its title is below the screen is placed
  from its author line, the line above the title, as far above the title
  as on card 1. A target with neither on screen is a miss.

- Jumps while dragging. After the last scroll the test drags the list back
  towards the top, through cards the list may not have drawn, in slow
  drags of a set length that end with the finger held still, so no list
  flings. Every text inside the list moves by the length of the drag; the
  same drag made among measured cards, after the calibration, gives each
  app's own figure for that length (the touch slop takes a few pixels). A
  drag that moves the content by more or less than that is content that
  jumped.

Movements are read from the cards' titles and author lines, the texts
that name one card only, where they sit wholly inside the list before and
after: the bar's title does not move, and a text cut off at the list's
edge reports only its visible part. A drag that leaves no such text on
screen both times is not counted. Each step waits until two dumps in a
row show the same positions. The dumps, a screenshot of each landing and
results.json go to <out-dir>.
"""
import json
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from collections import Counter

TARGETS = [1, 400, 402, 700, 950]
CHAT_TARGETS = [996, 600, 598, 300, 0]
HERE = os.path.dirname(os.path.abspath(__file__))


def app_of(name, screen):
    """The package of one app's screen and the command that starts it. Each
    screen of each app is an app of its own, opened straight on that screen
    (../apps.sh says which)."""
    out = subprocess.check_output(
        ["bash", "-c", '. "$0"; app_id "$1" "$2" && app_activity "$1"',
         os.path.join(HERE, "..", "apps.sh"), name, screen], text=True).split()
    return out[0], ["am", "start", "-W", "-n", f"{out[0]}/{out[1]}"]


BOUNDS = re.compile(r"\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]")
X = 540
DRAG_FROM, DRAG_TO = 900, 1700  # the finger moves down, the content follows it, and the cards above come into view
# The Chat screen's drags are half as long: a message can be taller than
# half the screen, and a drag of 800 px would carry every message's time
# off screen, leaving nothing to compare.
CHAT_DRAG_TO = 1300


def adb(*args, check=True):
    return subprocess.run(["adb", "shell", *args], capture_output=True, text=True, check=check).stdout


def dump():
    """The screen's text views and buttons, [(text, desc, left, top, right,
    bottom)], and the list's own bounds: the largest scrollable view."""
    for _ in range(5):
        out = adb("uiautomator", "dump", "/sdcard/bench_jump.xml", check=False)
        if "dumped" in out:
            xml = adb("cat", "/sdcard/bench_jump.xml")
            nodes, lists = [], []
            for n in ET.fromstring(xml).iter("node"):
                b = tuple(int(v) for v in BOUNDS.fullmatch(n.get("bounds", "")).groups())
                nodes.append((n.get("text", ""), n.get("content-desc", ""), *b))
                if n.get("scrollable") == "true":
                    lists.append(b)
            area = max(lists, key=lambda r: (r[2] - r[0]) * (r[3] - r[1])) if lists else None
            return Screen(nodes, area), xml
        time.sleep(0.5)
    raise RuntimeError("uiautomator could not dump the screen")


class Screen(list):
    """The nodes of one dump, with the list's bounds."""

    def __init__(self, nodes, area):
        super().__init__(nodes)
        self.area = area


# The texts that name one card only: its title and its author line, which
# ends with the card's number. The other texts of a card repeat on other
# cards (the body, the footer, the times), so a text seen in two dumps could
# be two cards.
UNIQUE = re.compile(r"Item #\d+|[A-Z][A-Za-z'. -]* \d+")
# On the Chat screen, a message's time ("91:53 PM"): the thread's clock
# runs past 24 hours, so no two messages share one.
CHAT_UNIQUE = re.compile(r"\d+:\d\d [AP]M")


def tops(screen):
    """Top edge of each card's title and author line that sits wholly inside
    the list, two pixels clear of its edges: the bar's title does not
    scroll, and a text cut off at the list's edge reports only its visible
    part."""
    seen = {}
    for t, _, _, top, _, bottom in screen:
        if UNIQUE.fullmatch(t):
            seen.setdefault(t, []).append((top, bottom))
    area = screen.area
    inside = lambda top, bottom: area is None or (top > area[1] + 2 and bottom < area[3] - 2)
    return {t: v[0][0] for t, v in seen.items() if len(v) == 1 and inside(*v[0])}


def settle(timeout=45.0):
    """Dumps until two in a row show the same text positions."""
    start = time.time()
    time.sleep(1.5)
    prev, xml = dump()
    while True:
        time.sleep(1.0)
        cur, xml = dump()
        if tops(cur) == tops(prev) and tops(cur):
            return cur, xml, time.time() - start
        if time.time() - start > timeout:
            return cur, xml, None
        prev = cur


def tap(desc):
    nodes, _ = dump()
    for _, d, l, t, r, b in nodes:
        if d == desc:
            adb("input", "tap", str((l + r) // 2), str((t + b) // 2))
            return
    raise RuntimeError(f"no {desc} button on screen")


def drag(y0, y1, steps=16):
    """A slow drag from y0 to y1 that ends with the finger held still."""
    cmds = [f"input motionevent DOWN {X} {y0}"]
    for i in range(1, steps + 1):
        cmds.append(f"input motionevent MOVE {X} {y0 + (y1 - y0) * i // steps}")
    cmds += ["sleep 0.4", f"input motionevent MOVE {X} {y1}", "sleep 0.3", f"input motionevent UP {X} {y1}"]
    adb("; ".join(cmds))


def shift(before, after):
    """How far the content moved: the movement most of the texts inside the
    list share, and how many texts were compared."""
    a, b = tops(before), tops(after)
    moves = [b[t] - a[t] for t in a.keys() & b.keys()]
    return (Counter(moves).most_common(1)[0][0], len(moves)) if moves else (None, 0)


def message_top(nodes, message):
    """Top of [message]'s bubble, read from its sender's name: the text
    with that name nearest above the message's time, starting where the
    time starts (both sit at the bubble's left padding)."""
    stamp, sender = message["timestampLabel"], message["senderName"]
    at = [(l, t) for txt, _, l, t, _, _ in nodes if txt == stamp]
    if len(at) != 1:
        return None
    left, top = at[0]
    above = [t for txt, _, l, t, _, b in nodes if txt == sender and abs(l - left) <= 8 and b <= top + 2]
    return max(above) if above else None


def title_top(nodes, card):
    for t, _, _, top, _, _ in nodes:
        if t == f"Item #{card}":
            return top
    return None


def author_top(nodes, card):
    """Top of the card's author line ("Jordan Lee 1"), the line above its
    title."""
    for t, _, _, top, _, _ in nodes:
        if re.fullmatch(rf"[A-Z][A-Za-z'. -]* {card}", t):
            return top
    return None


def first_title(nodes):
    cards = [(top, int(t[6:])) for t, _, _, top, _, _ in nodes if re.fullmatch(r"Item #\d+", t)]
    return min(cards)[1] if cards else None


def main_chat(app, out, drags, button):
    global UNIQUE
    UNIQUE = CHAT_UNIQUE
    messages = json.load(open(os.path.join(HERE, "..", "..", "assets", "chat.json")))
    pkg, launch = app_of(app, "chat")
    os.makedirs(out, exist_ok=True)
    adb("am", "force-stop", pkg)
    time.sleep(1)
    adb(*launch)
    time.sleep(8)
    result = {"app": app, "screen": "chat", "button": button, "targets": CHAT_TARGETS, "landings": [], "drags": []}
    calibration = None
    for n, number in enumerate(CHAT_TARGETS):
        before, _ = dump()
        tap(button)
        nodes, xml, took = settle()
        # A tap made while the app is still starting can be lost; the first
        # jump always moves the list, so a screen that did not change is
        # tapped again, and the output says so.
        for _ in range(3):
            if n > 0 or tops(nodes) != tops(before):
                break
            print("  the first tap did not move the list; tapping again")
            result["first_tap_repeats"] = result.get("first_tap_repeats", 0) + 1
            tap(button)
            nodes, xml, took = settle()
        open(os.path.join(out, f"jump{n}_{number}.xml"), "w").write(xml)
        subprocess.run(f"adb exec-out screencap -p > '{os.path.join(out, f'jump{n}_{number}.png')}'",
                       shell=True, check=True)
        top = message_top(nodes, messages[number])
        if n == 0:
            calibration = top
            if top is None:
                raise RuntimeError(f"the calibration jump did not land on message {number}")
        landing = {
            "message": number,
            "top_px": top,
            "error_px": None if top is None or n == 0 else top - calibration,
            "settled_s": None if took is None else round(took, 1),
        }
        result["landings"].append(landing)
        print(f"  jump to message {number}: top at {top}, error {landing['error_px']}, "
              f"settled in {landing['settled_s']} s")
        if n == 0:
            before = nodes
            drag(DRAG_FROM, CHAT_DRAG_TO)
            after, _, _ = settle()
            down, _ = shift(before, after)
            drag(CHAT_DRAG_TO, DRAG_FROM)
            back, _, _ = settle()
            up, _ = shift(after, back)
            result["drag_px"] = {"down": down, "up": up}
            print(f"  drag length here: {down} down, {up} up")
    # The last jump leaves the oldest message at the top, the thread's end,
    # so the drags go back down the thread, towards the newer messages.
    expected = result["drag_px"]["up"]
    nodes, _, _ = settle()
    for k in range(drags):
        drag(CHAT_DRAG_TO, DRAG_FROM)
        after, xml, _ = settle()
        open(os.path.join(out, f"drag{k}.xml"), "w").write(xml)
        moved, common = shift(nodes, after)
        err = None if moved is None or expected is None else moved - expected
        result["drags"].append({"moved_px": moved, "error_px": err, "texts_compared": common})
        print(f"  drag {k + 1}: moved {moved} (expected {expected}), error {err}")
        nodes = after
    subprocess.run(f"adb exec-out screencap -p > '{os.path.join(out, 'drags_end.png')}'", shell=True, check=True)
    adb("am", "force-stop", pkg)
    json.dump(result, open(os.path.join(out, "results.json"), "w"), indent=2)


def main():
    app, out = sys.argv[1], sys.argv[2]
    drags = int(sys.argv[sys.argv.index("--drags") + 1]) if "--drags" in sys.argv else 6
    button = "Scroll"
    if "--chat" in sys.argv:
        return main_chat(app, out, drags, button)
    pkg, launch = app_of(app, "cards")
    os.makedirs(out, exist_ok=True)
    adb("am", "force-stop", pkg)
    time.sleep(1)
    adb(*launch)
    time.sleep(5)
    # The screen is ready once its bar's buttons show.
    for _ in range(8):
        if any(d == button for _, d, *_ in dump()[0]):
            break
        time.sleep(2)
    else:
        raise RuntimeError(f"no {button} button on screen")

    result = {"app": app, "button": button, "targets": TARGETS, "landings": [], "drags": []}
    calibration = None
    for n, card in enumerate(TARGETS):
        tap(button)
        nodes, xml, took = settle()
        open(os.path.join(out, f"jump{n}_{card}.xml"), "w").write(xml)
        subprocess.run(f"adb exec-out screencap -p > '{os.path.join(out, f'jump{n}_{card}.png')}'",
                       shell=True, check=True)
        top = title_top(nodes, card)
        if n == 0:
            calibration = top
            if top is None or author_top(nodes, card) is None:
                raise RuntimeError("the calibration jump did not land on card 1")
            title_below_author = top - author_top(nodes, card)
        elif top is None and author_top(nodes, card) is not None:
            top = author_top(nodes, card) + title_below_author
        landing = {
            "card": card,
            "title_top_px": top,
            "error_px": None if top is None or n == 0 else top - calibration,
            "first_card_on_screen": first_title(nodes),
            "settled_s": None if took is None else round(took, 1),
        }
        result["landings"].append(landing)
        print(f"  jump to {card}: title at {top}, error {landing['error_px']}, "
              f"top card #{landing['first_card_on_screen']}, settled in {landing['settled_s']} s")
        if n == 0:
            # Measure this app's drag length among cards it has already
            # measured: the test's drag, back towards the header, then the
            # same drag in reverse (card 1's title stays on screen both
            # times).
            before = nodes
            drag(DRAG_FROM, DRAG_TO)
            after, _, _ = settle()
            down, _ = shift(before, after)
            drag(DRAG_TO, DRAG_FROM)
            back, _, _ = settle()
            up, _ = shift(after, back)
            result["drag_px"] = {"down": down, "up": up}
            print(f"  drag length here: {down} down, {up} up")

    expected = result["drag_px"]["down"]
    nodes, _, _ = settle()
    for k in range(drags):
        drag(DRAG_FROM, DRAG_TO)
        after, xml, _ = settle()
        open(os.path.join(out, f"drag{k}.xml"), "w").write(xml)
        moved, common = shift(nodes, after)
        err = None if moved is None or expected is None else moved - expected
        result["drags"].append({"moved_px": moved, "error_px": err, "texts_compared": common,
                                "first_card_on_screen": first_title(after)})
        print(f"  drag {k + 1}: moved {moved} (expected {expected}), error {err}, "
              f"top card #{first_title(after)}")
        nodes = after
    subprocess.run(f"adb exec-out screencap -p > '{os.path.join(out, 'drags_end.png')}'", shell=True, check=True)
    adb("am", "force-stop", pkg)
    json.dump(result, open(os.path.join(out, "results.json"), "w"), indent=2)


if __name__ == "__main__":
    main()
