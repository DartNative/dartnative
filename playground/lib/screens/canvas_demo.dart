/// Canvas demo screen.
///
/// Demonstrates two rendering tiers coexisting in the same scroll view:
///
/// • Tier 2 — Skia Graphite: [CanvasSurface] with a SkSL RuntimeEffect blob
///   shader.  All GPU draw calls route through `dart:ffi` → Skia C bridge →
///   CAMetalLayer.  No separate engine, no secondary isolate.
///
/// • Tier 1 — Core Animation: [Opacity] + [Container] mapped to UIView/CALayer
///   in the compositor render server at zero CPU cost.  These sit in the
///   same UIKit hierarchy as the Metal surface — no special bridging needed.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_skia/dartnative_skia.dart';
import 'home/demo_ui.dart';

// ── SkSL liquid glass shader ─────────────────────────────────────────────────

/// Same two circles as the gooey-blob example, but rendered with a liquid
/// glass refraction effect via SkSL RuntimeEffect.
///
/// Technique mirrors flutter_liquid_glass:
///   • smoothUnion SDF blends two circles with a gooey neck
///   • Central-difference normals (SkSL has no dFdx/dFdy in RuntimeEffect)
///   • getHeight() hemispheric lens profile (exact plugin formula)
///   • Manual refraction displacement (SkSL has no built-in refract())
///   • Chromatic aberration: R/G/B displaced by different amounts
///   • Rim lighting coloured by background luminance (plugin technique)
///   • Background sampled from `image` child shader (picsum photo)
///
/// Uniforms: [time (s), resolution.x (px), resolution.y (px)]
/// Children: [image] — pixel-space sampler
const _kLiquidGlassSksl = r'''
uniform float time;
uniform float2 resolution;
uniform float2 imageSize;
uniform shader image;

// ── SDFs ──────────────────────────────────────────────────────────────────────

float sdCircle(float2 p, float r) { return length(p) - r; }

// IQ polynomial smooth-union
float smoothUnion(float d1, float d2, float k) {
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / k;
}

float scene(float2 p, float2 c1, float2 c2, float r1, float r2, float k) {
    return smoothUnion(sdCircle(p - c1, r1), sdCircle(p - c2, r2), k);
}

// ── Hemispheric lens profile (exact flutter_liquid_glass formula) ─────────────

float getHeight(float sd, float thickness) {
    if (sd >= 0.0) return 0.0;
    float x = max(thickness + sd, 0.0);
    return sqrt(max(0.0, thickness * thickness - x * x));
}

// ── Sample background image (pixel-space coords, clamped to [0,1]) ────────────

float3 sampleBg(float2 pixelCoord, float2 sz) {
    // Map surface coords → image coords so the image covers the full surface.
    float2 imgCoord = pixelCoord / sz * imageSize;
    float2 clamped = clamp(imgCoord, float2(0.0), imageSize - float2(1.0));
    return float3(image.eval(clamped).rgb);
}

// ── Main ──────────────────────────────────────────────────────────────────────

half4 main(float2 fragCoord) {
    float2 sz = resolution;
    float2 p  = fragCoord - sz * 0.5;

    // Same oscillation as the gooey-blob example: circles breathe left/right.
    float  offset    = sin(time * 1.2) * 28.0;
    float  r1        = 68.0;
    float  r2        = 54.0;
    float  blendK    = 38.0;
    float2 c1        = float2(-48.0 - offset, 0.0);
    float2 c2        = float2( 48.0 + offset, 0.0);

    // Per-ball thickness proportional to radius (0.8 ratio → sphere-like dome).
    float thick1 = r1 * 1.8;   // 54.4 left ball (bigger → more sphere-like, smaller → more disc-like)
    float thick2 = r2 * 1.5;   // 43.2  right ball (bigger → more sphere-like,  smaller → more disc-like)

    // Blend thickness based on proximity to each ball centre.
    float d1 = sdCircle(p - c1, r1);
    float d2 = sdCircle(p - c2, r2);
    float blend = smoothstep(-20.0, 20.0, d1 - d2);
    float thickness = mix(thick1, thick2, blend);

    // Central-difference normal (SkSL RuntimeEffect has no dFdx/dFdy).
    float eps = 1.8;
    float sd  = scene(p, c1, c2, r1, r2, blendK);
    float2 grad = float2(
        scene(p + float2(eps, 0.0), c1, c2, r1, r2, blendK) -
        scene(p - float2(eps, 0.0), c1, c2, r1, r2, blendK),
        scene(p + float2(0.0, eps), c1, c2, r1, r2, blendK) -
        scene(p - float2(0.0, eps), c1, c2, r1, r2, blendK)
    ) * (0.5 / eps);

    // Lens height → normal z-component.
    // Quadratic ramp on ncos: tilts normals more aggressively at edges
    // for a convincing spherical curvature (linear looks flat/disc-like).
    float height = getHeight(sd, thickness);
    float nlin   = clamp((thickness + sd) / max(thickness, 0.001), 0.0, 1.0);
    float ncos   = nlin * nlin;  // quadratic → sphere-like curvature
    float3 N     = normalize(float3(grad * ncos,
                                    sqrt(max(0.0, 1.0 - ncos * ncos))));

    float  foreAlpha = 1.0 - smoothstep(-2.0, 1.0, sd);
    float3 bgPlain   = sampleBg(fragCoord, sz);

    // Outside the glass → plain background, skip all refraction work.
    if (foreAlpha < 0.005) {
        return half4(half3(bgPlain), 1.0);
    }

    // Fresnel: glass is more reflective at glancing angles.
    float fresnel = pow(1.0 - N.z, 3.0);

    // Manual refraction: displace fragCoord by N.xy * travel / IOR.
    // Cap travel so larger balls don't over-distort.
    float  travel = min((height + thickness * 3.5) / 1.45, 90.0);
    float2 disp   = N.xy * travel;

    // Chromatic aberration: red bends more, blue bends less.
    float  ca  = 0.10;
    float3 refracted = float3(
        sampleBg(fragCoord + disp * (1.0 + ca), sz).r,
        sampleBg(fragCoord + disp,               sz).g,
        sampleBg(fragCoord + disp * (1.0 - ca), sz).b
    );

    // Subtle tint: glass absorbs a tiny bit, cool blue cast.
    refracted *= float3(0.96, 0.98, 1.0);

    // Rim lighting coloured by background luminance (plugin technique).
    float normalizedH = height / max(thickness, 0.001);
    float shape    = clamp((1.0 - normalizedH) * 1.111, 0.0, 1.0);
    float thickFac = clamp((thickness - 5.0) * 0.5, 0.0, 1.0);
    float rimX     = sd / 1.2;
    float rim      = 1.0 / (1.0 + 1.8 * rimX * rimX);

    float2 lightDir = normalize(float2(0.5, -0.7));
    float  lDot     = max(0.0, dot(N.xy, lightDir));
    float  oppDot   = max(0.0, dot(N.xy, -lightDir));

    float  luma    = dot(refracted, float3(0.299, 0.587, 0.114));
    float3 hilight = luma > 0.001 ? min(refracted / luma, float3(1.0))
                                   : float3(1.0);
    float3 rimDir  = (hilight * 0.70) * (lDot + oppDot * 0.8) * 2.0;
    float3 rimAmb  =  hilight * 0.40;
    float3 lighting = (rimDir + rimAmb) * rim * shape * thickFac;

    // Primary specular highlight (top-left key light).
    float3 V    = float3(0.0, 0.0, 1.0);
    float3 L3   = normalize(float3(lightDir.x, lightDir.y, 0.8));
    float3 H    = normalize(L3 + V);
    float  spec1 = pow(max(dot(N, H), 0.0), 120.0) * 0.80;

    // Secondary specular (fill light from opposite side).
    float3 L3b   = normalize(float3(-0.4, 0.6, 0.7));
    float3 Hb    = normalize(L3b + V);
    float  spec2 = pow(max(dot(N, Hb), 0.0), 90.0) * 0.30;

    lighting += float3(spec1 + spec2);

    // Fresnel adds white reflection at edges.
    lighting += float3(fresnel * 0.45);

    // Fake environment reflection: bright spot in upper hemisphere
    // simulates sky reflecting on a sphere's top surface.
    float envDot = max(0.0, dot(N, normalize(float3(0.0, -0.8, 0.6))));
    float envRefl = pow(envDot, 6.0) * 0.25;
    lighting += float3(0.85, 0.92, 1.0) * envRefl;

    // Inner shadow: darken the centre slightly for depth.
    float innerShadow = smoothstep(0.0, 0.6, normalizedH) * 0.10;
    refracted *= 1.0 - innerShadow;

    float3 col = mix(bgPlain, refracted + lighting, foreAlpha);
    return half4(half3(col), 1.0);
}
''';

