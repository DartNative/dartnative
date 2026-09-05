/// Crypto demo — standalone example for dartnative_crypto.
///
/// Tests RSA and AES encryption APIs:
///   RSA tab:
///     - Generate RSA key pair (2048-bit)
///     - Encrypt text with public key (PKCS1v15 / OAEP)
///     - Decrypt ciphertext with private key
///     - Display keys and results
///   AES tab:
///     - Generate a random secret key (256-bit)
///     - Encrypt text with secret key (AES-256-GCM)
///     - Decrypt ciphertext with secret key
///     - PBKDF2 key derivation from password + salt
///     - Display key and results
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart';
import 'package:dartnative_crypto/dartnative_crypto.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _bgDark = Color(0xFF000000);
const _cardBg = Color(0xFF1C1C1E);
const _border = Color(0xFF3A3A3C);
const _textPrimary = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFF8E8E93);
const _accent = Color(0xFF0A84FF);
const _success = Color(0xFF34C759);
const _error = Color(0xFFFF3B30);
const _keyGreen = Color(0xFF32D74B);
const _monoBg = Color(0xFF262628);

// ── Screen ────────────────────────────────────────────────────────────────────

class CryptoDemo extends StatefulWidget {
  const CryptoDemo({super.key});

  @override
  State<CryptoDemo> createState() => _CryptoDemoState();
}

class _CryptoDemoState extends State<CryptoDemo> {
  int _tabIndex = 0;

  // ── RSA state ─────────────────────────────────────────────────────────────
  String _rsaPublicKey = '';
  String _rsaPrivateKey = '';
  final _rsaInputCtrl = TextEditingController(text: 'Hello dartnative RSA!');
  String _rsaEncrypted = '';
  String _rsaDecrypted = '';
  bool _rsaLoading = false;
  String _rsaStatus = '';

  // ── AES state ─────────────────────────────────────────────────────────────
  Uint8List? _aesKey;
  String _aesKeyHex = '';
  final _aesInputCtrl = TextEditingController(text: 'Hello dartnative AES!');
  String _aesEncryptedHex = '';
  String _aesDecrypted = '';
  bool _aesLoading = false;
  String _aesStatus = '';

  // ── PBKDF2 state ──────────────────────────────────────────────────────────
  final _pbkdf2PassCtrl = TextEditingController(text: 'my-secret-password');
  final _pbkdf2SaltCtrl = TextEditingController(text: 'random-salt-123');
  String _pbkdf2Key = '';
  bool _pbkdf2Loading = false;

  @override
  void dispose() {
    _rsaInputCtrl.dispose();
    _aesInputCtrl.dispose();
    _pbkdf2PassCtrl.dispose();
    _pbkdf2SaltCtrl.dispose();
    super.dispose();
  }

  // ── RSA actions ───────────────────────────────────────────────────────────

  Future<void> _rsaGenerate() async {
    dnLog('[CryptoDemo][RSA] generate tap');
    setState(() {
      _rsaLoading = true;
      _rsaStatus = 'Generating 2048-bit key pair…';
    });
    try {
      dnLog('[CryptoDemo][RSA] calling RSA.generate(2048)');
      final pair = await RSA.generate(2048);
      dnLog('[CryptoDemo][RSA] generate success');
      dnLog(
          '[CryptoDemo][RSA] publicKey  (first 80)="${pair.publicKey.length > 80 ? pair.publicKey.substring(0, 80) : pair.publicKey}" len=${pair.publicKey.length}');
      dnLog(
          '[CryptoDemo][RSA] privateKey (first 80)="${pair.privateKey.length > 80 ? pair.privateKey.substring(0, 80) : pair.privateKey}" len=${pair.privateKey.length}');
      setState(() {
        _rsaPublicKey = pair.publicKey;
        _rsaPrivateKey = pair.privateKey;
        _rsaStatus = 'Key pair generated ✓';
      });
    } catch (e) {
      dnLog('[CryptoDemo][RSA] generate error: $e');
      setState(() => _rsaStatus = 'Error: $e');
    } finally {
      setState(() => _rsaLoading = false);
    }
  }

