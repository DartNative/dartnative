/// Image widget demo.
///
/// Showcases dartnative's Image.network() backed by native UIImageView,
/// cache policies, precacheImage, and global ImageCache management.
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

// ── Tiny test image ───────────────────────────────────────────────────────────

/// Builds a minimal solid-color PNG of [w]×[h] (8-bit RGB, no interlace).
/// Uses a stored (uncompressed) deflate block so no zlib dependency is needed.
Uint8List _solidColorPng(int w, int h, {int r = 255, int g = 0, int b = 0}) {
  // ── CRC32 lookup table ──────────────────────────────────────────────────
  final crcT = Uint32List(256);
  for (int i = 0; i < 256; i++) {
    int c = i;
    for (int j = 0; j < 8; j++) {
      if ((c & 1) != 0) {
        c = 0xEDB88320 ^ (c >> 1);
      } else {
        c >>= 1;
      }
    }
    crcT[i] = c;
  }

  int crc32(Uint8List d) {
    int c = 0xFFFFFFFF;
    for (int i = 0; i < d.length; i++) c = crcT[(c ^ d[i]) & 0xFF] ^ (c >> 8);
    return c ^ 0xFFFFFFFF;
  }

  // ── Adler-32 (zlib checksum) ────────────────────────────────────────────
  int adler32(Uint8List d) {
    int a = 1, b = 0;
    for (int i = 0; i < d.length; i++) {
      a = (a + d[i]) % 65521;
      b = (b + a) % 65521;
    }
    return (b << 16) | a;
  }

  // ── Raw pixel rows ──────────────────────────────────────────────────────
  final rowBytes = 1 + 3 * w; // filter byte + RGB triplets
  final rawLen = h * rowBytes;
  final raw = Uint8List(rawLen);
  for (int y = 0; y < h; y++) {
    final ro = y * rowBytes;
    raw[ro] = 0; // filter: None
    for (int x = 0; x < w; x++) {
      final px = ro + 1 + x * 3;
      raw[px] = r;
      raw[px + 1] = g;
      raw[px + 2] = b;
    }
  }

  // ── Uncompressed deflate (stored block) ─────────────────────────────────
  //    BFINAL=1, BTYPE=00  →  0x01
  //    LEN (2 bytes LE)    →  rawLen & 0xFFFF
  //    NLEN (2 bytes LE)   →  (~rawLen) & 0xFFFF  (one's complement)
  //    Raw data follows
  final deflateLen = 5 + rawLen;
  final deflate = Uint8List(deflateLen);
  deflate[0] = 0x01;
  deflate[1] = rawLen & 0xFF;
  deflate[2] = (rawLen >> 8) & 0xFF;
  deflate[3] = (rawLen ^ 0xFFFF) & 0xFF;
  deflate[4] = ((rawLen ^ 0xFFFF) >> 8) & 0xFF;
  deflate.setRange(5, deflateLen, raw);

  // ── zlib wrapper ────────────────────────────────────────────────────────
  final a32 = adler32(raw);
  final zlibLen = 2 + deflateLen + 4;
  final zlibStream = Uint8List(zlibLen);
  zlibStream[0] = 0x78; // CMF (deflate, window=2048)
  zlibStream[1] = 0x01; // FLG (FCHECK=1)
  zlibStream.setRange(2, 2 + deflateLen, deflate);
  zlibStream[zlibLen - 4] = (a32 >> 24) & 0xFF;
  zlibStream[zlibLen - 3] = (a32 >> 16) & 0xFF;
  zlibStream[zlibLen - 2] = (a32 >> 8) & 0xFF;
  zlibStream[zlibLen - 1] = a32 & 0xFF;

  // ── PNG chunk helper ────────────────────────────────────────────────────
  void addChunk(List<int> dst, String type, Uint8List data) {
    final t = Uint8List.fromList(type.codeUnits);
    final crcData = Uint8List(t.length + data.length);
    crcData.setRange(0, t.length, t);
    crcData.setRange(t.length, t.length + data.length, data);
    final crc = crc32(crcData);
    // Length (4 bytes big-endian)
    dst.add((data.length >> 24) & 0xFF);
    dst.add((data.length >> 16) & 0xFF);
    dst.add((data.length >> 8) & 0xFF);
    dst.add(data.length & 0xFF);
    // Type
    dst.addAll(t);
    // Data
    dst.addAll(data);
    // CRC
    dst.add((crc >> 24) & 0xFF);
    dst.add((crc >> 16) & 0xFF);
    dst.add((crc >> 8) & 0xFF);
    dst.add(crc & 0xFF);
  }

  // ── Assemble PNG ────────────────────────────────────────────────────────
  final ihdr = Uint8List(13);
  // width (big-endian)
  ihdr[0] = (w >> 24) & 0xFF;
  ihdr[1] = (w >> 16) & 0xFF;
  ihdr[2] = (w >> 8) & 0xFF;
  ihdr[3] = w & 0xFF;
  // height (big-endian)
  ihdr[4] = (h >> 24) & 0xFF;
  ihdr[5] = (h >> 16) & 0xFF;
  ihdr[6] = (h >> 8) & 0xFF;
  ihdr[7] = h & 0xFF;
  ihdr[8] = 8; // bit depth
  ihdr[9] = 2; // color type: RGB
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace

  final result = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  ];
  addChunk(result, 'IHDR', ihdr);
  addChunk(result, 'IDAT', zlibStream);
  addChunk(result, 'IEND', Uint8List(0));

  return Uint8List.fromList(result);
}

