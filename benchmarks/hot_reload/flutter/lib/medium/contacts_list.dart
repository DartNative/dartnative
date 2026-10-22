import 'package:flutter/material.dart';

import 'contact_row.dart';
import 'contacts.dart';
import 'contacts_header.dart';

class ContactsList extends StatelessWidget {
  const ContactsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: contacts.length + 1,
      itemBuilder: (context, i) => i == 0
          ? ContactsHeader(count: contacts.length)
          : ContactRow(contact: contacts[i - 1], index: i - 1),
    );
  }
}
