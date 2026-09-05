import 'package:dartnative/dartnative.dart';

import '../api/auth_service.dart';
import '../utils/constants.dart';
import '../utils/shared_prefs.dart';
import '../widgets/field_shell.dart';
import 'home_screen.dart';

/// New users land here after their first sign in: pick a name and a
/// username, then enter the app. The profile is saved to the `profiles`
/// table in Supabase (see the README for the table definition).
class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key, this.prefillName});

  /// The name Apple or Google returned, prefilled so most users just
  /// confirm it.
  final String? prefillName;

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.prefillName ?? '');
    _username = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    final username = _username.text.trim().toLowerCase();
    if (name.isEmpty || username.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.saveProfile(name: name, username: username);
      await SharedPrefs.instance.setBool(kPrefOnboardingComplete, true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRoute(builder: (_) => const HomeScreen(), settings: '/home'),
      );
    } catch (e) {
      dnLog('CreateProfileScreen: save failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save your profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      appBar: AppBar(
        title: const Text(
          'Create your profile',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF101014),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How should we call you?',
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 15),
            ),
            const SizedBox(height: 12),
            FieldShell(
              color: const Color(0xFF1C1C22),
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'Your name',
                  hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                ),
                style:
                    const TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
              ),
            ),
            const SizedBox(height: 20),
            FieldShell(
              color: const Color(0xFF1C1C22),
              child: TextField(
                controller: _username,
                decoration: const InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                ),
                autocorrect: false,
                style:
                    const TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14),
              ),
            ],
            const SizedBox(height: 28),
            Button(
              title: _saving ? 'Saving...' : 'Continue',
              color: const Color(0xFFFFFFFF),
              foregroundColor: const Color(0xFF101014),
              height: 50,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
