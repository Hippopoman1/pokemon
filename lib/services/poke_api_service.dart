import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  static Future<List<Pokemon>> fetchPokemonList({int limit = 151}) async {
    final res = await http.get(Uri.parse('$baseUrl/pokemon?limit=$limit'));
    if (res.statusCode != 200) throw Exception('Failed to fetch Pokémon');

    final data = json.decode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;

    return results.asMap().entries.map((entry) {
      final idx = entry.key + 1; // id inferred from index
      final name = (entry.value['name'] as String);
      final imageUrl =
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$idx.png';
      return Pokemon(id: idx, name: capitalize(name), imageUrl: imageUrl);
    }).toList();
  }
}
