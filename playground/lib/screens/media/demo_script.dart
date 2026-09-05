/// The example's spoken demo script, in every language the engine speaks.
library;

/// The demo script the example speaks, translated into all 31 languages
/// [TTSLanguage.all] lists — so switching language in the picker tests the
/// SAME sentences in that language rather than falling back to English.
///
/// This lives in the example, not the plugin, because it is DartNative-branded
/// demo copy. The plugin's own neutral samples are [TTSTestStrings].
///
/// Every translation keeps the four things the script exists to exercise:
///
/// 1. **Four paragraphs.** The engine splits on blank lines before anything
///    else, so every language produces a comparable multi-chunk stream and
///    exercises the streaming/buffering path. (The exact chunk count follows
///    from paragraph lengths and the ramp in `_chunkText`, so it varies a
///    little by language — three or four for this script.)
/// 2. **Spelled-out numerals** one–five in the target language, in paragraph 2.
///    Digits would be read out character by character; words are the test.
/// 3. **Commas, a colon and a closing exclamation**, for prosody and pauses.
/// 4. **"DartNative" and "Flutter" left untranslated** — they are product
///    names, and they double as a check that a Latin brand name embedded in a
///    non-Latin script (Korean, Greek, Hindi, Arabic, Japanese) is spoken
///    sensibly.
class DemoScript {
  /// The demo script for [langCode], or the English one for an unknown code.
  static String forLanguage(String langCode) =>
      _byLang[langCode] ?? _byLang['en']!;

  /// Whether [text] is still one of the built-in scripts, i.e. the user has not
  /// typed over it. The language picker uses this to decide whether swapping in
  /// the newly-picked language's script would destroy the user's own input.
  static bool isScript(String text) => _all.contains(text.trim());

  static final Set<String> _all = _byLang.values.toSet();

