import 'package:flutter/material.dart';

import 'stat_chip.dart';

class HeaderStats extends StatelessWidget {
  final int people;

  const HeaderStats({super.key, required this.people});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatChip(value: '$people', label: 'people'),
        const SizedBox(width: 8),
        const StatChip(value: '8', label: 'teams'),
        const SizedBox(width: 8),
        const StatChip(value: '5', label: 'cities'),
      ],
    );
  }
}
