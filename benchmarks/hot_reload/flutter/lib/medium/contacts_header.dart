import 'package:flutter/material.dart';

import 'header_stats.dart';

class ContactsHeader extends StatelessWidget {
  final int count;

  const ContactsHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your team',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          HeaderStats(people: count),
        ],
      ),
    );
  }
}
