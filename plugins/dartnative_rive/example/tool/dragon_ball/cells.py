"""cells.py: a layer's fill as loops the renderer pays for once.

Rive's renderer fills a contour as a fan of triangles, from the middle of
its points to each of its segments, and a pixel pays for every triangle over
it. A traced layer is the worst case for that: a contour that winds across
the whole artboard around the figures has a fan several times its own area,
and every hole is filled once by the contour it is cut from and once by
itself. As traced, the layers are 1.8 million pixels of colour and 5.3
million of triangles.

So the artboard is cut into cells, in two again and again where it pays, and
a layer is written as what it fills in each: its outlines' runs inside the
cell, joined along the cell's edges into loops that hold the fill and
nothing else. A cell wholly inside the layer is one rectangle; a hole that
leaves the cell is no longer a hole but a bend in a loop. The loops of a
layer stay in its one shape, under its one fill, and meet edge to edge:
along a cut their coverage adds up to what the uncut layer had.

A contour is svgparse's: (start, [('L', (x, y)) | ('C', (x1, y1, x2, y2, x, y))]),
closed, the fill by non-zero winding. Inside, a contour is a closed list of
segments, each a tuple of its points: two for a line, four for a cubic."""
import bisect
import math

FLAT = 4             # lines a cubic is measured as


def _segments(contour):
    start, segs = contour
    out = []
    cur = start
    for kind, v in segs:
        end = (v[-2], v[-1])
        if kind == 'L':
            if end != cur:
                out.append((cur, end))
        else:
            out.append((cur, (v[0], v[1]), (v[2], v[3]), end))
        cur = end
    if cur != start:
        out.append((cur, start))
    return out


def _contour(loop):
    """A loop as svgparse has contours; None for one with nothing to draw."""
    segs = []
    for s in loop:
        if len(s) == 2:
            if math.dist(s[0], s[1]) > 1e-6:
                segs.append(('L', s[1]))
        elif max(math.dist(s[0], p) for p in s[1:]) > 1e-6:
            segs.append(('C', s[1] + s[2] + s[3]))
    return (loop[0][0], segs) if len(segs) > 1 else None


def _points(loop):
    """The loop as a polygon: every segment's start, a cubic's inside too."""
    pts = []
    for s in loop:
        pts.append(s[0])
        if len(s) == 4:
            (x0, y0), (x1, y1), (x2, y2), (x3, y3) = s
            for i in range(1, FLAT):
                t = i / FLAT
                m = 1 - t
                a, b, c, d = m * m * m, 3 * m * m * t, 3 * m * t * t, t * t * t
                pts.append((a * x0 + b * x1 + c * x2 + d * x3, a * y0 + b * y1 + c * y2 + d * y3))
    return pts


def measure(loop):
    """(area, fan): the loop's signed area, and the area of the triangles the
    renderer draws for it, from the mean of its segments' ends."""
    pts = _points(loop)
    mx = sum(s[0][0] for s in loop) / len(loop)
    my = sum(s[0][1] for s in loop) / len(loop)
    area = fan = 0.0
    px, py = pts[-1]
    for x, y in pts:
        a = ((px - mx) * (y - my) - (x - mx) * (py - my)) / 2
        area += a
        fan += abs(a)
        px, py = x, y
    return area, fan


def fan(contour):
    """The area of the triangles the renderer draws for a contour."""
    return measure(_segments(contour))[1]


def _crossings(v0, v1, v2, v3):
    """Where in 0..1 a cubic with these control values changes side of zero
    (zero itself counts as above)."""
    d0, d1, d2 = v1 - v0, v2 - v1, v3 - v2
    a, b, c = d0 - 2 * d1 + d2, 2 * (d1 - d0), d0
    stops = [0.0]
    if abs(a) < 1e-12:
        if abs(b) > 1e-12 and 0 < -c / b < 1:
            stops.append(-c / b)
    else:
        disc = b * b - 4 * a * c
        if disc > 0:
            q = math.sqrt(disc)
            stops += sorted(r for r in ((-b - q) / (2 * a), (-b + q) / (2 * a)) if 0 < r < 1)
    stops.append(1.0)

    def above(t):
        m = 1 - t
        return v0 * m * m * m + 3 * v1 * m * m * t + 3 * v2 * m * t * t + v3 * t * t * t >= 0

    out = []
    for lo, hi in zip(stops, stops[1:]):
        side = above(lo)
        if above(hi) != side:
            for _ in range(60):
                mid = (lo + hi) / 2
                if above(mid) == side:
                    lo = mid
                else:
                    hi = mid
            out.append(hi)
    return out


