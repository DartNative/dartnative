"""build_anime.py trace.svg trace.png out.riv [sound.mp3]: the traced SVG as
a Rive file.

build.sh runs this. trace.png is the SVG drawn at 1024 x 1024. A sound, when
given, is embedded in the file and plays each time the loop starts: an audio
event the animation fires on its first frame, which the runtime plays itself.

The artboard keeps the picture's top 870 rows (HEIGHT). The picture was
generated with Craiyon (craiyon.com), whose logo sits in its bottom right
corner; Craiyon's terms accept a credit in text beside the image instead,
which the Dragon Ball screen shows.

The trace's 32 colour layers become shapes of one artboard, each holding its
layer's contours under one fill, in the trace's paint order. The contours
are simplified first (simplify.py), since a Rive file pays for every segment
in every frame, and then cut up so the renderer fills each pixel of a layer
about once (cells.py). The first layer has the colour the artboard is
filled with, so it is left to that. On top of them, what moves:

  - nine floating stones. A stone is a node holding a copy of the paths that
    cover it, clipped to its outline, over a patch that hides the stone
    where the trace has it: the shapes around it, run on into its place
    (stones.py). The node rises, drifts and tilts.
  - over each of the two energy balls: a glow that swells and fades, a core
    that flashes, and bubbles of light that leave the ball and fade.

One looping animation, "Float", holds every key, and "State Machine 1" plays
it, so the file plays in a view that names neither.

A Rive file lists an artboard's objects top first: the first drawable in the
file is drawn last (Artboard::sortDrawOrder). Hence the order below."""
import math
import sys

import cells
import simplify
import stones
import svgparse
from rivwriter import PROPS, Riv

SCALE = 0.1                  # viewBox units to artboard pixels: 10240 to 1024
WIDTH, HEIGHT = 1024.0, 870.0  # the artboard: the picture without its bottom rows
FPS = 60
LOOP = 480                   # frames: 8 s
EPS = 0.9                    # px a simplified outline may stray from the trace
MIN_SIZE = 3.0               # px: a contour smaller both ways is dropped
SLACK = 400.0                # px2 of fan beyond its fill a cell may keep (cells.py)
LEAST = 16.0                 # px: a cell this small is cut no further
# What the layers are cut within: the artboard and a little more, off the
# trace's tenths of a pixel so no cut runs along one of its edges.
BOX = (-0.7373, -0.7373, WIDTH + 0.6129, HEIGHT + 0.6129)

BALLS = [
    # name, centre, glow radius, inner, middle and outer colour, beats a loop,
    # then its bubbles: (angle deg, from radius, to radius, size px, cycles a loop, delay)
    ('yellow', (266.0, 250.0), 150.0, (255, 253, 224), (255, 232, 120), (255, 214, 80), 8, [
        (-150, 110, 280, 30, 4, 0.00), (-78, 120, 295, 26, 3, 0.35), (-8, 110, 270, 32, 5, 0.15),
        (66, 120, 275, 24, 4, 0.50), (136, 110, 280, 28, 3, 0.25),
    ]),
    ('cyan', (636.0, 345.0), 104.0, (236, 255, 255), (150, 240, 246), (96, 214, 232), 12, [
        (-160, 70, 210, 22, 5, 0.20), (-88, 76, 225, 18, 4, 0.00), (-16, 70, 205, 22, 3, 0.45),
        (58, 76, 215, 18, 4, 0.30), (128, 70, 205, 22, 5, 0.55),
    ]),
]
BUBBLE = 0.8                 # a bubble's opacity at its brightest
# One row a stone, in stones.STONES' order. Beats and phases differ, so no
# two move together; every beat count divides the loop. The first stone lies
# over the beam, which the trace does not draw behind it: it moves least, so
# the gap it leaves in the beam stays small.
MOTION = [
    # rise px, beats, phase, drift px, beats, phase, tilt rad, beats, phase
    (12.0, 2, 0, 4.0, 1, 0, 0.075, 1, 0), (12.0, 3, 1, 5.0, 2, 1, 0.160, 2, 1),
    (14.0, 2, 1, 6.0, 3, 0, 0.150, 3, 0), (11.0, 4, 0, 5.0, 2, 0, 0.190, 2, 0),
    (9.0, 3, 0, 3.0, 1, 1, 0.180, 1, 1), (12.0, 2, 1, 5.0, 3, 1, 0.190, 3, 1),
    (15.0, 3, 0, 6.0, 2, 0, 0.120, 2, 0), (12.0, 2, 0, 5.0, 1, 0, 0.160, 1, 0),
    (9.0, 4, 1, 5.0, 3, 0, 0.240, 3, 0),
]


