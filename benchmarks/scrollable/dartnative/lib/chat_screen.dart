/// The Chat screen: Legend List's chat example (ChatExample.tsx), with its
/// messages, bubbles and attachment cards, plus two kinds of message added.
/// After every fourth message comes a photo with a bubble's rounded corners
/// and no padding, at one of five aspect ratios; after every third, a
/// sticker, a looping Lottie animation shown without a bubble, as messaging
/// apps show them. Both sit on the sender's side. A message with an
/// attachment card takes the bubble's whole width and the card fills it, as
/// a link preview does in a messaging app; the example draws the card 220
/// points wide whatever the bubble's width. The messages are the ones the
/// example's own generator makes (`tool/extract_chat.sh` writes them to
/// `assets/chat.json`); the stickers are six from each of four packs of the
/// DartNative playground's sticker keyboard. The thread opens at its newest
/// message, at the bottom, and the benchmark scrolls up through its
/// history. The bar's Scroll button animates to the next message of
/// [kChatScrollTargets].
///
/// The stickers play through the platform's Lottie library (lottie-android
/// and lottie-ios, the ones React Native's lottie-react-native uses), not
/// through the plugin's frames renderer (`RenderCache.raster`): the
/// benchmark compares the lists, so every app uses the same renderer.
library;
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_lottie/dartnative_lottie.dart';

import 'item_card.dart' show headerBackground;

/// The messages the bar's Scroll button goes to, in turn, the same in every
/// app, by number (0 is the oldest, 999 the newest). Each press scrolls,
/// animated, until that message's top is at the top of the list. The
/// first, to a message a few rows from the newest one where the thread
/// opens, lands among rows every list has measured, so it shows where a
/// message's top sits when it is at the top. Every scroll goes up the
/// history, away from where the thread opens: the one to message 598 moves
/// two messages, the others hundreds, past messages no list has measured,
/// the oldest last.
const kChatScrollTargets = [996, 600, 598, 300, 0];

/// A sticker follows every this many messages, as on the React Native
/// screen (STICKER_EVERY).
const int _stickerEvery = 3;

/// A sticker's side, in points, as a messaging app shows one.
const double _stickerSide = 160;

/// A photo follows every this many messages (PHOTO_EVERY), 240 points
/// wide; its height follows its shape.
const int _photoEvery = 4;
const double _photoWidth = 240;

/// The photos' shapes, in turn: the pixel size asked of the image service
/// (720 wide, three pixels a point) and the height shown, in points: 4:3,
/// 3:4, 1:1, 16:9 and 9:16.
const List<(int, int, double)> _photoShapes = [
  (720, 540, 180),
  (720, 960, 320),
  (720, 720, 240),
  (720, 405, 135),
  (720, 1280, 427),
];

/// The photos: 24 images from picsum.photos, picked by id, the same in
/// every app.
const int _firstPhotoId = 10;
const int _photoCount = 24;

/// The light fill a chat shows while a photo loads.
const Color _photoFill = Color(0xFFE5E7EB);

/// The sticker files: six from each of four packs, the same in every app.
final List<String> _stickers = [
  for (final pack in const ['duck', 'mia_bunny', 'hot_cherry', 'baby_yoda'])
    for (var n = 0; n < 6; n++) 'assets/stickers/${pack}_$n.json',
];

// The example's chat palette (screens/examples/shared.tsx).
const Color _background = Color(0xFFF6F3EE);
const Color _selfBubble = Color(0xFFDBEAFE);
const Color _otherBubble = Color(0xFFFFFFFF);
const Color _text = Color(0xFF111827);
const Color _timestamp = Color(0xFF64748B);
const Color _scrim = Color(0x240F172A);

class ChatAttachment {
  const ChatAttachment(this.accent, this.height, this.label, this.subtitle);

  final Color accent;
  final double height;
  final String label;
  final String subtitle;
}

/// One item of the thread: a message, a sticker when [sticker] is set, or
/// a photo when [photo] is.
class ChatItem {
  const ChatItem({
    required this.self,
    this.senderName = '',
    this.text = '',
    this.timestamp = '',
    this.attachment,
    this.sticker,
    this.photo,
    this.photoHeight = 0,
  });

  final bool self;
  final String senderName;
  final String text;
  final String timestamp;
  final ChatAttachment? attachment;
  final String? sticker;
  final String? photo;
  final double photoHeight;
}

