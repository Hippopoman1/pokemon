// =============================
// pages/pokemon_list_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import '../models/pokemon.dart';
import '../services/poke_api_service.dart';
import '../widgets/pokemon_tile.dart';
import 'saved_teams_page.dart';

class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});

  @override
  State<PokemonListPage> createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  late Future<List<Pokemon>> _future;
  final TeamController c = Get.find<TeamController>();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = PokeApiService.fetchPokemonList(limit: 151);
    _searchCtrl.addListener(() => c.query.value = _searchCtrl.text.trim());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon GO Team Builder'),
        actions: [
          IconButton(
            tooltip: 'Saved Teams',
            onPressed: () => Get.to(() => const SavedTeamsPage()),
            icon: const Icon(Icons.bookmark_added),
          ),
          IconButton(
            tooltip: 'Team Preview',
            onPressed: () => Get.toNamed('/preview'),
            icon: const Icon(Icons.groups),
          ),
          IconButton(
            tooltip: 'About',
            onPressed: () => Get.toNamed('/about'),
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search Pokémon…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Pokemon>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final list = snapshot.data ?? [];

                // Obx ตรงนี้ช่วยให้กรองผลตาม query แบบ reactive
                return Obx(() {
                  final q = c.query.value.toLowerCase();
                  final filtered = q.isEmpty
                      ? list
                      : list
                            .where((p) => p.name.toLowerCase().contains(q))
                            .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];

                      // Obx แยกต่อรายแถว -> แค่แถวที่ถูกกดจะรีเฟรชเป็น Select ทันที
                      return Obx(() {
                        final selected = c.isSelected(p.id);
                        return PokemonTile(
                          pokemon: p,
                          selected: selected,
                          onTap: () => c.togglePokemon(p),
                        );
                      });
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: () => Get.toNamed('/preview'),
          icon: const Icon(Icons.arrow_forward),
          label: Text(
            'Preview (${c.selectedIds.length}/${TeamController.maxTeamSize})',
          ),
        ),
      ),
    );
  }
}
