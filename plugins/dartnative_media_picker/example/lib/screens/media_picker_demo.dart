/// Media picker demo — standalone example for dartnative_media_picker.
///
/// Lets the user pick images, videos, or both via
/// the native gallery and shows the returned file metadata.
library;

import 'package:dartnative/dartnative.dart'
    hide showMediaPicker, MediaPickerType, MediaFile;
import 'package:dartnative_media_picker/dartnative_media_picker.dart';

class MediaPickerDemo extends StatefulWidget {
  const MediaPickerDemo({super.key});

  @override
  State<MediaPickerDemo> createState() => _MediaPickerDemoState();
}

class _MediaPickerDemoState extends State<MediaPickerDemo> {
  String _pickedMedia = 'No media picked yet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Media Picker Demo',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      // The Scaffold's own colour is what the navigator paints behind a
      // push; a colour set on the body alone leaves a white frame.
      backgroundColor: const Color(0xFF000000),
      body: SizedBox(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Pick images and videos from the native gallery picker.',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
            const SizedBox(height: 16),
            // The other layer: read the library and draw the grid yourself.
            Button(
              title: 'Photo library (gallery layer)',
              variant: ButtonVariant.filled,
              onPressed: () => Navigator.pushNamed(context, '/gallery'),
            ),
            const SizedBox(height: 16),
            Button(
              title: 'Pick Image',
              variant: ButtonVariant.tinted,
              onPressed: () async {
                final files = await showMediaPicker(
                  type: MediaPickerType.images,
                );
                setState(() {
                  _pickedMedia = files.isEmpty
                      ? 'Cancelled'
                      : files.map((f) => '${f.type}: ${f.name}').join('\n');
                });
              },
            ),
            const SizedBox(height: 8),
            Button(
              title: 'Pick Video',
              variant: ButtonVariant.tinted,
              onPressed: () async {
                final files = await showMediaPicker(
                  type: MediaPickerType.videos,
                );
                setState(() {
                  _pickedMedia = files.isEmpty
                      ? 'Cancelled'
                      : files.map((f) => '${f.type}: ${f.name}').join('\n');
                });
              },
            ),
            const SizedBox(height: 8),
            Button(
              title: 'Pick Multiple (up to 3)',
              variant: ButtonVariant.tinted,
              onPressed: () async {
                final files = await showMediaPicker(
                  type: MediaPickerType.imagesAndVideos,
                  maxSelection: 3,
                );
                setState(() {
                  _pickedMedia = files.isEmpty
                      ? 'Cancelled'
                      : '${files.length} file(s):\n${files.map((f) => '${f.type}: ${f.name}').join('\n')}';
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              _pickedMedia,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
