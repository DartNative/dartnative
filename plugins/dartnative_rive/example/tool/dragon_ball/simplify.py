"""simplify.py: the trace with fewer segments, within a tolerance.

A traced outline is cut into many more cubics than its shape needs, and a
Rive file pays for each one every frame. Neighbouring segments are merged
into one cubic wherever that cubic stays within `eps` pixels of what they
drew (and they of it); a cubic that is a line within the tolerance becomes
one; and a contour too small to see is dropped. Works on svgparse's contours,
in artboard pixels."""
import math

SAMPLES = 4          # points kept along each original segment


def _bez(p0, p1, p2, p3, t):
    m = 1 - t
    a, b, c, d = m * m * m, 3 * m * m * t, 3 * m * t * t, t * t * t
    return (a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1])


def _dist_to_polyline(p, line):
    best = 1e18
    px, py = p
    for (ax, ay), (bx, by) in zip(line, line[1:]):
        dx, dy = bx - ax, by - ay
        L = dx * dx + dy * dy
        t = 0.0 if L == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L))
        qx, qy = ax + t * dx, ay + t * dy
        d = (px - qx) ** 2 + (py - qy) ** 2
        if d < best:
            best = d
    return math.sqrt(best)


class Seg:
    """A cubic p0 c1 c2 p3 and the points of the original outline it stands for."""
    __slots__ = ('p0', 'c1', 'c2', 'p3', 'orig')

    def __init__(self, p0, c1, c2, p3, orig=None):
        self.p0, self.c1, self.c2, self.p3 = p0, c1, c2, p3
        self.orig = orig or [_bez(p0, c1, c2, p3, i / SAMPLES) for i in range(SAMPLES + 1)]

    def length(self):
        return (math.dist(self.p0, self.c1) + math.dist(self.c1, self.c2) + math.dist(self.c2, self.p3) +
                math.dist(self.p0, self.p3)) / 2


def _merge(a, b, eps):
    """One cubic for a then b, or None when it strays more than eps."""
    la, lb = a.length(), b.length()
    if la + lb == 0:
        return Seg(a.p0, a.p0, b.p3, b.p3, a.orig + b.orig[1:])
    t = min(0.95, max(0.05, la / (la + lb)))
    c1 = (a.p0[0] + (a.c1[0] - a.p0[0]) / t, a.p0[1] + (a.c1[1] - a.p0[1]) / t)
    c2 = (b.p3[0] + (b.c2[0] - b.p3[0]) / (1 - t), b.p3[1] + (b.c2[1] - b.p3[1]) / (1 - t))
    orig = a.orig + b.orig[1:]
    n = max(8, len(orig))
    line = [_bez(a.p0, c1, c2, b.p3, i / n) for i in range(n + 1)]
    for p in orig:
        if _dist_to_polyline(p, line) > eps:
            return None
    for p in line[1:-1]:
        if _dist_to_polyline(p, orig) > eps:
            return None
    return Seg(a.p0, c1, c2, b.p3, orig)


def contour(start, segs, eps, min_size):
    """(start, segs) simplified, or None for a contour too small to see."""
    cur = start
    out = []
    for kind, v in segs:
        if kind == 'L':
            p3 = (v[0], v[1])
            c1 = (cur[0] + (p3[0] - cur[0]) / 3, cur[1] + (p3[1] - cur[1]) / 3)
            c2 = (cur[0] + (p3[0] - cur[0]) * 2 / 3, cur[1] + (p3[1] - cur[1]) * 2 / 3)
        else:
            c1, c2, p3 = (v[0], v[1]), (v[2], v[3]), (v[4], v[5])
        if math.dist(cur, p3) > 1e-9 or kind == 'C':
            out.append(Seg(cur, c1, c2, p3))
        cur = p3
    if not out:
        return None
    xs = [p[0] for s in out for p in s.orig]
    ys = [p[1] for s in out for p in s.orig]
    if max(xs) - min(xs) < min_size and max(ys) - min(ys) < min_size:
        return None
    # Merge along the contour until a pass merges nothing.
    changed = True
    while changed and len(out) > 2:
        changed = False
        i = 0
        merged = []
        while i < len(out):
            s = out[i]
            while i + 1 < len(out):
                m = _merge(s, out[i + 1], eps)
                if m is None:
                    break
                s = m
                i += 1
                changed = True
            merged.append(s)
            i += 1
        out = merged
    result = []
    for s in out:
        chord = [s.p0, s.p3]
        if _dist_to_polyline(s.c1, chord) < eps / 2 and _dist_to_polyline(s.c2, chord) < eps / 2 and \
                all(_dist_to_polyline(p, chord) < eps for p in s.orig):
            result.append(('L', s.p3))
        else:
            result.append(('C', (s.c1[0], s.c1[1], s.c2[0], s.c2[1], s.p3[0], s.p3[1])))
    return (out[0].p0, result)