  Future<void> _rsaEncrypt({bool useOAEP = false}) async {
    dnLog('[CryptoDemo][RSA] encrypt tap useOAEP=$useOAEP');
    dnLog(
        '[CryptoDemo][RSA] encrypt precheck keyEmpty=${_rsaPublicKey.isEmpty} keyLen=${_rsaPublicKey.length} loading=$_rsaLoading');
    if (_rsaPublicKey.isEmpty) {
      dnLog('[CryptoDemo][RSA] encrypt blocked: no public key');
      setState(() => _rsaStatus = 'Generate a key pair first');
      return;
    }
    setState(() {
      _rsaLoading = true;
      _rsaStatus = 'Encrypting…';
    });
    try {
      dnLog(
          '[CryptoDemo][RSA] calling RSA.encrypt useOAEP=$useOAEP plaintextLen=${_rsaInputCtrl.text.length}');
      if (useOAEP) {
        _rsaEncrypted = await RSA.encryptOAEP(
          _rsaInputCtrl.text,
          '', // label
          RSAHash.SHA256,
          _rsaPublicKey,
        );
      } else {
        _rsaEncrypted = await RSA.encryptPKCS1v15(
          _rsaInputCtrl.text,
          _rsaPublicKey,
        );
      }
      dnLog(
          '[CryptoDemo][RSA] encrypt success cipherLen=${_rsaEncrypted.length} first100=${_rsaEncrypted.length > 100 ? _rsaEncrypted.substring(0, 100) : _rsaEncrypted}');
      setState(() => _rsaStatus = 'Encrypted ✓');
    } catch (e) {
      dnLog('[CryptoDemo][RSA] encrypt error: $e');
      setState(() => _rsaStatus = 'Encrypt error: $e');
    } finally {
      setState(() => _rsaLoading = false);
    }
  }

  Future<void> _rsaDecrypt({bool useOAEP = false}) async {
    if (_rsaEncrypted.isEmpty) {
      setState(() => _rsaStatus = 'Encrypt something first');
      return;
    }
    setState(() {
      _rsaLoading = true;
      _rsaStatus = 'Decrypting…';
    });
    try {
      if (useOAEP) {
        _rsaDecrypted = await RSA.decryptOAEP(
          _rsaEncrypted,
          '', // label
          RSAHash.SHA256,
          _rsaPrivateKey,
        );
      } else {
        _rsaDecrypted = await RSA.decryptPKCS1v15(
          _rsaEncrypted,
          _rsaPrivateKey,
        );
      }
      setState(() {
        _rsaStatus = _rsaDecrypted == _rsaInputCtrl.text
            ? 'Decrypted ✓ — matches original'
            : 'Decrypted ✗ — mismatch!';
      });
    } catch (e) {
      setState(() => _rsaStatus = 'Decrypt error: $e');
    } finally {
      setState(() => _rsaLoading = false);
    }
  }

  // ── AES actions ───────────────────────────────────────────────────────────