def argb(rgb, a=255):
    return (a << 24) | (rgb[0] << 16) | (rgb[1] << 8) | rgb[2]


_simplified = {}


def contour(sub):
    """A parsed contour in artboard pixels, simplified: (start, segments), or
    None when it is too small to see."""
    if id(sub) not in _simplified:
        _simplified[id(sub)] = simplify.contour(
            (sub.start[0] * SCALE, sub.start[1] * SCALE),
            [(k, tuple(a * SCALE for a in v)) for k, v in sub.segs], EPS, MIN_SIZE)
    return _simplified[id(sub)]


def lines(pts):
    return (pts[0], [('L', p) for p in pts[1:]])


def winding(path, x, y):
    """The winding of a point in a path's contours, through their anchors."""
    w = 0
    for sub in path:
        pts = [sub.start] + [(v[-2], v[-1]) for _, v in sub.segs]
        for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
            if (y0 <= y) != (y1 <= y) and x0 + (y - y0) / (y1 - y0) * (x1 - x0) > x:
                w += 1 if y1 > y0 else -1
    return w


class Builder:
    def __init__(self, sound=None):
        self.r = Riv()
        self.r.obj('Backboard', counted=False)
        # A file's assets come before its artboards; an audio event names
        # its asset by its place among them.
        if sound:
            self.r.obj('AudioAsset', [('Asset.name', 'Power-up'), ('FileAsset.assetId', 1)], counted=False)
            self.r.obj('FileAssetContents', [('FileAssetContents.bytes', sound)], counted=False)
        self.artboard = self.r.artboard([
            ('Component.name', 'Dragon Ball'),
            ('LayoutComponent.width', WIDTH), ('LayoutComponent.height', HEIGHT),
            ('LayoutComponent.clip', True),
        ])
        self.vertices = 0

    def shape(self, parent, name=None, extra=()):
        props = [('Component.parentId', parent)] + list(extra)
        if name:
            props.insert(0, ('Component.name', name))
        return self.r.obj('Shape', props)

    def solid(self, parent, color):
        fill = self.r.obj('Fill', [('Component.parentId', parent)])
        self.r.obj('SolidColor', [('Component.parentId', fill), ('SolidColor.colorValue', color)])

    def gradient(self, parent, kind, stops, **ends):
        """A fill of `kind` ('LinearGradient' or 'RadialGradient'), its ends in
        the shape's space, and its stops [(colour, position)]."""
        fill = self.r.obj('Fill', [('Component.parentId', parent)])
        gradient = self.r.obj(kind, [('Component.parentId', fill)] +
                              [('LinearGradient.' + k, v) for k, v in ends.items()])
        for color, position in stops:
            self.r.obj('GradientStop', [('Component.parentId', gradient),
                                        ('GradientStop.colorValue', color), ('GradientStop.position', position)])

    def disc(self, name, x, y, radius, stops):
        """A circle at (x, y) filled from its centre out with `stops`."""
        shape = self.shape(self.artboard, name, [('Node.x', x), ('Node.y', y)])
        self.r.obj('Ellipse', [('Component.parentId', shape),
                               ('ParametricPath.width', radius * 2), ('ParametricPath.height', radius * 2)])
        self.gradient(shape, 'RadialGradient', stops, endX=radius)
        return shape

    def path(self, parent, start_segs, ox=0.0, oy=0.0):
        """One closed contour as a PointsPath, its points relative to (ox, oy);
        nothing for a contour simplified away.

        A Rive vertex carries its own handles, as an angle and a distance:
        the one into it is the second control point of the segment that ends
        there, the one out of it the first of the segment that starts there.
        A point with neither is a StraightVertex."""
        if start_segs is None:
            return None
        start, segs = start_segs
        pid = self.r.obj('PointsPath', [('Component.parentId', parent), ('PointsCommonPath.isClosed', True)])
        anchors = [start] + [(v[-2], v[-1]) for _, v in segs]
        outs = [((v[0], v[1]) if k == 'C' else None) for k, v in segs] + [None]
        ins = [None] + [((v[2], v[3]) if k == 'C' else None) for k, v in segs]
        # A contour drawn back to its start: its last anchor is its first.
        if len(anchors) > 1 and math.dist(anchors[-1], anchors[0]) < 1e-6:
            ins[0] = ins[-1]
            anchors.pop()
            ins.pop()
            outs.pop()
        for (x, y), i, o in zip(anchors, ins, outs):
            props = [('Component.parentId', pid), ('Vertex.x', x - ox), ('Vertex.y', y - oy)]
            has_in = i is not None and math.dist(i, (x, y)) > 1e-4
            has_out = o is not None and math.dist(o, (x, y)) > 1e-4
            if has_in:
                props += [('CubicDetachedVertex.inRotation', math.atan2(i[1] - y, i[0] - x)),
                          ('CubicDetachedVertex.inDistance', math.dist(i, (x, y)))]
            if has_out:
                props += [('CubicDetachedVertex.outRotation', math.atan2(o[1] - y, o[0] - x)),
                          ('CubicDetachedVertex.outDistance', math.dist(o, (x, y)))]
            self.r.obj('CubicDetachedVertex' if has_in or has_out else 'StraightVertex', props)
            self.vertices += 1
        return pid