def _halves(s, t):
    """De Casteljau: the cubic s in two at t."""
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = s
    ax, ay = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
    bx, by = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
    cx, cy = x2 + (x3 - x2) * t, y2 + (y3 - y2) * t
    dx, dy = ax + (bx - ax) * t, ay + (by - ay) * t
    ex, ey = bx + (cx - bx) * t, by + (cy - by) * t
    m = (dx + (ex - dx) * t, dy + (ey - dy) * t)
    return (s[0], (ax, ay), (dx, dy), m), (m, (ex, ey), (cx, cy), s[3])


def _on(p, axis, at):
    return (at, p[1]) if axis == 0 else (p[0], at)


def _parts(s, axis, at):
    """The segment in the pieces a line cuts it into: [(piece, above)]. The
    points on the line are on it exactly, and the two sides share them."""
    if len(s) == 2:
        a, b = s[0][axis] - at, s[1][axis] - at
        if (a >= 0) == (b >= 0):
            return [(s, a >= 0)]
        t = a / (a - b)
        m = _on((s[0][0] + (s[1][0] - s[0][0]) * t, s[0][1] + (s[1][1] - s[0][1]) * t), axis, at)
        return [((s[0], m), a >= 0), ((m, s[1]), b >= 0)]
    v = [p[axis] - at for p in s]
    above = v[0] >= 0
    if all((x >= 0) == above for x in v[1:]):
        return [(s, above)]
    out = []
    done = 0.0
    for t in _crossings(*v):
        left, s = _halves(s, (t - done) / (1 - done))
        m = _on(left[3], axis, at)
        out.append(((left[0], left[1], left[2], m), above))
        s = (m, s[1], s[2], s[3])
        above = not above
        done = t
    out.append((s, above))
    return out


def _closed(parts):
    """Pieces in a contour's order, joined along the line they were cut on."""
    if not parts:
        return None
    out = []
    prev = parts[-1][-1]
    for p in parts:
        if p[0] != prev:
            out.append((prev, p[0]))
        out.append(p)
        prev = p[-1]
    return out


def cut(loop, axis, at):
    """The loop on each side of the line x = at (axis 0) or y = at (axis 1):
    (below, above), either None. Each side winds as the loop did around every
    point of it."""
    lo = min(p[axis] for s in loop for p in s)
    hi = max(p[axis] for s in loop for p in s)
    if lo >= at:
        return None, loop
    if hi < at:
        return loop, None
    below, above = [], []
    for s in loop:
        for piece, side in _parts(s, axis, at):
            (above if side else below).append(piece)
    return _closed(below), _closed(above)


def _rect(box, sign):
    x0, y0, x1, y1 = box
    c = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
    if sign < 0:
        c.reverse()
    return [(c[i], c[(i + 1) % 4]) for i in range(4)]


def _along(p, box):
    """How far round the cell's edge p is, clockwise as drawn from its top
    left; None for a point not on it."""
    x0, y0, x1, y1 = box
    if p[1] == y0:
        return p[0] - x0
    if p[0] == x1:
        return (x1 - x0) + (p[1] - y0)
    if p[1] == y1:
        return (x1 - x0) + (y1 - y0) + (x1 - p[0])
    if p[0] == x0:
        return 2 * (x1 - x0) + (y1 - y0) + (y1 - p[1])
    return None


def _edge(s, box):
    """Whether s is a line along one of the cell's edges."""
    if len(s) != 2:
        return False
    (ax, ay), (bx, by) = s
    return (ax == bx and (ax == box[0] or ax == box[2])) or (ay == by and (ay == box[1] or ay == box[3]))


