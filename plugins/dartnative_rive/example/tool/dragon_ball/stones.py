"""stones.py: the floating stones, cut out of the rendered trace.

A stone is not a set of the trace's paths: its colours run on under the sky
around it. So each is found in the picture instead. For every stone — a
rectangle in image pixels that holds it — this gives its pixels, by colour
and connectivity; their outline as a polygon, which clips the copy that
moves; the outline a few pixels out, the patch that hides the stone where
the trace has it; the sky colours above and below it, the patch's fill; and
over that fill, the shapes around the stone run on into its place."""
import collections, math, struct, zlib

# How far the patch reaches beyond the stone's pixels. The trace draws a
# stone's soft edge as thin bands of in-between colours around it; a patch
# short of them leaves a ring where the stone was, once the stone moves off.
PATCH = 3
MEND_LEAST = 12      # pixels: a smaller piece of the mend is left to the patch's fill

STONES = [
    # name, the rectangle that holds it (x0, y0, x1, y1), [opening radius]
    ('Stone 1', (0, 520, 94, 670), 5),   # opened: the beam's edge has its colours and touches it
    ('Stone 2', (174, 430, 224, 510)),
    ('Stone 3', (154, 555, 204, 612)),
    ('Stone 4', (74, 698, 116, 747)),
    ('Stone 5', (0, 476, 26, 516)),
    ('Stone 6', (922, 285, 960, 339)),
    ('Stone 7', (934, 505, 1014, 594)),
    ('Stone 8', (802, 704, 854, 759)),
    ('Stone 9', (243, 488, 270, 515)),
]


class Picture:
    """An 8-bit RGB or RGBA PNG, not interlaced, as Chrome writes one."""

    def __init__(self, path):
        data = open(path, 'rb').read()
        assert data[:8] == b'\x89PNG\r\n\x1a\n', 'not a PNG'
        pos = 8
        idat = b''
        while pos < len(data):
            n, kind = struct.unpack('>I4s', data[pos:pos + 8])
            body = data[pos + 8:pos + 8 + n]
            if kind == b'IHDR':
                self.w, self.h, depth, colour, _, _, interlace = struct.unpack('>IIBBBBB', body)
                assert depth == 8 and colour in (2, 6) and interlace == 0, 'unsupported PNG'
                self.bpp = 3 if colour == 2 else 4
            elif kind == b'IDAT':
                idat += body
            pos += 12 + n
        raw = zlib.decompress(idat)
        bpp, stride = self.bpp, self.w * self.bpp
        rows = []
        prev = bytearray(stride)
        p = 0
        for _ in range(self.h):
            f = raw[p]
            line = bytearray(raw[p + 1:p + 1 + stride])
            p += 1 + stride
            if f == 1:
                for i in range(bpp, stride):
                    line[i] = (line[i] + line[i - bpp]) & 255
            elif f == 2:
                for i in range(stride):
                    line[i] = (line[i] + prev[i]) & 255
            elif f == 3:
                for i in range(stride):
                    a = line[i - bpp] if i >= bpp else 0
                    line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
            elif f == 4:
                for i in range(stride):
                    a = line[i - bpp] if i >= bpp else 0
                    b = prev[i]
                    c = prev[i - bpp] if i >= bpp else 0
                    pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                    line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
            rows.append(line)
            prev = line
        self.rows = rows

    def px(self, x, y):
        i = x * self.bpp
        r = self.rows[y]
        return r[i], r[i + 1], r[i + 2]


def stony(c):
    """A stone's colours: the trace's near black, and its dark browns."""
    r, g, b = c
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    return lum < 34 or (r - b >= 10 and lum < 135)


def blobs(cand):
    seen = set()
    out = []
    for p in cand:
        if p in seen:
            continue
        blob = {p}
        q = collections.deque([p])
        seen.add(p)
        while q:
            x, y = q.popleft()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in cand and n not in seen:
                    seen.add(n)
                    blob.add(n)
                    q.append(n)
        out.append(blob)
    return out


def fill_holes(m):
    xs = [p[0] for p in m]
    ys = [p[1] for p in m]
    x0, x1, y0, y1 = min(xs) - 1, max(xs) + 1, min(ys) - 1, max(ys) + 1
    out = {(x0, y0)}
    q = collections.deque([(x0, y0)])
    while q:
        x, y = q.popleft()
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if x0 <= n[0] <= x1 and y0 <= n[1] <= y1 and n not in m and n not in out:
                out.add(n)
                q.append(n)
    return {(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1) if (x, y) not in out}