class LiquidGlassShaderPainter extends CustomPainter {
  final SkiaImage? image;

  LiquidGlassShaderPainter({this.image});

  // Compiled once — reused across all frames.
  RuntimeEffect? _effect;
  bool _effectCompiled = false;

  // Monotonically-increasing time in seconds (updated each paint call).
  double _time = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) {
      // No image yet — show placeholder.
      canvas.drawPaint(Paint(color: const Color(0xFFE8E0D3)));
      return;
    }

    if (!_effectCompiled) {
      _effectCompiled = true;
      _effect = RuntimeEffect.make(_kLiquidGlassSksl);
    }
    final effect = _effect;
    if (effect == null) {
      canvas.drawPaint(Paint(color: const Color(0xFFE8E0D3)));
      return;
    }

    final w = size.width;
    final h = size.height;

    final imageShader = img.asShader();
    try {
      final shader = effect.makeShaderWithChildren(
        [_time, w, h, img.width.toDouble(), img.height.toDouble()],
        [imageShader],
      );
      canvas.drawPaint(Paint()..shader = shader);
      shader.dispose();
    } finally {
      imageShader.dispose();
    }

    _time += 1.0 / 60.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Gooey blob painter (saveLayer + blur + blend modes) ──────────────────────

/// Gooey metaball effect using the saveLayer + blur + colorDodge + colorBurn
/// technique — no SkSL required.  Adapted from:
/// https://dev.to/get_pieces/flutter-gooey-blobs-4b3o
///
/// Technique:
///   1. Save a blur layer (Gaussian sigma ≈ 12 px)
///   2. Draw two black circles inside the layer
///   3. Restore — blur melts the circles together at overlap
///   4. colorDodge rect: sharpens blurred outlines
///   5. colorBurn rect:  makes the blurred interior solid black
///   6. screen rect:     overlays a radial gradient for colour
class GooeyBlobPainter extends CustomPainter {
  double _time = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bounds = Rect.fromLTWH(0, 0, w, h);

