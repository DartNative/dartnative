"""rivwriter.py: writes a Rive runtime file (.riv, format 7.0), object by
object.

The layout is the one Rive documents for its runtimes
(rive.app/docs/runtimes/advanced-topic/format): the fingerprint "RIVE", the
version, a file id, a table of the property keys used with each one's field
type, then the objects — a type key, property key and value pairs, a zero.
The type and property keys below are rive-runtime's
(include/rive/generated/**/*_base.hpp), with each property's field type from
its core_registry.hpp: u = varuint (ids too), s = string, f = 32-bit float,
c = 32-bit colour, b = one byte, y = bytes (a varuint length, then them)."""
import struct

TYPES = {
    'Artboard': 1, 'Node': 2, 'Shape': 3, 'Ellipse': 4, 'StraightVertex': 5, 'CubicDetachedVertex': 6,
    'PointsPath': 16, 'RadialGradient': 17, 'SolidColor': 18, 'GradientStop': 19, 'Fill': 20,
    'LinearGradient': 22,
    'FileAssetContents': 106, 'KeyFrameCallback': 171, 'AudioAsset': 406, 'AudioEvent': 407,
    'Backboard': 23, 'KeyedObject': 25, 'KeyedProperty': 26, 'CubicEaseInterpolator': 28, 'KeyFrameDouble': 30,
    'LinearAnimation': 31, 'ClippingShape': 42, 'StateMachine': 53, 'StateMachineLayer': 57,
    'AnimationState': 61, 'AnyState': 62, 'EntryState': 63, 'ExitState': 64, 'StateTransition': 65,
}
PROPS = {
    'Component.name': (4, 's'),
    'Component.parentId': (5, 'u'),
    'LayoutComponent.width': (7, 'f'),
    'LayoutComponent.height': (8, 'f'),
    'Node.x': (13, 'f'),
    'Node.y': (14, 'f'),
    'TransformComponent.rotation': (15, 'f'),
    'TransformComponent.scaleX': (16, 'f'),
    'TransformComponent.scaleY': (17, 'f'),
    'WorldTransformComponent.opacity': (18, 'f'),
    'ParametricPath.width': (20, 'f'),
    'ParametricPath.height': (21, 'f'),
    'Vertex.x': (24, 'f'),
    'Vertex.y': (25, 'f'),
    'PointsCommonPath.isClosed': (32, 'b'),
    'LinearGradient.startY': (33, 'f'),
    'LinearGradient.endX': (34, 'f'),
    'LinearGradient.endY': (35, 'f'),
    'SolidColor.colorValue': (37, 'c'),
    'GradientStop.colorValue': (38, 'c'),
    'GradientStop.position': (39, 'f'),
    'LinearGradient.startX': (42, 'f'),
    'KeyedObject.objectId': (51, 'u'),
    'KeyedProperty.propertyKey': (53, 'u'),
    'Animation.name': (55, 's'),
    'LinearAnimation.fps': (56, 'u'),
    'LinearAnimation.duration': (57, 'u'),
    'LinearAnimation.loopValue': (59, 'u'),
    'CubicInterpolator.x1': (63, 'f'),
    'CubicInterpolator.y1': (64, 'f'),
    'CubicInterpolator.x2': (65, 'f'),
    'CubicInterpolator.y2': (66, 'f'),
    'KeyFrame.frame': (67, 'u'),
    'InterpolatingKeyFrame.interpolationType': (68, 'u'),
    'InterpolatingKeyFrame.interpolatorId': (69, 'u'),
    'KeyFrameDouble.value': (70, 'f'),
    'CubicDetachedVertex.inRotation': (84, 'f'),
    'CubicDetachedVertex.inDistance': (85, 'f'),
    'CubicDetachedVertex.outRotation': (86, 'f'),
    'CubicDetachedVertex.outDistance': (87, 'f'),
    'ClippingShape.sourceId': (92, 'u'),
    'StateMachineComponent.name': (138, 's'),
    'AnimationState.animationId': (149, 'u'),
    'StateTransition.stateToId': (151, 'u'),
    'LayoutComponent.clip': (196, 'b'),
    'Asset.name': (203, 's'),
    'FileAsset.assetId': (204, 'u'),
    'FileAssetContents.bytes': (212, 'y'),
    'Event.trigger': (395, 'u'),         # keyed only, through callbacks: never a value
    'AudioEvent.assetId': (408, 'u'),
}
# A field type's two bits in the header's table: what a runtime that does
# not know a property reads to skip its value.
TOC = {'u': 0, 'b': 0, 's': 1, 'y': 1, 'f': 2, 'c': 3}


def varuint(v):
    out = bytearray()
    while True:
        b = v & 0x7f
        v >>= 7
        if v:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


class Riv:
    def __init__(self, file_id=0):
        self.body = bytearray()
        self.used = {}
        self.file_id = file_id
        self.local = -1          # the id of the object last added to the artboard

    def obj(self, cls, props=(), counted=True):
        """Appends one object; props is [('Class.property', value)].

        Returns its id when it is one of the artboard's objects (a component
        or an interpolator), which is how others name it: its place among
        them, the artboard being 0. Animations, keyed objects, key frames and
        a state machine's parts are not (counted=False)."""
        self.body += varuint(TYPES[cls])
        for name, value in props:
            key, kind = PROPS[name]
            self.used[key] = kind
            self.body += varuint(key)
            if kind == 'u':
                self.body += varuint(int(value))
            elif kind == 'b':
                self.body += bytes([1 if value else 0])
            elif kind == 's':
                b = value.encode('utf8')
                self.body += varuint(len(b)) + b
            elif kind == 'y':
                self.body += varuint(len(value)) + value
            elif kind == 'f':
                self.body += struct.pack('<f', value)
            else:
                self.body += struct.pack('<I', value)
        self.body += varuint(0)
        if counted:
            self.local += 1
            return self.local

    def artboard(self, props):
        self.local = -1
        return self.obj('Artboard', props)

    def bytes(self):
        keys = sorted(self.used)
        head = bytearray(b'RIVE') + varuint(7) + varuint(0) + varuint(self.file_id)
        for k in keys:
            head += varuint(k)
        head += varuint(0)
        # Two bits a key, four keys to each 32-bit word (RuntimeHeader::read).
        for i in range(0, len(keys), 4):
            word = 0
            for j, k in enumerate(keys[i:i + 4]):
                word |= TOC[self.used[k]] << (2 * j)
            head += struct.pack('<I', word)
        return bytes(head) + bytes(self.body)
