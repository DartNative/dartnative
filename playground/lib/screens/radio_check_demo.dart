import 'package:dartnative/dartnative.dart';
import 'home/demo_ui.dart';

class RadioCheckDemo extends StatefulWidget {
  const RadioCheckDemo({super.key});

  @override
  State<RadioCheckDemo> createState() => _RadioCheckDemoState();
}

class _RadioCheckDemoState extends State<RadioCheckDemo> {
  // Checkbox state
  bool? _check1 = false;
  bool? _check2 = true;
  bool? _check3 = false;

  // Radio state
  String _radioSelected = 'b';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kHomeBg,
      extendBodyBehindAppBar: isIOS26,
      appBar: AppBar(
        title: Text(
          'Radio / Check Buttons',
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

            // ── Checkboxes ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Checkbox',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _checkRow(
                    'Option A',
                    _check1,
                    (v) => setState(() => _check1 = v),
                  ),
                  _checkRow(
                    'Option B (checked)',
                    _check2,
                    (v) => setState(() => _check2 = v),
                  ),
                  _checkRow(
                    'Option C',
                    _check3,
                    (v) => setState(() => _check3 = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Single Radio button test (WITH callback) ─────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Radio (with onChanged)',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kRowBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<String>(
                        value: 'a',
                        groupValue: _radioSelected,
                        onChanged: (v) => setState(() => _radioSelected = v!),
                        activeColor: const Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Option A',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'b',
                        groupValue: _radioSelected,
                        onChanged: (v) => setState(() => _radioSelected = v!),
                        activeColor: const Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Option B',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _checkRow(String label, bool? value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: kTextPrimary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