def dilate(m, n=1):
    for _ in range(n):
        m = m | {(x + dx, y + dy) for (x, y) in m for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
    return m


def erode(m, n=1):
    for _ in range(n):
        m = {(x, y) for (x, y) in m if all((x + dx, y + dy) in m for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    return m


def mask_of(pic, rect, opening=0):
    """The stone in rect: the largest blob of its colours, holes filled."""
    x0, y0, x1, y1 = rect
    x0, y0, x1, y1 = max(0, x0), max(0, y0), min(pic.w, x1), min(pic.h, y1)
    cand = {(x, y) for y in range(y0, y1) for x in range(x0, x1) if stony(pic.px(x, y))}
    best = max(blobs(cand), key=len)
    if opening:
        # Opened: eroded, the largest piece kept, grown back inside the blob.
        # A strip thinner than twice the radius no longer joins it.
        core = max(blobs(erode(best, opening)), key=len)
        best = max(blobs(dilate(core, opening + 1) & best), key=len)
    return fill_holes(best)


def outline(m):
    """The longest closed loop of pixel edges around m, as corner points."""
    nxt = collections.defaultdict(list)
    for (x, y) in m:
        if (x, y - 1) not in m: nxt[(x, y)].append((x + 1, y))
        if (x + 1, y) not in m: nxt[(x + 1, y)].append((x + 1, y + 1))
        if (x, y + 1) not in m: nxt[(x + 1, y + 1)].append((x, y + 1))
        if (x - 1, y) not in m: nxt[(x, y + 1)].append((x, y))
    loops = []
    while nxt:
        start = next(iter(nxt))
        loop = [start]
        cur = start
        while True:
            outs = nxt[cur]
            n = outs.pop()
            if not outs:
                del nxt[cur]
            if n == start:
                break
            loop.append(n)
            cur = n
        loops.append(loop)
    return max(loops, key=len)


def simplify(pts, eps):
    """Douglas-Peucker on a closed polygon."""
    def dp(a, b):
        if b - a < 2:
            return []
        ax, ay = pts[a]
        bx, by = pts[b % len(pts)]
        length = math.hypot(bx - ax, by - ay) or 1e-9
        dmax, idx = 0, None
        for i in range(a + 1, b):
            x, y = pts[i]
            d = abs((bx - ax) * (ay - y) - (ax - x) * (by - ay)) / length
            if d > dmax:
                dmax, idx = d, i
        if dmax <= eps:
            return []
        return dp(a, idx) + [idx] + dp(idx, b)
    n = len(pts)
    far = max(range(n), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)
    return [pts[i] for i in [0] + dp(0, far) + [far] + dp(far, n)]


def chaikin(pts, n=2):
    """Corner cutting: the pixel staircase becomes a curve of short lines."""
    for _ in range(n):
        out = []
        for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
            out.append((0.75 * x0 + 0.25 * x1, 0.75 * y0 + 0.25 * y1))
            out.append((0.25 * x0 + 0.75 * x1, 0.25 * y0 + 0.75 * y1))
        pts = out
    return pts


def polygon(m, eps=0.75, smooth=2):
    return chaikin(simplify(outline(m), eps), smooth)


def around(pic, m):
    """The sky around m: the commonest colour that is not the stone's in the
    upper half of a ring around it, and in the lower half."""
    ys = [p[1] for p in m]
    mid = (min(ys) + max(ys)) / 2
    top, bottom = collections.Counter(), collections.Counter()
    for (x, y) in dilate(m, PATCH + 5) - dilate(m, PATCH + 1):
        if 0 <= x < pic.w and 0 <= y < pic.h:
            p = pic.px(x, y)
            if not stony(p):
                (top if y < mid else bottom)[p] += 1
    both = top + bottom
    return ((top or both).most_common(1)[0][0], (bottom or both).most_common(1)[0][0])


def mend(pic, hole, palette):
    """What the sky might be where a stone was: [(colour, polygon)], the
    largest first. Every pixel of the hole takes the colour of the nearest
    pixel around it — the trace's colour nearest to that — so each shape
    that the stone interrupts runs on under it, and they meet in its middle.
    A polygon is a pixel wider than its pixels: they overlap, and nothing
    under them shows between two."""
    def trace(c):
        return min(palette, key=lambda q: (q[0] - c[0]) ** 2 + (q[1] - c[1]) ** 2 + (q[2] - c[2]) ** 2)

    around = [(x, y, trace(pic.px(x, y))) for (x, y) in dilate(hole, 1) - hole
              if 0 <= x < pic.w and 0 <= y < pic.h]
    parts = collections.defaultdict(set)
    for (x, y) in hole:
        if 0 <= x < pic.w and 0 <= y < pic.h:
            parts[min(around, key=lambda a: (a[0] - x) ** 2 + (a[1] - y) ** 2)[2]].add((x, y))
    out = []
    for colour, pixels in parts.items():
        for blob in blobs(pixels):
            if len(blob) >= MEND_LEAST:
                # Coarser than a stone's outline: these edges lie under it.
                out.append((len(blob), colour, polygon(dilate(blob, 1), 1.0, 1)))
    return [(colour, poly) for _, colour, poly in sorted(out, reverse=True)]


def cut(png, palette):
    """Each stone: its name, centre, clip and patch polygons, the patch's
    two colours, what mends it (of the trace's colours, `palette`), its
    pixels and their bounding box — in image pixels."""
    pic = Picture(png)
    out = []
    for name, rect, *opening in STONES:
        m = mask_of(pic, rect, *opening)
        xs = [p[0] for p in m]
        ys = [p[1] for p in m]
        box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        out.append({
            'name': name, 'centre': ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2),
            'clip': polygon(m), 'patch': polygon(dilate(m, PATCH)),
            'colours': around(pic, m), 'mend': mend(pic, dilate(m, PATCH), palette), 'box': box, 'mask': m,
        })
    return out
