"""svgparse.py: the traced SVG as colour layers of closed contours.

The trace is 32 groups, one per colour, each a list of paths whose `d` uses
M, m, l, c and z only. A contour is its start point and its segments,
('L', (x, y)) or ('C', (x1, y1, x2, y2, x, y)), absolute, in viewBox units."""
import re

TOK = re.compile(r'([MmLlCcZz])|(-?\d*\.?\d+(?:e-?\d+)?)')


class Sub:
    __slots__ = ('start', 'segs', 'closed', 'bbox')

    def __init__(self, start):
        self.start = start
        self.segs = []
        self.closed = False


def parse_d(d):
    subs = []
    cur = None
    x = y = sx = sy = 0.0
    toks = TOK.findall(d)
    i = 0
    cmd = None

    def num():
        nonlocal i
        v = float(toks[i][1])
        i += 1
        return v

    while i < len(toks):
        if toks[i][0]:
            cmd = toks[i][0]
            i += 1
            if cmd in 'Zz':
                if cur is not None:
                    cur.closed = True
                x, y = sx, sy
                continue
        if cmd in 'Mm':
            nx, ny = num(), num()
            if cmd == 'm':
                nx += x
                ny += y
            x, y = nx, ny
            sx, sy = x, y
            cur = Sub((x, y))
            subs.append(cur)
            cmd = 'L' if cmd == 'M' else 'l'   # coordinates after a moveto are linetos
        elif cmd in 'Ll':
            nx, ny = num(), num()
            if cmd == 'l':
                nx += x
                ny += y
            cur.segs.append(('L', (nx, ny)))
            x, y = nx, ny
        elif cmd in 'Cc':
            v = [num() for _ in range(6)]
            if cmd == 'c':
                v = [v[0] + x, v[1] + y, v[2] + x, v[3] + y, v[4] + x, v[5] + y]
            cur.segs.append(('C', tuple(v)))
            x, y = v[4], v[5]
        else:
            raise ValueError('path command %r' % cmd)
    return subs


def bbox(sub):
    xs = [sub.start[0]]
    ys = [sub.start[1]]
    for _, v in sub.segs:
        xs += v[0::2]
        ys += v[1::2]
    return (min(xs), min(ys), max(xs), max(ys))


def load(path):
    """[{'color': (r, g, b), 'paths': [[Sub, ...], ...]}], in paint order."""
    s = open(path).read()
    groups = []
    for gm in re.finditer(r'<g id="[^"]*" fill="rgb\((\d+),(\d+),(\d+)\)"[^>]*>(.*?)</g></g>', s, re.S):
        paths = []
        for d in re.findall(r'<path[^>]* d="([^"]*)"', gm.group(4)):
            subs = parse_d(d)
            for sb in subs:
                sb.bbox = bbox(sb)
            paths.append(subs)
        groups.append({'color': (int(gm.group(1)), int(gm.group(2)), int(gm.group(3))), 'paths': paths})
    return groups
