import 'package:flutter/material.dart';

import 'contacts.dart';
import 'report_colour.dart';

const rowColor = Color(0xFF4A90E2);

class ContactRow extends StatelessWidget {
  final Contact contact;
  final int index;

  const ContactRow({super.key, required this.contact, required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => reportColour(rowColor));
    }
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFFFFF),
            child: Text(
              contact.initials,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.role,
                  style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFFFFFFF)),
        ],
      ),
    );
  }
}