  Future<void> _aesGenerateKey() async {
    dnLog('[CryptoDemo][AES] generate tap');
    setState(() {
      _aesLoading = true;
      _aesStatus = 'Generating 256-bit AES key…';
    });
    try {
      dnLog('[CryptoDemo][AES] calling AES.generateSecretKey(256)');
      final key = await AES.generateSecretKey(256);
      dnLog(
          '[CryptoDemo][AES] generate success len=${key.length} first4=${key.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
      setState(() {
        _aesKey = key;
        _aesKeyHex = _bytesToHex(key);
        _aesStatus = 'AES-256 key generated ✓';
      });
      dnLog(
          '[CryptoDemo][AES] state committed keyLen=${_aesKey?.length ?? 0} keyHexLen=${_aesKeyHex.length}');
    } catch (e) {
      dnLog('[CryptoDemo][AES] generate error: $e');
      setState(() => _aesStatus = 'Error: $e');
    } finally {
      setState(() => _aesLoading = false);
    }
  }

  Future<void> _aesEncrypt() async {
    dnLog('[CryptoDemo][AES] encrypt tap');
    dnLog(
        '[CryptoDemo][AES] encrypt precheck keyNull=${_aesKey == null} keyLen=${_aesKey?.length ?? 0} keyHexLen=${_aesKeyHex.length} loading=$_aesLoading');
    if (_aesKey == null) {
      dnLog('[CryptoDemo][AES] encrypt blocked: no AES key available');
      setState(() => _aesStatus = 'Generate a key first');
      return;
    }
    setState(() {
      _aesLoading = true;
      _aesStatus = 'Encrypting with AES-256-GCM…';
    });
    try {
      dnLog(
          '[CryptoDemo][AES] calling AES.encrypt dataLen=${_aesInputCtrl.text.length} keyLen=${_aesKey!.length}');
      final input = utf8.encode(_aesInputCtrl.text);
      final encrypted = await AES.encrypt(Uint8List.fromList(input), _aesKey!);
      dnLog('[CryptoDemo][AES] encrypt success bytes=${encrypted.length}');
      setState(() {
        _aesEncryptedHex = _bytesToHex(encrypted);
        _aesStatus = 'Encrypted ✓ — ${encrypted.length} bytes';
      });
    } catch (e) {
      dnLog('[CryptoDemo][AES] encrypt error: $e');
      setState(() => _aesStatus = 'Encrypt error: $e');
    } finally {
      setState(() => _aesLoading = false);
    }
  }

  Future<void> _aesDecrypt() async {
    dnLog('[CryptoDemo][AES] decrypt tap');
    if (_aesEncryptedHex.isEmpty) {
      setState(() => _aesStatus = 'Encrypt something first');
      return;
    }
    setState(() {
      _aesLoading = true;
      _aesStatus = 'Decrypting with AES-256-GCM…';
    });
    try {
      dnLog(
          '[CryptoDemo][AES] calling AES.decrypt cipherLen=${_aesEncryptedHex.length} keyLen=${_aesKey?.length ?? 0}');
      final encrypted = _hexToBytes(_aesEncryptedHex);
      final decrypted = await AES.decrypt(encrypted, _aesKey!);
      final text = utf8.decode(decrypted);
      dnLog('[CryptoDemo][AES] decrypt success textLen=${text.length}');
      setState(() {
        _aesDecrypted = text;
        _aesStatus = text == _aesInputCtrl.text
            ? 'Decrypted ✓ — matches original'
            : 'Decrypted ✗ — mismatch!';
      });
    } catch (e) {
      dnLog('[CryptoDemo][AES] decrypt error: $e');
      setState(() => _aesStatus = 'Decrypt error: $e');
    } finally {
      setState(() => _aesLoading = false);
    }
  }

  // ── PBKDF2 actions ────────────────────────────────────────────────────────

  Future<void> _pbkdf2Derive() async {
    dnLog('[CryptoDemo][AES] pbkdf2 tap');
    setState(() {
      _pbkdf2Loading = true;
    });
    try {
      dnLog('[CryptoDemo][AES] calling AES.pbkdf2');
      final key = await AES.pbkdf2(
        _pbkdf2PassCtrl.text,
        _pbkdf2SaltCtrl.text,
        32, // 256-bit derived key
        100000, // 100K iterations
        'sha256',
      );
      dnLog('[CryptoDemo][AES] pbkdf2 success len=${key.length}');
      setState(() {
        _pbkdf2Key = _bytesToHex(key);
      });
    } catch (e) {
      dnLog('[CryptoDemo][AES] pbkdf2 error: $e');
      setState(() => _pbkdf2Key = 'Error: $e');
    } finally {
      setState(() => _pbkdf2Loading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Uint8List _hexToBytes(String hex) {
    final buf = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      buf.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(buf);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The screen colour belongs on the Scaffold: iOS 26 paints the push
      // backdrop with the route's colour, else it flashes at the corners.
      backgroundColor: _bgDark,
      // Dark screen: iOS 26 renders its scroll-edge fades in the trait.
      brightness: Brightness.dark,
      appBar: AppBar(
        title: const Text(
          'Crypto',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: SegmentedControl(
              segments: const ['RSA', 'AES'],
              selectedIndex: _tabIndex,
              onValueChanged: (i) {
                dnLog('[CryptoDemo] tab changed from $_tabIndex to $i');
                setState(() => _tabIndex = i);
              },
              labelFontStyle: const TextStyle(color: _textSecondary),
              selectedLabelFontStyle: const TextStyle(color: _textPrimary),
            ),
          ),
          Expanded(
            child: _tabIndex == 0 ? _buildRSATab() : _buildAESTab(),
          ),
        ],
      ),
    );
  }

  // ── RSA tab ───────────────────────────────────────────────────────────────

  Widget _buildRSATab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Section: Key Generation ──────────────────────────────────────
        const _SectionHeader('1 · Generate RSA Key Pair'),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Generate 2048-bit Key Pair',
          isLoading: _rsaLoading,
          onTap: _rsaGenerate,
        ),
        if (_rsaPublicKey.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Public Key',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          _MonoBlock(_rsaPublicKey.length > 120
              ? '${_rsaPublicKey.substring(0, 120)}…'
              : _rsaPublicKey),
          const SizedBox(height: 12),
          const Text('Private Key',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          _MonoBlock(_rsaPrivateKey.length > 120
              ? '${_rsaPrivateKey.substring(0, 120)}…'
              : _rsaPrivateKey),
        ],
        const SizedBox(height: 24),

        // ── Section: Encrypt / Decrypt ───────────────────────────────────
        const _SectionHeader('2 · Encrypt / Decrypt'),
        const SizedBox(height: 12),
        TextField(
          controller: _rsaInputCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter text to encrypt…',
          ),
          style: const TextStyle(color: _textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Encrypt (PKCS1)',
                isLoading: _rsaLoading,
                onTap: () => _rsaEncrypt(useOAEP: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Encrypt (OAEP)',
                isLoading: _rsaLoading,
                onTap: () => _rsaEncrypt(useOAEP: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Decrypt (PKCS1)',
                isLoading: _rsaLoading,
                onTap: () => _rsaDecrypt(useOAEP: false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Decrypt (OAEP)',
                isLoading: _rsaLoading,
                onTap: () => _rsaDecrypt(useOAEP: true),
              ),
            ),
          ],
        ),
        if (_rsaEncrypted.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Encrypted (base64)',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          _MonoBlock(_rsaEncrypted.length > 100
              ? '${_rsaEncrypted.substring(0, 100)}…'
              : _rsaEncrypted),
        ],
        if (_rsaDecrypted.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Decrypted',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          _MonoBlock(_rsaDecrypted),
        ],
        if (_rsaStatus.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ResultText(_rsaStatus),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  // ── AES tab ───────────────────────────────────────────────────────────────

  Widget _buildAESTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Section: Key Generation ──────────────────────────────────────
        const _SectionHeader('1 · AES-256 Key'),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Generate AES-256 Key',
          isLoading: _aesLoading,
          onTap: _aesGenerateKey,
        ),
        if (_aesKeyHex.isNotEmpty) ...[
          const SizedBox(height: 8),
          _MonoBlock(_aesKeyHex),
        ],
        const SizedBox(height: 24),

