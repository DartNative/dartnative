class Contact {
  final String name;
  final String role;

  const Contact(this.name, this.role);

  String get initials => name.split(' ').map((part) => part[0]).join();
}

const _first = ['Ada', 'Alan', 'Grace', 'Linus', 'Edsger', 'Barbara', 'Ken', 'Margaret'];
const _last = ['Lee', 'Park', 'Diaz', 'Kim', 'Ross'];
const _roles = ['Design', 'Platform', 'Support', 'Sales', 'Research'];

final List<Contact> contacts = List.generate(
  40,
  (i) => Contact('${_first[i % 8]} ${_last[i % 5]}', _roles[(i ~/ 8) % 5]),
);