def main(svg, png, out, sound=None):
    groups = svgparse.load(svg)
    cut = stones.cut(png, [g['color'] for g in groups])
    b = Builder(open(sound, 'rb').read() if sound else None)
    r = b.r

    # On top: over each energy ball, its bubbles, its core and its glow.
    glows, cores, bubbles = [], [], []
    for name, (cx, cy), radius, inner, middle, outer, beats, orbs in BALLS:
        for i, (angle, r0, r1, size, cycles, delay) in enumerate(orbs):
            ca, sa = math.cos(math.radians(angle)), math.sin(math.radians(angle))
            shape = b.disc('Bubble %s %d' % (name, i + 1), cx + ca * r0, cy + sa * r0, size / 2,
                           [(argb((255, 255, 255), 255), 0.0), (argb(inner, 235), 0.35), (argb(middle, 150), 0.65),
                            (argb(outer, 0), 1.0)])
            bubbles.append((shape, (cx + ca * r0, cy + sa * r0), (cx + ca * r1, cy + sa * r1), cycles, delay))
        cores.append((b.disc('Core ' + name, cx, cy, radius * 0.34,
                             [(argb((255, 255, 255), 230), 0.0), (argb(inner, 120), 0.5), (argb(inner, 0), 1.0)]),
                      beats))
        glows.append((b.disc('Glow ' + name, cx, cy, radius,
                             [(argb(inner, 200), 0.0), (argb(middle, 120), 0.45), (argb(outer, 0), 1.0)]),
                      beats))

    # The stones: a node at the stone's centre, its outline as the clip of
    # everything under the node, and the layers that show inside it, the
    # lightest — the trace's topmost — first.
    nodes = []
    for s in cut:
        cx, cy = s['centre']
        node = r.obj('Node', [('Component.name', s['name']), ('Component.parentId', b.artboard),
                              ('Node.x', cx), ('Node.y', cy)])
        clip = b.shape(node, s['name'] + ' outline')
        b.path(clip, lines(s['clip']), cx, cy)
        r.obj('ClippingShape', [('Component.parentId', node), ('ClippingShape.sourceId', clip)])
        x0, y0, x1, y1 = s['box']
        probes = sorted(s['mask'])[::max(1, len(s['mask']) // 160)]
        for group in reversed(groups):
            mine = []
            for path in group['paths']:
                near = any(sub.bbox[2] * SCALE >= x0 and sub.bbox[0] * SCALE <= x1 and
                           sub.bbox[3] * SCALE >= y0 and sub.bbox[1] * SCALE <= y1 for sub in path)
                if near and any(winding(path, (px + 0.5) / SCALE, (py + 0.5) / SCALE) for px, py in probes):
                    mine += path
            # Only what the stone's box holds of them: the rest is clipped
            # away, and would be filled before it is.
            mine, _ = cells.fill([contour(sub) for sub in mine],
                                 (x0 - 2.0373, y0 - 2.0373, x1 + 2.0911, y1 + 2.0911), SLACK, LEAST)
            if mine:
                shape = b.shape(node)
                for c in mine:
                    b.path(shape, c, cx, cy)
                b.solid(shape, argb(group['color']))
        nodes.append(node)

    # The patches where the trace has the stones: the sky above a stone at
    # its top, the sky below it at its bottom, and over that the shapes
    # around the stone run on into its place, the smallest on top.
    for s in cut:
        for colour, poly in reversed(s['mend']):
            shape = b.shape(b.artboard)
            b.path(shape, lines(poly))
            b.solid(shape, argb(colour))
        shape = b.shape(b.artboard, s['name'] + ' patch')
        b.path(shape, lines(s['patch']))
        above, below = s['colours']
        x = (s['box'][0] + s['box'][2]) / 2
        b.gradient(shape, 'LinearGradient', [(argb(above), 0.0), (argb(below), 1.0)],
                   startX=x, startY=float(s['box'][1]), endX=x, endY=float(s['box'][3]))

    # The trace: a shape a colour layer, the last painted first in the file.
    # Not the first: the artboard's fill is its colour.
    fan = rough = 0
    for i, group in reversed(list(enumerate(groups))[1:]):
        shape = b.shape(b.artboard, 'Layer %d' % (i + 1))
        loops, left = cells.fill([contour(sub) for path in group['paths'] for sub in path], BOX, SLACK, LEAST)
        for c in loops:
            b.path(shape, c)
            fan += cells.fan(c)
        rough += left
        b.solid(shape, argb(group['color']))

    # The artboard's own fill, under everything: the first layer's colour,
    # which also closes the hairlines the trace leaves open along its edges.
    b.solid(b.artboard, argb(groups[0]['color']))

    # The sound: an audio event that plays the file's one asset.
    power_up = r.obj('AudioEvent', [('Component.name', 'Power-up'), ('Component.parentId', b.artboard),
                                    ('AudioEvent.assetId', 0)]) if sound else None

    ease = r.obj('CubicEaseInterpolator', [
        ('CubicInterpolator.x1', 0.42), ('CubicInterpolator.y1', 0.0),
        ('CubicInterpolator.x2', 0.58), ('CubicInterpolator.y2', 1.0),
    ])

    r.obj('LinearAnimation', [('Animation.name', 'Float'), ('LinearAnimation.fps', FPS),
                              ('LinearAnimation.duration', LOOP), ('LinearAnimation.loopValue', 1)],
          counted=False)

    def keys(prop, frames):
        """Keys of the keyed object's property: [(frame, value, how)], how
        being 0 to hold the value, 1 to go on in a line, 2 eased."""
        r.obj('KeyedProperty', [('KeyedProperty.propertyKey', PROPS[prop][0])], counted=False)
        for frame, value, how in frames:
            props = [('KeyFrameDouble.value', value), ('InterpolatingKeyFrame.interpolationType', how)]
            if how == 2:
                props.append(('InterpolatingKeyFrame.interpolatorId', ease))
            if frame:
                props.insert(0, ('KeyFrame.frame', frame))
            r.obj('KeyFrameDouble', props, counted=False)

    def wave(prop, base, amp, beats, phase=0):
        """The property swings base - amp .. base + amp, `beats` times a
        loop, eased in and out; phase 1 starts it high."""
        half = LOOP // (beats * 2)
        keys(prop, [(k * half, base + (amp if (k + phase) % 2 == 1 else -amp), 2) for k in range(beats * 2 + 1)])

    if power_up is not None:
        # Fired on the loop's first frame, so on every loop: a callback key
        # on the event's trigger.
        r.obj('KeyedObject', [('KeyedObject.objectId', power_up)], counted=False)
        r.obj('KeyedProperty', [('KeyedProperty.propertyKey', PROPS['Event.trigger'][0])], counted=False)
        r.obj('KeyFrameCallback', counted=False)
    for node, s, (rise, beats, phase, drift, d_beats, d_phase, tilt, t_beats, t_phase) in zip(nodes, cut, MOTION):
        r.obj('KeyedObject', [('KeyedObject.objectId', node)], counted=False)
        wave('Node.x', s['centre'][0], drift, d_beats, d_phase)
        wave('Node.y', s['centre'][1], rise, beats, phase)
        wave('TransformComponent.rotation', 0.0, tilt, t_beats, t_phase)
    for shape, beats in glows:
        r.obj('KeyedObject', [('KeyedObject.objectId', shape)], counted=False)
        wave('TransformComponent.scaleX', 1.0, 0.22, beats)
        wave('TransformComponent.scaleY', 1.0, 0.22, beats)
        wave('WorldTransformComponent.opacity', 0.6, 0.4, beats)
    for shape, beats in cores:
        # Out of step with its glow: high when the glow is low.
        r.obj('KeyedObject', [('KeyedObject.objectId', shape)], counted=False)
        wave('TransformComponent.scaleX', 1.0, 0.3, beats, 1)
        wave('TransformComponent.scaleY', 1.0, 0.3, beats, 1)
        wave('WorldTransformComponent.opacity', 0.55, 0.45, beats, 1)
    for shape, (x0, y0), (x1, y1), cycles, delay in bubbles:
        # A cycle: unseen at the ball's rim for `delay` of it, then out
        # along its ray into the sky, where it fades; back at the rim,
        # unseen, for the next.
        span = LOOP // cycles
        wait = int(span * delay)
        x, y, opacity, scale = [], [], [], []
        for c in range(cycles):
            f = c * span
            if wait:
                x.append((f, x0, 0))
                y.append((f, y0, 0))
                opacity.append((f, 0.0, 0))
                scale.append((f, 1.0, 0))
            x += [(f + wait, x0, 1), (f + span - 1, x1, 0)]
            y += [(f + wait, y0, 1), (f + span - 1, y1, 0)]
            flight = span - 1 - wait
            opacity += [(f + wait, 0.0, 1), (f + wait + flight // 5, BUBBLE, 1),
                        (f + wait + flight * 7 // 10, BUBBLE, 1), (f + span - 1, 0.0, 0)]
            scale += [(f + wait, 1.0, 1), (f + span - 1, 0.6, 0)]
        r.obj('KeyedObject', [('KeyedObject.objectId', shape)], counted=False)
        keys('Node.x', x)
        keys('Node.y', y)
        keys('WorldTransformComponent.opacity', opacity)
        keys('TransformComponent.scaleX', scale)
        keys('TransformComponent.scaleY', scale)

    # The state machine: one layer, whose entry state goes to the one state
    # that plays the animation. A layer's transitions name its states by
    # their place in it.
    r.obj('StateMachine', [('Animation.name', 'State Machine 1')], counted=False)
    r.obj('StateMachineLayer', [('StateMachineComponent.name', 'Layer 1')], counted=False)
    r.obj('AnimationState', [('AnimationState.animationId', 0)], counted=False)   # state 0
    r.obj('AnyState', counted=False)                                              # state 1
    r.obj('EntryState', counted=False)                                            # state 2
    r.obj('StateTransition', [('StateTransition.stateToId', 0)], counted=False)
    r.obj('ExitState', counted=False)                                             # state 3

    data = r.bytes()
    with open(out, 'wb') as f:
        f.write(data)
    print('%s: %d bytes, %d vertices, %d artboard objects' % (out, len(data), b.vertices, r.local + 1))
    print('layers: %.2f million px of fan, %d cells left as cut' % (fan / 1e6, rough))


if __name__ == '__main__':
    if len(sys.argv) not in (4, 5):
        sys.exit(__doc__)
    main(*sys.argv[1:])