        // ── Section: Encrypt / Decrypt ───────────────────────────────────
        const _SectionHeader('2 · Encrypt / Decrypt (AES-256-GCM)'),
        const SizedBox(height: 12),
        TextField(
          controller: _aesInputCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter text to encrypt…',
          ),
          style: const TextStyle(color: _textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Encrypt',
                isLoading: _aesLoading,
                onTap: _aesEncrypt,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Decrypt',
                isLoading: _aesLoading,
                onTap: _aesDecrypt,
              ),
            ),
          ],
        ),
        if (_aesEncryptedHex.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Encrypted (hex)',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          _MonoBlock(_aesEncryptedHex.length > 80
              ? '${_aesEncryptedHex.substring(0, 80)}…'
              : _aesEncryptedHex),
        ],
        if (_aesDecrypted.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Decrypted',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          _MonoBlock(_aesDecrypted),
        ],
        if (_aesStatus.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ResultText(_aesStatus),
        ],
        const SizedBox(height: 24),

        // ── Section: PBKDF2 ──────────────────────────────────────────────
        const _SectionHeader('3 · PBKDF2 Key Derivation (SHA-256)'),
        const SizedBox(height: 8),
        const Text(
          'Derive a 256-bit key from a password using 100K iterations.',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pbkdf2PassCtrl,
          decoration: const InputDecoration(hintText: 'Password'),
          style: const TextStyle(color: _textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pbkdf2SaltCtrl,
          decoration: const InputDecoration(hintText: 'Salt'),
          style: const TextStyle(color: _textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Derive Key (PBKDF2)',
          isLoading: _pbkdf2Loading,
          onTap: _pbkdf2Derive,
        ),
        if (_pbkdf2Key.isNotEmpty) ...[
          const SizedBox(height: 8),
          _MonoBlock(_pbkdf2Key),
        ],
        const SizedBox(height: 24),

        // ── Section: Digest ──────────────────────────────────────────────
        const _SectionHeader('4 · Hash Digest'),
        const SizedBox(height: 8),
        const Text(
          'Compute SHA-256 hash of sample data using native CryptoKit / java.security.',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: _accent),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

class _MonoBlock extends StatelessWidget {
  const _MonoBlock(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _monoBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _keyGreen,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isError = text.startsWith('Error');
    return Text(
      text,
      style: TextStyle(
        color: isError ? _error : _success,
        fontSize: 13,
      ),
    );
  }
}