  static const Map<String, String> _byLang = {
    // English
    'en':
        'Welcome to DartNative, where native performance meets the simplicity of Flutter.\n\n'
        'This is a short voice test with numbers: one, two, three, four, five.\n\n'
        'Let\'s test punctuation, pauses, and a natural conversational tone.\n\n'
        'Thank you for listening!',
    // Korean
    'ko':
        'DartNative에 오신 것을 환영합니다. 네이티브 성능과 Flutter의 단순함이 만나는 곳입니다.\n\n'
        '숫자를 넣은 짧은 음성 테스트입니다: 하나, 둘, 셋, 넷, 다섯.\n\n'
        '구두점과 쉼, 자연스러운 대화 말투를 테스트해 보겠습니다.\n\n'
        '들어 주셔서 감사합니다!',
    // Spanish
    'es':
        'Bienvenido a DartNative, donde el rendimiento nativo se une a la simplicidad de Flutter.\n\n'
        'Esta es una breve prueba de voz con números: uno, dos, tres, cuatro, cinco.\n\n'
        'Vamos a probar la puntuación, las pausas y un tono conversacional natural.\n\n'
        '¡Gracias por escuchar!',
    // Portuguese
    'pt':
        'Bem-vindo ao DartNative, onde o desempenho nativo encontra a simplicidade do Flutter.\n\n'
        'Este é um breve teste de voz com números: um, dois, três, quatro, cinco.\n\n'
        'Vamos testar a pontuação, as pausas e um tom de conversa natural.\n\n'
        'Obrigado por ouvir!',
    // French
    'fr':
        'Bienvenue dans DartNative, où la performance native rencontre la simplicité de Flutter.\n\n'
        'Voici un court test vocal avec des chiffres : un, deux, trois, quatre, cinq.\n\n'
        'Testons la ponctuation, les pauses et un ton de conversation naturel.\n\n'
        'Merci de votre écoute !',
    // Italian
    'it':
        'Benvenuto in DartNative, dove le prestazioni native incontrano la semplicità di Flutter.\n\n'
        'Questo è un breve test vocale con i numeri: uno, due, tre, quattro, cinque.\n\n'
        'Proviamo la punteggiatura, le pause e un tono di conversazione naturale.\n\n'
        'Grazie per l\'ascolto!',
    // Arabic
    'ar':
        'مرحبًا بك في DartNative، حيث يلتقي الأداء الأصلي ببساطة Flutter.\n\n'
        'هذا اختبار صوتي قصير بالأرقام: واحد، اثنان، ثلاثة، أربعة، خمسة.\n\n'
        'لنختبر علامات الترقيم والوقفات ونبرة محادثة طبيعية.\n\n'
        'شكرًا لاستماعك!',
    // Bulgarian
    'bg':
        'Добре дошли в DartNative, където нативната производителност се среща с простотата на Flutter.\n\n'
        'Това е кратък гласов тест с числа: едно, две, три, четири, пет.\n\n'
        'Нека тестваме пунктуацията, паузите и естествения разговорен тон.\n\n'
        'Благодаря, че слушахте!',
    // Croatian
    'hr':
        'Dobro došli u DartNative, gdje se izvorne performanse susreću s jednostavnošću Fluttera.\n\n'
        'Ovo je kratak glasovni test s brojevima: jedan, dva, tri, četiri, pet.\n\n'
        'Testirajmo interpunkciju, stanke i prirodan razgovorni ton.\n\n'
        'Hvala na slušanju!',
    // Czech
    'cs':
        'Vítejte v DartNative, kde se nativní výkon potkává s jednoduchostí Flutteru.\n\n'
        'Toto je krátký hlasový test s čísly: jedna, dva, tři, čtyři, pět.\n\n'
        'Otestujme interpunkci, pauzy a přirozený konverzační tón.\n\n'
        'Děkujeme za poslech!',
    // Danish
    'da':
        'Velkommen til DartNative, hvor native ydeevne møder enkelheden i Flutter.\n\n'
        'Dette er en kort stemmetest med tal: en, to, tre, fire, fem.\n\n'
        'Lad os teste tegnsætning, pauser og en naturlig samtaletone.\n\n'
        'Tak fordi du lyttede!',
    // Dutch
    'nl':
        'Welkom bij DartNative, waar native prestaties samenkomen met de eenvoud van Flutter.\n\n'
        'Dit is een korte spraaktest met getallen: één, twee, drie, vier, vijf.\n\n'
        'Laten we interpunctie, pauzes en een natuurlijke gesprekstoon testen.\n\n'
        'Bedankt voor het luisteren!',
    // Estonian
    'et':
        'Tere tulemast DartNative\'i, kus natiivne jõudlus kohtub Flutteri lihtsusega.\n\n'
        'See on lühike hääletest numbritega: üks, kaks, kolm, neli, viis.\n\n'
        'Testime kirjavahemärke, pause ja loomulikku vestlustooni.\n\n'
        'Aitäh kuulamast!',
    // Finnish
    'fi':
        'Tervetuloa DartNativeen, jossa natiivi suorituskyky kohtaa Flutterin yksinkertaisuuden.\n\n'
        'Tämä on lyhyt äänitesti numeroilla: yksi, kaksi, kolme, neljä, viisi.\n\n'
        'Testataan välimerkkejä, taukoja ja luontevaa keskustelusävyä.\n\n'
        'Kiitos kuuntelusta!',
    // German
    'de':
        'Willkommen bei DartNative, wo native Leistung auf die Einfachheit von Flutter trifft.\n\n'
        'Das ist ein kurzer Sprachtest mit Zahlen: eins, zwei, drei, vier, fünf.\n\n'
        'Testen wir Satzzeichen, Pausen und einen natürlichen Gesprächston.\n\n'
        'Danke fürs Zuhören!',
    // Greek
    'el':
        'Καλώς ήρθατε στο DartNative, όπου η εγγενής απόδοση συναντά την απλότητα του Flutter.\n\n'
        'Αυτή είναι μια σύντομη φωνητική δοκιμή με αριθμούς: ένα, δύο, τρία, τέσσερα, πέντε.\n\n'
        'Ας δοκιμάσουμε τη στίξη, τις παύσεις και έναν φυσικό τόνο συνομιλίας.\n\n'
        'Ευχαριστώ που ακούσατε!',
    // Hindi
    'hi':
        'DartNative में आपका स्वागत है, जहाँ नेटिव प्रदर्शन Flutter की सरलता से मिलता है।\n\n'
        'यह संख्याओं के साथ एक छोटा वॉइस टेस्ट है: एक, दो, तीन, चार, पाँच।\n\n'
        'आइए विराम चिह्न, ठहराव और एक स्वाभाविक बातचीत के लहजे का परीक्षण करें।\n\n'
        'सुनने के लिए धन्यवाद!',
    // Hungarian
    'hu':
        'Üdvözöljük a DartNative-ben, ahol a natív teljesítmény találkozik a Flutter egyszerűségével.\n\n'
        'Ez egy rövid hangteszt számokkal: egy, kettő, három, négy, öt.\n\n'
        'Teszteljük az írásjeleket, a szüneteket és a természetes társalgási hangnemet.\n\n'
        'Köszönjük, hogy meghallgattad!',
    // Indonesian
    'id':
        'Selamat datang di DartNative, tempat performa native bertemu dengan kesederhanaan Flutter.\n\n'
        'Ini adalah tes suara singkat dengan angka: satu, dua, tiga, empat, lima.\n\n'
        'Mari kita uji tanda baca, jeda, dan nada percakapan yang alami.\n\n'
        'Terima kasih sudah mendengarkan!',
    // Japanese
    'ja':
        'DartNative へようこそ。ネイティブの性能と Flutter の手軽さが出会う場所です。\n\n'
        '数字を使った短い音声テストです。いち、に、さん、よん、ご。\n\n'
        '句読点と間、そして自然な会話の口調をテストしてみましょう。\n\n'
        'お聞きいただきありがとうございました。',
    // Latvian
    'lv':
        'Laipni lūdzam DartNative, kur vietējā veiktspēja satiekas ar Flutter vienkāršību.\n\n'
        'Šis ir īss balss tests ar cipariem: viens, divi, trīs, četri, pieci.\n\n'
        'Pārbaudīsim pieturzīmes, pauzes un dabisku sarunas toni.\n\n'
        'Paldies, ka klausījāties!',
    // Lithuanian
    'lt':
        'Sveiki atvykę į DartNative, kur savoji sparta susitinka su Flutter paprastumu.\n\n'
        'Tai trumpas balso testas su skaičiais: vienas, du, trys, keturi, penki.\n\n'
        'Išbandykime skyrybos ženklus, pauzes ir natūralų pokalbio toną.\n\n'
        'Ačiū, kad klausėtės!',
    // Polish
    'pl':
        'Witamy w DartNative, gdzie natywna wydajność spotyka się z prostotą Fluttera.\n\n'
        'To krótki test głosu z liczbami: jeden, dwa, trzy, cztery, pięć.\n\n'
        'Przetestujmy interpunkcję, pauzy i naturalny ton rozmowy.\n\n'
        'Dziękujemy za wysłuchanie!',
    // Romanian
    'ro':
        'Bine ați venit la DartNative, unde performanța nativă se întâlnește cu simplitatea Flutter.\n\n'
        'Acesta este un scurt test vocal cu numere: unu, doi, trei, patru, cinci.\n\n'
        'Să testăm punctuația, pauzele și un ton natural de conversație.\n\n'
        'Mulțumim că ați ascultat!',
    // Russian
    'ru':
        'Добро пожаловать в DartNative, где нативная производительность встречается с простотой Flutter.\n\n'
        'Это короткий голосовой тест с числами: один, два, три, четыре, пять.\n\n'
        'Давайте проверим пунктуацию, паузы и естественную разговорную интонацию.\n\n'
        'Спасибо за внимание!',
    // Slovak
    'sk':
        'Vitajte v DartNative, kde sa natívny výkon stretáva s jednoduchosťou Flutteru.\n\n'
        'Toto je krátky hlasový test s číslami: jeden, dva, tri, štyri, päť.\n\n'
        'Otestujme interpunkciu, pauzy a prirodzený konverzačný tón.\n\n'
        'Ďakujeme za počúvanie!',
    // Slovenian
    'sl':
        'Dobrodošli v DartNative, kjer se domača zmogljivost sreča s preprostostjo Flutterja.\n\n'
        'To je kratek glasovni test s števili: ena, dve, tri, štiri, pet.\n\n'
        'Preizkusimo ločila, premore in naraven pogovorni ton.\n\n'
        'Hvala za poslušanje!',
    // Swedish
    'sv':
        'Välkommen till DartNative, där native prestanda möter Flutters enkelhet.\n\n'
        'Det här är ett kort rösttest med siffror: ett, två, tre, fyra, fem.\n\n'
        'Låt oss testa skiljetecken, pauser och en naturlig samtalston.\n\n'
        'Tack för att du lyssnade!',
    // Turkish
    'tr':
        'DartNative\'e hoş geldiniz; yerel performansın Flutter\'ın sadeliğiyle buluştuğu yer.\n\n'
        'Bu, sayılarla yapılan kısa bir ses testi: bir, iki, üç, dört, beş.\n\n'
        'Noktalama işaretlerini, duraklamaları ve doğal bir sohbet tonunu test edelim.\n\n'
        'Dinlediğiniz için teşekkürler!',
    // Ukrainian
    'uk':
        'Ласкаво просимо до DartNative, де нативна продуктивність поєднується з простотою Flutter.\n\n'
        'Це короткий голосовий тест із числами: один, два, три, чотири, п\'ять.\n\n'
        'Перевірмо пунктуацію, паузи та природну розмовну інтонацію.\n\n'
        'Дякуємо, що слухали!',
    // Vietnamese
    'vi':
        'Chào mừng bạn đến với DartNative, nơi hiệu năng gốc gặp gỡ sự đơn giản của Flutter.\n\n'
        'Đây là một bài kiểm tra giọng nói ngắn với các con số: một, hai, ba, bốn, năm.\n\n'
        'Hãy thử dấu câu, khoảng ngắt và giọng trò chuyện tự nhiên.\n\n'
        'Cảm ơn bạn đã lắng nghe!',
  };
}