/// A 10×10 solid-red PNG, built programmatically for Image.memory testing.
final Uint8List _redPixelPng = _solidColorPng(10, 10);

// ── Sample URLs ───────────────────────────────────────────────────────────────

const _sampleImages = [
  'https://picsum.photos/id/10/600/400',
  'https://picsum.photos/id/20/600/400',
  'https://picsum.photos/id/30/600/400',
  'https://picsum.photos/id/40/600/400',
  'https://picsum.photos/id/50/600/400',
  'https://picsum.photos/id/60/600/400',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class ImageDemo extends StatefulWidget {
  const ImageDemo({super.key});

  @override
  State<ImageDemo> createState() => _ImageDemoState();
}

class _ImageDemoState extends State<ImageDemo> {
  ImageCachePolicy _policy = ImageCachePolicy.standard;
  String _statusMessage = '';
  int _fadeInKey = 0;
  int _placeholderKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Image & Caching',
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
          padding: EdgeInsets.fromLTRB(16,
              isIOS26 ? MediaQuery.paddingOf(context).top + 64 : 16, 16, 16),
          children: [
            // ── Section: Cache policy selector ──────────────────────────────
            _SectionHeader('Cache Policy'),
            const SizedBox(height: 8),
            _PolicySelector(
              selected: _policy,
              onChanged: (p) => setState(() => _policy = p),
            ),
            const SizedBox(height: 8),
            Text(
              _policyDescription(_policy),
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ── Section: Image grid ─────────────────────────────────────────
            _SectionHeader('Image.network() with selected policy'),
            const SizedBox(height: 12),
            ..._buildImageCards(),
            const SizedBox(height: 24),

            // ── Section: BoxFit comparison ──────────────────────────────────
            _SectionHeader('BoxFit Comparison'),
            const SizedBox(height: 12),
            _BoxFitComparison(),
            const SizedBox(height: 24),

            // ── Section: Image sources ──────────────────────────────────────
            _SectionHeader('Image Sources'),
            const SizedBox(height: 12),
            _ImageSourcesDemo(),
            const SizedBox(height: 24),

            // ── Section: Fade-in animation ──────────────────────────────────
            Row(
              children: [
                const Expanded(child: _SectionHeader('Fade-in Animation')),
                GestureDetector(
                  onTap: () => setState(() => _fadeInKey++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FadeInComparison(revision: _fadeInKey),
            const SizedBox(height: 24),

            // ── Section: Placeholder & errorWidget ──────────────────────────
            Row(
              children: [
                const Expanded(
                  child: _SectionHeader('Placeholder & Error Widget'),
                ),
                GestureDetector(
                  onTap: () => setState(() => _placeholderKey++),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Refresh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PlaceholderErrorDemo(revision: _placeholderKey),
            const SizedBox(height: 24),

            // ── Section: Cache management ───────────────────────────────────
            _SectionHeader('Cache Management'),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'precacheImage (next 3 URLs)',
              onTap: _precacheNextImages,
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'ImageCache.clearMemory()',
              onTap: () {
                ImageCache.clearMemory();
                setState(() => _statusMessage = 'Memory cache cleared');
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'ImageCache.clearDisk()',
              onTap: () {
                ImageCache.clearDisk();
                setState(() => _statusMessage = 'Disk cache cleared');
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'ImageCache.clearAll()',
              onTap: () {
                ImageCache.clearAll();
                setState(() => _statusMessage = 'All caches cleared');
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Evict first image',
              onTap: () {
                ImageCache.evict(NetworkImage(_sampleImages[0]));
                setState(
                  () => _statusMessage =
                      'Evicted: ${_sampleImages[0].split('/').last}',
                );
              },
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C3A1C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Color(0xFF4CD964),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Section: Configure cache ────────────────────────────────────
            _SectionHeader('Configure Cache Sizes'),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'Set 50 MB mem / 100 MB disk',
              onTap: () {
                ImageCache.configure(
                  maxMemoryBytes: 50 * 1024 * 1024,
                  maxDiskBytes: 100 * 1024 * 1024,
                );
                setState(
                  () => _statusMessage = 'Configured: 50 MB mem, 100 MB disk',
                );
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Set 200 MB mem / 500 MB disk',
              onTap: () {
                ImageCache.configure(
                  maxMemoryBytes: 200 * 1024 * 1024,
                  maxDiskBytes: 500 * 1024 * 1024,
                );
                setState(
                  () => _statusMessage = 'Configured: 200 MB mem, 500 MB disk',
                );
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Reset to defaults (100 MB / 200 MB)',
              onTap: () {
                ImageCache.configure(); // defaults
                setState(() => _statusMessage = 'Cache reset to defaults');
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildImageCards() {
    return [
      for (int i = 0; i < _sampleImages.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: _ImageCard(url: _sampleImages[i], policy: _policy),
              ),
              const SizedBox(width: 12),
              if (i + 1 < _sampleImages.length)
                Expanded(
                  child: _ImageCard(
                    url: _sampleImages[i + 1],
                    policy: _policy,
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
    ];
  }

  void _precacheNextImages() {
    // Precache a set of URLs that haven't been displayed yet.
    const precacheUrls = [
      'https://picsum.photos/id/100/600/400',
      'https://picsum.photos/id/110/600/400',
      'https://picsum.photos/id/120/600/400',
    ];
    for (final url in precacheUrls) {
      precacheImage(NetworkImage(url), cachePolicy: _policy);
    }
    setState(() => _statusMessage = 'Pre-caching 3 images (fire-and-forget)');
  }

  String _policyDescription(ImageCachePolicy policy) {
    return switch (policy) {
      ImageCachePolicy.standard =>
        'standard — Cached in both memory (NSCache) and on disk (URLCache). '
            'Best for most images.',
      ImageCachePolicy.memoryOnly =>
        'memoryOnly — Cached in memory only. Not persisted to disk. '
            'Use for sensitive or ephemeral content.',
      ImageCachePolicy.none =>
        'none — No caching. Always re-downloads from the network. '
            'Use for live feeds or one-time signed URLs.',
    };
  }
}

// ── Image card ────────────────────────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.url, required this.policy});

  final String url;
  final ImageCachePolicy policy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kTileBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(
            url,
            height: 120,
            fit: BoxFit.cover,
            cachePolicy: policy,
            placeholder: Shimmer.fromColors(
              baseColor: kRowBg,
              highlightColor: const Color(0xFF424242),
              child: Container(color: kRowBg),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'picsum #${url.split('/id/')[1].split('/')[0]}',
              style: TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BoxFit comparison ─────────────────────────────────────────────────────────

class _BoxFitComparison extends StatelessWidget {
  const _BoxFitComparison();

  @override
  Widget build(BuildContext context) {
    final url = _sampleImages[0];
    final fits = [
      ('cover', BoxFit.cover),
      ('contain', BoxFit.contain),
      ('fill', BoxFit.fill),
      ('fitWidth', BoxFit.fitWidth),
    ];

    return Column(
      children: [
        for (final (label, fit) in fits)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'BoxFit.$label',
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: kRowBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kChipBg),
                  ),
                  child: Image.network(url, height: 150, fit: fit),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Image sources demo ────────────────────────────────────────────────────────

class _ImageSourcesDemo extends StatelessWidget {
  const _ImageSourcesDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Asset image
        Text(
          Platform.isIOS
              ? 'Image.asset("assets/apple-logo.png")'
              : 'Image.asset("assets/google-logo.png")',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 100,
          // The logos are white — a fixed dark swatch keeps them visible in
          // both light and dark theme.
          color: const Color(0xFF2C2C2E),
          child: Center(
            child: Image.asset(
              Platform.isIOS
                  ? 'assets/apple-logo.png'
                  : 'assets/google-logo.png',
              width: 80,
              height: 80,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Memory image (programmatically-built 10×10 red PNG)
        Text(
          'Image.memory(bytes) — 10×10 red PNG',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 100,
          color: kRowBg,
          child: Center(
            child: Image.memory(
              _redPixelPng,
              width: 10,
              height: 10,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Fade-in comparison ────────────────────────────────────────────────────────

class _FadeInComparison extends StatelessWidget {
  const _FadeInComparison({this.revision = 0});

  final int revision;

  @override
  Widget build(BuildContext context) {
    // Use cache-policy .none so every render triggers a fresh download,
    // making the fade-in visible even after the first load.
    // Append ?v=revision as cache-buster so the native side sees a new URL
    // on each refresh tap and re-downloads the image.
    final durations = [
      ('No fade', Duration.zero),
      ('300 ms', Duration(milliseconds: 300)),
      ('800 ms', Duration(milliseconds: 800)),
    ];
    return Column(
      children: [
        for (final (label, dur) in durations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Image.network(
                  'https://picsum.photos/id/70/600/300?v=$revision',
                  height: 120,
                  fit: BoxFit.cover,
                  fadeInDuration: dur,
                  cachePolicy: ImageCachePolicy.none,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Placeholder & error demo ──────────────────────────────────────────────────

class _PlaceholderErrorDemo extends StatelessWidget {
  const _PlaceholderErrorDemo({this.revision = 0});

  final int revision;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // With placeholder (spinner while loading)
        Text(
          'With placeholder (spinner while loading)',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Image.network(
          'https://picsum.photos/id/80/600/300?v=$revision',
          height: 150,
          fit: BoxFit.cover,
          cachePolicy: ImageCachePolicy.none,
          placeholder: Container(
            height: 150,
            color: kChipBg,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
        const SizedBox(height: 16),

        // With errorWidget (broken URL)
        Text(
          'With errorWidget (broken URL)',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Image.network(
          'https://invalid.example.test/no-image.jpg',
          height: 150,
          fit: BoxFit.cover,
          placeholder: Container(
            height: 150,
            color: kChipBg,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: Container(
            height: 150,
            color: const Color(0xFFFF3B30),
            child: Center(
              child: Text(
                'Error',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Policy selector ───────────────────────────────────────────────────────────

class _PolicySelector extends StatelessWidget {
  const _PolicySelector({required this.selected, required this.onChanged});

  final ImageCachePolicy selected;
  final void Function(ImageCachePolicy) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final policy in ImageCachePolicy.values) ...[
          if (policy != ImageCachePolicy.values.first) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(policy),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == policy ? const Color(0xFF0A84FF) : kTileBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    policy.name,
                    style: TextStyle(
                      color: selected == policy
                          ? const Color(0xFFFFFFFF)
                          : kTextSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: kTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kTileBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 15),
        ),
      ),
    );
  }
}