    // Fill white first — blend modes (colorDodge, colorBurn) require an opaque
    // white base.  The Metal framebuffer is cleared to transparent-black by
    // CanvasSurface; setting backgroundColor only paints the UIKit view *under*
    // the Metal layer, which doesn't affect blend-mode math inside the framebuffer.
    canvas.drawPaint(Paint(color: const Color(0xFFFFFFFF)));

    // ── 1. Blurred layer ──────────────────────────────────────────────────
    final blurLayerPaint = Paint()
      ..color = const Color(0xFF808080)
      ..imageFilter = const ImageFilter.blur(sigmaX: 12, sigmaY: 12);
    canvas.saveLayer(bounds, blurLayerPaint);

    // Two black circles that slowly oscillate left/right.
    const baseRadius1 = 70.0;
    const baseRadius2 = 55.0;
    final offset = math.sin(_time * 1.2) * 28.0;
    final circlePaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(
      Offset(w / 2 - 48 - offset, h / 2),
      baseRadius1,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(w / 2 + 48 + offset, h / 2),
      baseRadius2,
      circlePaint,
    );
    canvas.restore();

    // ── 2. colorDodge: sharpens the blurred circle outlines ───────────────
    canvas.drawRect(
      bounds,
      Paint()
        ..color = const Color(0xFF808080)
        ..blendMode = BlendMode.colorDodge,
    );

    // ── 3. colorBurn: fills the blurred interiors solid ───────────────────
    canvas.drawRect(
      bounds,
      Paint()
        ..color = const Color(0xFF000000)
        ..blendMode = BlendMode.colorBurn,
    );