/// The thread, oldest first: the example's messages, with a photo after
/// the second of every four and a sticker after the third of every three,
/// each from the sender of the message before it. The sticker is picked by
/// a small generator with a fixed seed, the same in every app, so a sticker
/// file never repeats at a fixed distance: a list reuses its views in turn,
/// and a file that came back to the view still holding it would be shown
/// without being built again.
List<ChatItem> loadChatThread() {
  final bytes = loadAssetBytes('assets/chat.json');
  if (bytes == null) return const [];
  final messages = jsonDecode(utf8.decode(bytes)) as List<dynamic>;
  final thread = <ChatItem>[];
  var stickerSeed = 2026;
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i] as Map<String, dynamic>;
    final a = m['attachment'] as Map<String, dynamic>?;
    final self = m['sender'] == 'self';
    thread.add(ChatItem(
      self: self,
      senderName: m['senderName'] as String,
      text: m['text'] as String,
      timestamp: m['timestampLabel'] as String,
      attachment: a == null
          ? null
          : ChatAttachment(
              Color(0xFF000000 | int.parse((a['accent'] as String).substring(1), radix: 16)),
              (a['height'] as num).toDouble(),
              a['label'] as String,
              a['subtitle'] as String,
            ),
    ));
    if (i % _photoEvery == 1) {
      final n = i ~/ _photoEvery;
      final (w, h, height) = _photoShapes[n % _photoShapes.length];
      thread.add(ChatItem(
        self: self,
        photo: 'https://picsum.photos/id/${_firstPhotoId + n % _photoCount}/$w/$h',
        photoHeight: height,
      ));
    }
    if (i % _stickerEvery == _stickerEvery - 1) {
      stickerSeed = stickerSeed * 48271 % 2147483647;
      thread.add(ChatItem(self: self, sticker: _stickers[stickerSeed % _stickers.length]));
    }
  }
  return thread;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.thread,
    this.keepAliveCount,
    this.cacheExtent,
    this.recycleItems = false,
  });

  final List<ChatItem> thread;
  final int? keepAliveCount;
  final double? cacheExtent;
  final bool recycleItems;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _list = FastListController();
  int _nextTarget = 0;

  /// Each message's row in the newest-first list, by its number.
  late final List<int> _messageRows = [
    for (var i = 0; i < widget.thread.length; i++)
      if (widget.thread[i].sticker == null && widget.thread[i].photo == null)
        widget.thread.length - 1 - i,
  ];

  void _scroll() {
    final message = kChatScrollTargets[_nextTarget % kChatScrollTargets.length];
    _nextTarget++;
    _list.scrollToItem(_messageRows[message]);
  }

  List<ChatItem> get thread => widget.thread;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: headerBackground(context),
          // React Native's stack header is 56 dp on Android; on iOS both
          // apps use the system navigation bar.
          toolbarHeight: Platform.isAndroid ? 56 : null,
          title: const Text('Chat (DN)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Scroll',
              onPressed: _scroll,
            ),
          ],
        ),
        // The example keeps the thread above the bottom safe area.
        body: SafeArea(
          top: false,
          child: FastList(
            // Newest first, from the bottom up: the list opens at the
            // newest message.
            reverse: true,
            controller: _list,
            padding: const EdgeInsets.all(16),
            itemCount: thread.length,
            keepAliveCount: widget.keepAliveCount,
            cacheExtent: widget.cacheExtent,
            recycleItems: widget.recycleItems,
            itemBuilder: (context, i) {
              final item = thread[thread.length - 1 - i];
              if (item.sticker != null) return _Sticker(item);
              if (item.photo != null) return _Photo(item);
              return _Bubble(item);
            },
          ),
        ),
      );
}

class _Sticker extends StatelessWidget {
  const _Sticker(this.item);

  final ChatItem item;

  @override
  Widget build(BuildContext context) => Align(
        alignment: item.self ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: _stickerSide,
            height: _stickerSide,
            child: Lottie(
              asset: item.sticker,
              loop: true,
              autoplay: true,
              fit: LottieFit.contain,
            ),
          ),
        ),
      );
}

/// A photo with a bubble's rounded corners and no padding.
class _Photo extends StatelessWidget {
  const _Photo(this.item);

  final ChatItem item;

  @override
  Widget build(BuildContext context) => Align(
        alignment: item.self ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: _photoWidth,
            height: item.photoHeight,
            decoration: BoxDecoration(
              color: _photoFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.network(
              item.photo!,
              width: _photoWidth,
              height: item.photoHeight,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
}

/// The example's bubble: the sender's name, the attachment card if any,
/// the text and the time, at most 84 % of the thread's width. A bubble
/// with an attachment card takes all of that width, the card filling it.
class _Bubble extends StatelessWidget {
  const _Bubble(this.item);

  final ChatItem item;

  @override
  Widget build(BuildContext context) {
    final attachment = item.attachment;
    final maxWidth = (MediaQuery.of(context).size.width - 32) * 0.84;
    return Align(
      alignment: item.self ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        width: attachment == null ? null : maxWidth,
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: item.self ? _selfBubble : _otherBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.senderName,
              style: const TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            if (attachment != null) _AttachmentCard(attachment, width: maxWidth - 28),
            Text(
              item.text,
              style: const TextStyle(color: _text, fontSize: 14, height: 20 / 14),
            ),
            const SizedBox(height: 8),
            Text(item.timestamp, style: const TextStyle(color: _timestamp, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// The example's attachment card: a block of the accent colour under a
/// light scrim, its label and subtitle at the bottom, as wide as the
/// bubble's content.
class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard(this.attachment, {required this.width});

  final ChatAttachment attachment;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: attachment.height,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: attachment.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _scrim,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                attachment.subtitle,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}