def _loops(pieces, box, sign):
    """What the pieces fill of the cell, as loops that do not overlap: each
    run of outline inside the cell, then the cell's edge, the fill's way
    round, to the run that comes in next. None when the pieces are not that
    simple — outlines that cross, or wind twice — and are best left alone."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    whole = (w + h) * 2
    runs, loops = [], []
    total = 0.0
    for piece in pieces:
        total += measure(piece)[0]
        on = [_edge(s, box) for s in piece]
        if not any(on):
            loops.append(piece)          # an island or a hole inside the cell
            continue
        if all(on):
            continue                     # the cell's own edge: the fill around the runs
        first = on.index(True)
        run = []
        for i in range(first + 1, first + 1 + len(piece)):
            s = piece[i % len(piece)]
            if on[i % len(piece)]:
                if run:
                    runs.append(run)
                run = []
            else:
                run.append(s)
    if not runs:
        if round(total / (w * h * sign)) > 0:
            loops.append(_rect(box, sign))
        elif abs(total) > 1e-6 * w * h and not loops:
            return None
    else:
        def key(p):
            a = _along(p, box)
            return None if a is None else (a if sign > 0 else (whole - a) % whole)

        corners = sorted((key(c), c) for c in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)))
        ins = sorted((key(r[0][0]), i) for i, r in enumerate(runs) if key(r[0][0]) is not None)
        if len(ins) != len(runs):
            return None
        keys = [k for k, _ in ins]
        nxt = {}
        for i, r in enumerate(runs):
            k = key(r[-1][-1])
            if k is None:
                return None
            j = ins[bisect.bisect_left(keys, k) % len(ins)][1]
            if j in nxt.values():
                return None
            nxt[i] = (j, k)
        left = set(range(len(runs)))
        while left:
            i = start = min(left)
            loop = []
            while True:
                left.discard(i)
                loop += runs[i]
                j, k = nxt[i]
                # Along the edge to where run j comes in, by the corners on the way.
                p = runs[i][-1][-1]
                reach = (key(runs[j][0][0]) - k) % whole
                for ck, c in sorted(corners, key=lambda c: (c[0] - k) % whole):
                    if 0 < (ck - k) % whole < reach:
                        loop.append((p, c))
                        p = c
                if p != runs[j][0][0]:
                    loop.append((p, runs[j][0][0]))
                i = j
                if i == start:
                    break
                if i not in left:
                    return None
            loops.append(loop)
    if abs(sum(measure(l)[0] for l in loops) - total) > 1e-6 * w * h:
        return None
    return loops


def fill(contours, box, slack, least):
    """What the contours fill inside box, as contours whose fans cover little
    more than the fill: a cell is cut in two while its loops' fans exceed
    their area by more than `slack` square pixels and it is wider or taller
    than `least`. Returns (contours, cells left as they were cut)."""
    pieces = [_segments(c) for c in contours if c is not None]
    pieces = [p for p in pieces if len(p) > 1]
    sign = 1 if sum(measure(p)[0] for p in pieces) >= 0 else -1
    for axis, at, keep in ((0, box[0], 1), (1, box[1], 1), (0, box[2], 0), (1, box[3], 0)):
        pieces = [q for q in (cut(p, axis, at)[keep] for p in pieces) if q]
    out = []
    rough = 0
    todo = [(pieces, box)]
    while todo:
        pieces, cell = todo.pop()
        if not pieces:
            continue
        loops = _loops(pieces, cell, sign)
        simple = loops is not None
        if not simple:
            loops = pieces
        sizes = [measure(l) for l in loops]
        over = sum(f for _, f in sizes) - abs(sum(a for a, _ in sizes))
        w, h = cell[2] - cell[0], cell[3] - cell[1]
        if over <= slack or max(w, h) <= least:
            rough += not simple
            out += loops
            continue
        axis = 0 if w >= h else 1
        at = (cell[axis] + cell[axis + 2]) / 2
        below, above = [], []
        for l in loops:
            a, b = cut(l, axis, at)
            if a:
                below.append(a)
            if b:
                above.append(b)
        todo.append((below, (cell[0], cell[1], at, cell[3]) if axis == 0 else (cell[0], cell[1], cell[2], at)))
        todo.append((above, (at, cell[1], cell[2], cell[3]) if axis == 0 else (cell[0], at, cell[2], cell[3])))
    return [c for c in (_contour(l) for l in out) if c], rough
