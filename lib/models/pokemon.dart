class Pokemon {
  final int id;
  final String name;
  final String imageUrl; // official artwork sprite url

  Pokemon({required this.id, required this.name, required this.imageUrl});
}

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
