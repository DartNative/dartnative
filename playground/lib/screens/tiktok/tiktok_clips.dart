/// The clips, the made-up social data and the pool tuning behind the
/// TikTok-style feed. None of it is measured or sent anywhere.
library;

import 'dart:io' show Platform;

/// One clip: a free video from Pexels and its poster.
class TikTokClip {
  const TikTokClip(
    this.id,
    this.file,
    this.poster,
    this.width,
    this.height,
    this.fps,
    this.seconds,
  );

  final int id;
  final String file;
  final String poster;
  final int width;
  final int height;
  final int fps;
  final int seconds;

  String get url => 'https://videos.pexels.com/video-files/$id/$file';
  String get posterUrl => 'https://images.pexels.com/videos/$id/$poster';
  double get aspectRatio => width / height;
}

/// Pool and cache tuning. Four live players on iOS, three on Android, where
/// hardware decoders are scarcer; the page under the finger, the next two
/// and the previous one; 2 MB fetched ahead per upcoming page, one page
/// past the pool window too; a freed decoder settles before its
/// replacement is created.
abstract final class FeedTuning {
  static final int maxLivePlayers = Platform.isIOS ? 4 : 3;
  static const int preloadAhead = 2;
  static const int preCacheBeyond = 1;
  static const int preCacheBytes = 2 * 1024 * 1024;
  static const int maxDiskCacheBytes = 100 * 1024 * 1024;
  static const Duration disposeSettle = Duration(milliseconds: 250);

  /// The feed arrives the way a real one comes from a server: [batch]
  /// clips per request, and the next request goes out when the user is
  /// [fetchAhead] pages from the end of what has arrived.
  static const int batch = 30;
  static const int fetchAhead = 5;
}

const String _crop = '?auto=compress&cs=tinysrgb&fit=crop&h=1200&w=630';

/// How many of [kClips], from the top, the feed opens on, in this order.
const int kOpeningCount = 19;