    // ── 4. Radial gradient via screen blend — adds colour ─────────────────
    final gradient = const CanvasRadialGradient(
      radius: 0.8,
      colors: [Color(0xFFFFD700), Color(0xFFFF69B4)],
    ).createShader(bounds);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.screen,
    );
    gradient.dispose();

    _time += 1.0 / 60.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Screen widget ─────────────────────────────────────────────────────────────

class CanvasDemo extends StatefulWidget {
  const CanvasDemo({super.key});

  @override
  State<CanvasDemo> createState() => _CanvasDemoState();
}

class _CanvasDemoState extends State<CanvasDemo> {
  // ── Core Animation demo state ─────────────────────────────────────────────

  bool _visible = true;
  double _scale = 1.0;
  Timer? _coreAnimTimer;

  // ── Frosted glass image ───────────────────────────────────────────────────

  SkiaImage? _bgImage;

  // Persist painter across rebuilds so _time isn't reset by setState.
  final _dissolvePainter = TextParticleEffect(text: 'SKIA');

  @override
  void initState() {
    super.initState();
    // Toggle the Core Animation widgets every 1.6 s so observers can see
    // UIKit's implicit animations running alongside the Skia surface.
    _coreAnimTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      // Dart timers keep firing in background; each toggle animates and pays
      // a full relayout. Skip while backgrounded (checked per tick — cheaper
      // than observer wiring for a demo).
      if (!WidgetsBinding.instance.isForeground) return;
      setState(() {
        _visible = !_visible;
        _scale = _visible ? 1.0 : 0.6;
      });
    });
    // Load the background image for the frosted-glass shader asynchronously.
    _loadBgImage();
  }

  Future<void> _loadBgImage() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://picsum.photos/seed/frosted/400/260'),
      );
      request.followRedirects = true;
      request.maxRedirects = 5;
      final response = await request.close();
      dnLog(
        '[canvas_demo] image fetch status=${response.statusCode} '
        'contentLength=${response.contentLength}',
      );
      final chunks = <int>[];
      await for (final chunk in response) {
        chunks.addAll(chunk);
      }
      client.close();
      dnLog('[canvas_demo] image bytes downloaded: ${chunks.length}');
      final image = loadSkiaImageFromBytes(Uint8List.fromList(chunks));
      dnLog(
        '[canvas_demo] loadSkiaImageFromBytes → '
        '${image == null ? "null (decode failed)" : "${image.width}×${image.height}"}',
      );
      if (image != null) {
        if (!mounted) {
          // Widget left the tree while the network/decode was in flight —
          // drop the image so we don't leak the native handle.
          image.dispose();
          return;
        }
        setState(() => _bgImage = image);
      }
    } catch (e, st) {
      dnLog('[canvas_demo] _loadBgImage error: $e\n$st');
    }
  }

  @override
  void dispose() {
    _coreAnimTimer?.cancel();
    _bgImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Canvas Surface',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBarBg,
      ),
      body: Container(
        color: kHomeBg,
        child: ListView(
          children: [
            SizedBox(
                // Bar clearance is AUTOMATIC (extendBodyBehindAppBar +
                // null-padding scrollable -> Scaffold applies safeTop+toolbar);
                // keep only a small gap.
                height: isIOS26 ? 8 : 24),

            // ── Section header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'GPU-accelerated canvas',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                Platform.isAndroid
                    ? 'CanvasSurface embeds a Skia Graphite Vulkan SurfaceView '
                        'inside the native view hierarchy. The CustomPainter '
                        'runs in the main Dart isolate over dart:ffi — no '
                        'separate engine, no secondary isolate.'
                    : 'CanvasSurface embeds a Skia Graphite CAMetalLayer inside '
                        'the UIKit hierarchy. The CustomPainter runs in the '
                        'main Dart isolate over dart:ffi — no separate '
                        'engine, no secondary isolate.',
                style: TextStyle(color: kTextSecondary, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),

            // ── Tier 2: Skia Surface — Gooey Blobs ─────────────────────────
            _SectionLabel(
              label: 'TIER 2 — SKIA GRAPHITE (GPU)',
              subtitle: 'saveLayer + blur + colorDodge/colorBurn blend modes',
            ),
            const SizedBox(height: 8),
            CanvasSurface(
              height: 220,
              backgroundColor: const Color(0xFFFFFFFF),
              painter: GooeyBlobPainter(),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Gooey metaball using saveLayer+blur, colorDodge, colorBurn, '
                'and a screen-blend radial gradient. No SkSL — pure canvas ops.',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 28),

            // ── Tier 2: Skia Surface — SkSL liquid glass ──────────────────
            _SectionLabel(
              label: 'TIER 2 — SKIA GRAPHITE (GPU)',
              subtitle: 'SkSL RuntimeEffect · liquid glass SDF shader',
            ),
            const SizedBox(height: 8),
            if (_bgImage != null)
              CanvasSurface(
                height: 280,
                backgroundColor: const Color(0xFFE6E0D6),
                painter: LiquidGlassShaderPainter(image: _bgImage),
              )
            else
              Container(
                height: 280,
                color: const Color(0xFFE6E0D6),
                child: Center(
                  child: Text(
                    'Loading image…',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Two glass pills merge with a refractive gooey neck — SDF '
                'smooth-min, UV displacement from surface normals bends the '
                'grid background like real glass. Pure GPU via RuntimeEffect.',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 28),

            // ── Tier 2a: CPU particle dissolve ─────────────────────────
            _SectionLabel(
              label: 'TIER 2 — SKIA GRAPHITE (GPU)',
              subtitle: 'CPU particle system · drawCircle · staggered dissolve',
            ),
            const SizedBox(height: 8),
            CanvasSurface(
              height: 260,
              backgroundColor: const Color(0xFF0A0A1A),
              painter: _dissolvePainter,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Same offscreen "SKIA" texture sampled via readPixels — '
                '~2500 particles drawn with canvas.drawCircle(). Each dot '
                'scatters, rises, shrinks, and fades with staggered timing.',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 28),

            // ── Tier 1: Core Animation ──────────────────────────────────────
            _SectionLabel(
              label: Platform.isAndroid
                  ? 'TIER 1 — NATIVE VIEWS (HWUI)'
                  : 'TIER 1 — CORE ANIMATION (compositor)',
              subtitle: Platform.isAndroid
                  ? 'Opacity + Container · native View/RenderNode'
                  : 'Opacity + Container · native UIView/CALayer',
            ),
            const SizedBox(height: 16),
            Center(
              child: Opacity(
                opacity: _visible ? 1.0 : 0.15,
                child: Container(
                  width: 120 * _scale,
                  height: 120 * _scale,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B21A8), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'CA',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                Platform.isAndroid
                    ? 'Tier 1 widgets (Opacity + Container) map to native '
                        'View/RenderNode — zero Skia overhead. State changes '
                        'drive HWUI property updates natively. Tier 1 and '
                        'Tier 2 composite on the same GPU pass.'
                    : 'Tier 1 widgets (Opacity + Container) map to native '
                        'UIView/CALayer — zero Skia overhead. State changes '
                        'drive Core Animation property updates natively. Tier '
                        '1 and Tier 2 composite on the same GPU pass.',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // ── Metadata ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Surface details',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _InfoRow(label: 'Tier 2 renderer', value: 'Skia Graphite'),
            _InfoRow(
              label: 'GPU backend',
              value: Platform.isAndroid
                  ? 'Vulkan (SurfaceView)'
                  : 'Metal (CAMetalLayer)',
            ),
            _InfoRow(
              label: 'Binary (bare tier)',
              value: Platform.isAndroid ? '4.2 MB arm64' : '7.8 MB arm64',
            ),
            const _InfoRow(label: 'Frame driver', value: 'Display vsync (up to 120 Hz)'),
            const _InfoRow(label: 'Isolate', value: 'Main (no secondary)'),
            _InfoRow(
              label: 'Tier 1 renderer',
              value:
                  Platform.isAndroid ? 'HWUI (RenderNode)' : 'Core Animation',
            ),
            _InfoRow(
              label: 'Tier 1 cost',
              value: Platform.isAndroid
                  ? '0 CPU — RenderThread'
                  : '0 CPU — render server',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── _SectionLabel ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String subtitle;
  const _SectionLabel({required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: kTextTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── _InfoRow ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: kRowBg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(color: kTextPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
