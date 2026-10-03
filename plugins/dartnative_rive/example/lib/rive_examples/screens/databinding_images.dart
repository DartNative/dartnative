// Ported from rive-flutter's example/lib/examples/databinding_images.dart.
// Copyright (c) 2020 Rive, MIT; see THIRD_PARTY_NOTICES.
//
// Kept as close to the original as the API allows. The diff:
//
//   FileLoader.fromAsset + RiveWidgetBuilder  →  Rive(asset:, controller:)
//   onLoaded: viewModelInstance.image('…')!   →  the same lookup in initState
//   rootBundle.load(path)                     →  loadAssetBytes(path)   (sync)
//   RiveExampleApp.getCurrentFactory          →  RiveFactory
//   ElevatedButton                            →  the example's pill button
//   (index 0 highlighted, the view left empty →  the highlighted image is
//   until a tap)                                  shown once the images are
//                                                 read: ball_elements.riv
//                                                 carries no image of its own
//   _buildImageCarousel() at the page's foot  →  the same strip, its black
//                                                run to the screen's edge and
//                                                the thumbnails lifted clear
//                                                of the home indicator
//                                                (SafeArea). width: infinity
//                                                is what Flutter does anyway;
//                                                DartNative's SafeArea does
//                                                not pass the list's full
//                                                width up (framework gap,
//                                                reported)
//
// Their RiveLoading/RiveFailed branches go: the file loads on the platform
// side and the view shows as soon as it has. The property lookup moves from
// onLoaded to initState because ours never waits on the file; a value set
// before the view mounts is applied when it does.
//
// See: https://rive.app/docs/runtimes/data-binding

import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_rive/dartnative_rive.dart';

import '../elevated_pill.dart';
import '../theme.dart';

Widget buildDataBindingImages(BuildContext context) =>
    const ExampleDataBindingImages();

/// Example using Rive data binding images at runtime.
///
/// See: https://rive.app/docs/runtimes/data-binding
class ExampleDataBindingImages extends StatefulWidget {
  const ExampleDataBindingImages({super.key});

  @override
  State<ExampleDataBindingImages> createState() =>
      _ExampleDataBindingImagesState();
}

class _ExampleDataBindingImagesState extends State<ExampleDataBindingImages> {
  final controller = RiveController();
  late ViewModelInstance viewModelInstance;
  late ViewModelInstanceAssetImage imageProperty;

  int selectedImageIndex = 0;
  final Map<String, Uint8List> _imageCache = {};

  final List<String> images = [
    'Basketball.webp',
    'Beach ball.webp',
    'Coffee.webp',
    'Cola.webp',
    'Cookie.webp',
    'Donut.webp',
    'Earth.webp',
    'Egg.webp',
    'Football.webp',
    'Paper.webp',
    'Pizza.webp',
    'Vinyl record.webp',
  ];

  @override
  void initState() {
    super.initState();
    viewModelInstance = controller.viewModelInstance;
    imageProperty = viewModelInstance.image('ball_image');
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    for (String imageName in images) {
      try {
        final bytes = await loadBundleAsset(imageName);
        _imageCache[imageName] = bytes;
      } catch (e) {
        debugPrint('Failed to load image: $imageName - $e');
      }
    }
    if (mounted) {
      setState(() {});
      await _swapImage(selectedImageIndex);
    }
  }

  Future<Uint8List> loadBundleAsset(String name) async {
    final data = loadAssetBytes('assets/images/$name');
    if (data == null) throw StateError('no asset assets/images/$name');
    return data;
  }

  Future<void> _swapImage(int index) async {
    if (index >= 0 && index < images.length) {
      final imageName = images[index];
      final cachedBytes = _imageCache[imageName];

      if (cachedBytes != null) {
        final renderImage = await RiveFactory.decodeImage(cachedBytes);
        if (renderImage != null) {
          imageProperty.value = renderImage;
          setState(() {
            selectedImageIndex = index;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    imageProperty.dispose();
    super.dispose();
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 100,
      decoration: const BoxDecoration(color: Colors.black),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedImageIndex;
          final imageName = images[index];
          final cachedBytes = _imageCache[imageName];

          return GestureDetector(
            onTap: () => _swapImage(index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[300],
                  width: isSelected ? 1.5 : 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: cachedBytes != null
                    ? Image.memory(
                        cachedBytes,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(child: Text('Tap the image!!', style: _text)),
        ),
        Expanded(
          child: Rive(
            asset: 'assets/rive/ball_elements.riv',
            controller: controller,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedPill(
            onPressed: () {
              imageProperty.value = null;
              setState(() {});
            },
            child: const Text('Clear image'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Select an image', style: _text),
        ),
        Container(
          width: double.infinity,
          color: Colors.black,
          child: SafeArea(top: false, child: _buildImageCarousel()),
        ),
      ],
    );
  }
}

/// Upstream's Text on its Material theme: body text, 14 logical pixels.
const _text = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 14,
  fontFamily: monoFont,
);