/// Portrait clips from Pexels, people and places rather than scenery. The
/// first [kOpeningCount] are the feed's opening, in this order: the five
/// the Infinite Video Scrolling demo plays, so the two feeds open on the
/// same videos, then fourteen picked by hand; after them the feed deals
/// the rest at random and starts over once every clip has been shown.
const List<TikTokClip> kClips = [
  TikTokClip(5329239, '5329239-hd_1080_2048_25fps.mp4', 'pictures/preview-0.jpeg', 1080, 2048, 25, 64),
  TikTokClip(7197863, '7197863-hd_720_1280_25fps.mp4', 'pictures/preview-0.jpeg', 720, 1280, 25, 14),
  TikTokClip(7150170, '7150170-sd_540_960_25fps.mp4', 'pictures/preview-0.jpeg', 540, 960, 25, 9),
  TikTokClip(6864993, '6864993-hd_720_1366_25fps.mp4', 'pictures/preview-0.jpeg', 720, 1366, 25, 25),
  TikTokClip(12109326, '12109326-hd_720_1280_25fps.mp4', 'pictures/preview-0.jpeg', 720, 1280, 25, 10),
  TikTokClip(12879951, '12879951-hd_720_1280_24fps.mp4', 'pexels-photo-12879951.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(17422590, '17422590-hd_720_1280_24fps.mp4', 'pexels-photo-17422590.jpeg$_crop', 720, 1280, 24, 15),
  TikTokClip(18463428, '18463428-hd_720_1280_60fps.mp4', 'pexels-photo-18463428.jpeg$_crop', 720, 1280, 60, 9),
  TikTokClip(4929206, '4929206-hd_720_1366_25fps.mp4', 'pexels-photo-4929206.jpeg$_crop', 720, 1366, 25, 44),
  TikTokClip(4725196, '4725196-hd_720_1280_25fps.mp4', 'pictures/preview-0.jpeg', 720, 1280, 25, 5),
  TikTokClip(20618586, '20618586-hd_720_1280_60fps.mp4', 'pexels-photo-20618586.jpeg$_crop', 720, 1280, 60, 11),
  TikTokClip(35480733, '15030937_720_1280_60fps.mp4', 'pexels-photo-35480733.jpeg$_crop', 720, 1280, 60, 11),
  TikTokClip(10329079, '10329079-hd_720_1280_50fps.mp4', 'pexels-photo-10329079.jpeg$_crop', 720, 1280, 50, 16),
  TikTokClip(7319619, '7319619-hd_720_1366_25fps.mp4', 'pexels-photo-7319619.jpeg$_crop', 720, 1366, 25, 39),
  TikTokClip(10996037, '10996037-hd_720_1280_30fps.mp4', 'pictures/preview-0.jpeg', 720, 1280, 30, 8),
  TikTokClip(7721706, '7721706-hd_720_1366_25fps.mp4', 'pictures/preview-0.jpeg', 720, 1366, 25, 12),
  TikTokClip(36165312, '15337495_720_1280_30fps.mp4', 'pexels-photo-36165312.jpeg$_crop', 720, 1280, 30, 12),
  TikTokClip(34766758, '14739249_720_1280_59fps.mp4', 'pexels-photo-34766758.jpeg$_crop', 720, 1280, 59, 15),
  TikTokClip(8042838, '8042838-hd_720_1366_25fps.mp4', 'pictures/preview-0.jpeg', 720, 1366, 25, 13),
  TikTokClip(19155828, '19155828-hd_720_1280_30fps.mp4', 'counterlight-model-photo-shoot-woman-hands-19155828.jpeg$_crop', 720, 1280, 30, 6),
  TikTokClip(32220524, '13741878_720_1280_24fps.mp4', 'business-car-city-conference-32220524.jpeg$_crop', 720, 1280, 24, 16),
  TikTokClip(30840253, '13188406_720_1280_60fps.mp4', 'big-city-life-city-activity-city-adventure-city-life-30840253.jpeg$_crop', 720, 1280, 60, 16),
  TikTokClip(16277046, '16277046-hd_720_1280_30fps.mp4', 'audio-classic-music-old-16277046.jpeg$_crop', 720, 1280, 30, 8),
  TikTokClip(20680305, '20680305-hd_720_1280_30fps.mp4', 'snow-street-view-woman-walking-20680305.jpeg$_crop', 720, 1280, 30, 12),
  TikTokClip(31967557, '13621994_720_1280_24fps.mp4', 'aerial-city-downtown-seattle-drone-31967557.jpeg$_crop', 720, 1280, 24, 12),
  TikTokClip(35703894, '15132224_720_1280_50fps.mp4', 'beans-bell-pepper-bowl-cooking-35703894.jpeg$_crop', 720, 1280, 50, 16),
  TikTokClip(30044756, '12888286_720_1280_30fps.mp4', 'dish-food-indian-dish-paneer-30044756.jpeg$_crop', 720, 1280, 30, 7),
  TikTokClip(34164177, '14483826_720_1280_24fps.mp4', 'beanokio-cafe-coffee-shop-wicker-park-34164177.jpeg$_crop', 720, 1280, 24, 9),
  TikTokClip(18130530, '18130530-hd_720_1280_30fps.mp4', 'pexels-walk-in-berlin-part-i-18130530.jpeg$_crop', 720, 1280, 30, 16),
  TikTokClip(10741262, '10741262-hd_720_1280_30fps.mp4', 'city-kuala-lumpur-night-city-public-transport-10741262.jpeg$_crop', 720, 1280, 30, 9),
  TikTokClip(36879827, '15623099_720_1280_30fps.mp4', 'al-fresco-dining-meal-meat-outdoor-cooking-36879827.jpeg$_crop', 720, 1280, 30, 8),
  TikTokClip(29691053, '12769317_720_1280_60fps.mp4', 'animals-cat-dog-dog-and-cat-29691053.jpeg$_crop', 720, 1280, 60, 10),
  TikTokClip(31891725, '13584092_720_1280_24fps.mp4', 'busy-city-cloudy-corporate-31891725.jpeg$_crop', 720, 1280, 24, 14),
  TikTokClip(4734671, '4734671-hd_720_1280_25fps.mp4', 'boy-friends-girl-skateboarding-4734671.jpeg$_crop', 720, 1280, 25, 9),
  TikTokClip(6645810, '6645810-hd_720_1280_30fps.mp4', 'asian-asian-cuisine-asian-food-bbq-6645810.jpeg$_crop', 720, 1280, 30, 10),
  TikTokClip(16277043, '16277043-hd_720_1280_30fps.mp4', 'audio-classic-music-old-16277043.jpeg$_crop', 720, 1280, 30, 10),
  TikTokClip(28115367, '12303950_720_1280_30fps.mp4', 'automobile-city-lights-evening-light-evenings-28115367.jpeg$_crop', 720, 1280, 30, 11),
  TikTokClip(5617531, '5617531-hd_720_1280_25fps.mp4', 'food-hands-healthy-eating-starters-5617531.jpeg$_crop', 720, 1280, 25, 10),
  TikTokClip(8499351, '8499351-hd_720_1280_24fps.mp4', 'care-dog-walking-dogs-family-8499351.jpeg$_crop', 720, 1280, 24, 14),
  TikTokClip(7817125, '7817125-hd_720_1280_60fps.mp4', 'adult-boy-business-chair-7817125.jpeg$_crop', 720, 1280, 60, 10),
  TikTokClip(35189047, '14908075_720_1280_60fps.mp4', 'ankara-ankara-province-automobiles-car-emblem-35189047.jpeg$_crop', 720, 1280, 60, 15),
  TikTokClip(34499554, '14618037_720_1280_30fps.mp4', 'africa-blue-city-chefchaouen-maroc-34499554.jpeg$_crop', 720, 1280, 30, 7),
  TikTokClip(13931622, '13931622-hd_720_1280_24fps.mp4', 'active-beautiful-bike-city-13931622.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(8498883, '8498883-hd_720_1280_24fps.mp4', 'care-dog-walking-dogs-family-8498883.jpeg$_crop', 720, 1280, 24, 18),
  TikTokClip(14607104, '14607104-hd_720_1280_24fps.mp4', '4k-america-buildings-city-14607104.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(35470210, '15027167_720_1280_30fps.mp4', 'asia-street-food-authentic-street-food-crispy-poori-deep-frying-35470210.jpeg$_crop', 720, 1280, 30, 13),
  TikTokClip(38869201, '16523327_720_1280_24fps.mp4', 'bangladesh-4k-drone-video-bangladesh-dhaka-4k-drone-shot-bangladesh-drone-video-beautiful-dhaka-city-38869201.jpeg$_crop', 720, 1280, 24, 7),
  TikTokClip(19981541, '19981541-hd_720_1280_24fps.mp4', 'aliment-drinks-familiar-food-19981541.jpeg$_crop', 720, 1280, 24, 6),
  TikTokClip(31366800, '13385149_720_1280_50fps.mp4', 'alfama-district-bairro-alto-city-of-lisbon-europe-travel-31366800.jpeg$_crop', 720, 1280, 50, 11),
  TikTokClip(9620605, '9620605-hd_720_1280_60fps.mp4', 'big-city-brickell-bridge-cars-9620605.jpeg$_crop', 720, 1280, 60, 7),
  TikTokClip(27924765, '12264659_720_1280_30fps.mp4', '2024-istanbul-istiklal-street-tram-27924765.jpeg$_crop', 720, 1280, 30, 19),
  TikTokClip(27437047, '12144177_720_1280_30fps.mp4', 'beyoglu-champion-esplanade-football-27437047.jpeg$_crop', 720, 1280, 30, 17),
  TikTokClip(36579293, '15509203_720_1280_60fps.mp4', 'ramadan-ramadan-food-shared-meal-shared-moment-36579293.jpeg$_crop', 720, 1280, 60, 8),
  TikTokClip(36339394, '15412976_720_1280_30fps.mp4', 'com-gia-dinh-family-gathering-traditional-vietnamese-food-vietnamese-food-36339394.jpeg$_crop', 720, 1280, 30, 7),
  TikTokClip(35112878, '14875941_720_1280_25fps.mp4', 'belly-dancing-dance-dancing-performance-35112878.jpeg$_crop', 720, 1280, 25, 9),
  TikTokClip(39359532, '16754102_720_1280_24fps.mp4', 'bangladesh-4k-drone-video-dhaka-4k-drone-dhaka-4k-drone-travel-dhaka-4k-video-39359532.jpeg$_crop', 720, 1280, 24, 11),
  TikTokClip(34636825, '14680500_720_1280_30fps.mp4', 'concert-scene-live-concert-34636825.jpeg$_crop', 720, 1280, 30, 8),
  TikTokClip(36579538, '15509367_720_1280_60fps.mp4', 'ramadan-ramadan-food-shared-meal-shared-moment-36579538.jpeg$_crop', 720, 1280, 60, 7),
  TikTokClip(32046895, '13660846_720_1280_50fps.mp4', 'asian-model-beautiful-best-photographer-in-bangalore-bestphotographerindia-32046895.jpeg$_crop', 720, 1280, 50, 15),
  TikTokClip(30628321, '13111363_720_1280_60fps.mp4', 'blonde-model-dancin-disco-discotheque-30628321.jpeg$_crop', 720, 1280, 60, 6),
  TikTokClip(26589007, '11966515_720_1280_60fps.mp4', 'automotive-automotives-black-car-bmw-26589007.jpeg$_crop', 720, 1280, 60, 7),
  TikTokClip(39359517, '16754042_720_1280_24fps.mp4', 'bangladesh-4k-drone-video-dhaka-4k-drone-dhaka-4k-drone-travel-dhaka-4k-video-39359517.jpeg$_crop', 720, 1280, 24, 11),
  TikTokClip(34163977, '14484030_720_1280_24fps.mp4', 'beanokio-cafe-coffee-shop-wicker-park-34163977.jpeg$_crop', 720, 1280, 24, 8),
  TikTokClip(10594890, '10594890-hd_720_1280_30fps.mp4', 'christmas-istanbul-noel-travel-blog-10594890.jpeg$_crop', 720, 1280, 30, 16),
  TikTokClip(20521347, '20521347-hd_720_1280_60fps.mp4', 'basketball-basquetbol-20521347.jpeg$_crop', 720, 1280, 60, 18),
  TikTokClip(35246006, '14931852_720_1280_30fps.mp4', 'asian-food-asian-street-food-asian-sweet-food-bangladeshi-local-sweet-35246006.jpeg$_crop', 720, 1280, 30, 8),
  TikTokClip(8028182, '8028182-hd_720_1280_24fps.mp4', 'boho-freedom-girl-hippie-8028182.jpeg$_crop', 720, 1280, 24, 13),
  TikTokClip(13443887, '13443887-hd_720_1280_24fps.mp4', 'adult-appoint-boy-bridge-13443887.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(35612093, '15091754_720_1280_60fps.mp4', 'autumn-blue-car-cars-35612093.jpeg$_crop', 720, 1280, 60, 6),
  TikTokClip(7487698, '7487698-hd_720_1280_24fps.mp4', '20-25-year-old-woman-adult-blur-breakfast-7487698.jpeg$_crop', 720, 1280, 24, 11),
  TikTokClip(28308907, '12357081_720_1280_30fps.mp4', 'food-mexican-food-taco-tortilla-28308907.jpeg$_crop', 720, 1280, 30, 14),
  TikTokClip(13326104, '13326104-hd_720_1280_24fps.mp4', 'adult-appoint-business-car-13326104.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(19156909, '19156909-hd_720_1280_60fps.mp4', 'breakfast-cafe-latte-coffee-painted-nails-19156909.jpeg$_crop', 720, 1280, 60, 9),
  TikTokClip(6645816, '6645816-hd_720_1280_30fps.mp4', 'asian-asian-cuisine-asian-food-bbq-6645816.jpeg$_crop', 720, 1280, 30, 10),
  TikTokClip(13433156, '13433156-hd_720_1280_24fps.mp4', 'adult-boy-cap-color-13433156.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(13117141, '13117141-hd_720_1280_30fps.mp4', 'basketball-dunk-dunking-13117141.jpeg$_crop', 720, 1280, 30, 11),
  TikTokClip(34268286, '14519759_720_1280_60fps.mp4', '4k-video-4k-video-copyright-free-crowd-people-crowded-city-34268286.jpeg$_crop', 720, 1280, 60, 9),
  TikTokClip(19332993, '19332993-hd_720_1280_50fps.mp4', '4k-video-america-american-car-building-19332993.jpeg$_crop', 720, 1280, 50, 10),
  TikTokClip(27807342, '12228870_720_1280_30fps.mp4', 'bogota-food-pineapple-turckey-27807342.jpeg$_crop', 720, 1280, 30, 16),
  TikTokClip(29509293, '12702402_720_1280_60fps.mp4', 'flying-over-city-29509293.jpeg$_crop', 720, 1280, 60, 20),
  TikTokClip(20522220, '20522220-hd_720_1280_60fps.mp4', 'basketball-basquetbol-canasta-de-basquetbol-20522220.jpeg$_crop', 720, 1280, 60, 19),
  TikTokClip(35112880, '14875938_720_1280_25fps.mp4', 'belly-dancing-dance-dancing-performance-35112880.jpeg$_crop', 720, 1280, 25, 18),
  TikTokClip(8028137, '8028137-hd_720_1280_25fps.mp4', 'bgirl-break-dance-breakdance-dance-8028137.jpeg$_crop', 720, 1280, 25, 20),
  TikTokClip(35448530, '15018253_720_1280_30fps.mp4', 'competition-food-karachi-khao-sey-35448530.jpeg$_crop', 720, 1280, 30, 7),
  TikTokClip(36700079, '15556728_720_1280_60fps.mp4', '4k-4k-hd-free-videos-busy-roads-car-36700079.jpeg$_crop', 720, 1280, 60, 14),
  TikTokClip(35733130, '15145084_720_1280_30fps.mp4', 'asian-cityscape-bhaktapur-city-transportation-electric-wires-35733130.jpeg$_crop', 720, 1280, 30, 20),
  TikTokClip(35112876, '14875923_720_1280_25fps.mp4', 'belly-dancing-dance-dancing-performance-35112876.jpeg$_crop', 720, 1280, 25, 8),
  TikTokClip(17410937, '17410937-hd_720_1280_30fps.mp4', 'arabica-coffee-bar-cafe-black-coffee-caffeine-17410937.jpeg$_crop', 720, 1280, 30, 11),
  TikTokClip(31891726, '13584084_720_1280_24fps.mp4', 'busy-city-cloudy-corporate-31891726.jpeg$_crop', 720, 1280, 24, 18),
  TikTokClip(13441308, '13441308-hd_720_1280_24fps.mp4', 'adult-appoint-beautiful-bike-13441308.jpeg$_crop', 720, 1280, 24, 10),
  TikTokClip(38432931, '16320549_720_1280_24fps.mp4', 'dj-dj-equipment-fashion-festival-38432931.jpeg$_crop', 720, 1280, 24, 8),
];

/// A handle, a caption and counts per clip, derived from the clip id so a
/// clip reads the same wherever it recurs in the feed.
class ClipSocial {
  const ClipSocial({
    required this.handle,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.shares,
  });

  final String handle;
  final String caption;
  final int likes;
  final int comments;
  final int saves;
  final int shares;
}

const _handles = [
  'kathmandu.frames', 'slowtravel', 'pexels.picks', 'tinyplanet',
  'goldenhour.club', 'streetsofnepal', 'drone.diaries', 'quiet.mornings',
];

const _captions = [
  'Nobody talks about how good this looks at 25fps',
  'Saved this for a rainy day. It is raining.',
  'Found this spot by accident and stayed two hours',
  'Sound on. Trust me.',
  'POV: you finally took the long way home',
  'Filmed on a Tuesday, posted on a Tuesday',
];

ClipSocial socialFor(TikTokClip clip) {
  final s = clip.id;
  return ClipSocial(
    handle: _handles[s % _handles.length],
    caption: _captions[(s ~/ 7) % _captions.length],
    likes: 1200 + (s * 37) % 480000,
    comments: 40 + (s * 13) % 9000,
    saves: 90 + (s * 7) % 30000,
    shares: 15 + (s * 3) % 12000,
  );
}

/// 1.2K, 48.3K, 1.1M: the way the counts read on the real thing.
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return '${k >= 100 ? k.round() : k.toStringAsFixed(1)}K';
  }
  return '${(n / 1000000).toStringAsFixed(1)}M';
}

/// Creators the viewer follows. Two to start with, so the Following feed
/// has something in it before anyone taps Follow.
final Set<String> followed = {'slowtravel', 'drone.diaries'};

/// Comments the viewer posted, per clip id, newest first.
final Map<int, List<String>> postedComments = {};

/// The clips a creator posted, in feed order. Capped: a profile grid of
/// hundreds of tiles is not what that screen is for.
List<TikTokClip> clipsBy(String handle) => [
  for (final c in kClips)
    if (socialFor(c).handle == handle) c,
].take(18).toList();

/// The Following feed: clips from followed creators, in feed order.
List<TikTokClip> followingClips() => [
  for (final c in kClips)
    if (followed.contains(socialFor(c).handle)) c,
];

/// Display name for a handle: `drone.diaries` reads as `Drone Diaries`.
String displayName(String handle) => handle
    .split(RegExp(r'[._]'))
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
