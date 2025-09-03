
// =============================
// pages/team_preview_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import '../widgets/team_card.dart';
import 'team_saved_detail_page.dart';

class TeamPreviewPage extends StatelessWidget {
  const TeamPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamController c = Get.find<TeamController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Preview'),
        actions: [
          IconButton(
            tooltip: 'Reset Team',
            onPressed: () => c.resetTeam(),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Obx(() => TextField(
                      controller: TextEditingController(text: c.teamName.value)
                        ..selection = TextSelection.collapsed(offset: c.teamName.value.length),
                      onSubmitted: (v) => c.setTeamName(v.trim().isNotEmpty ? v.trim() : 'My Team'),
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                      ),
                    )),
              ),
              const SizedBox(width: 12),
              Obx(() => FilledButton.icon(
                    onPressed: c.selectedIds.isEmpty ? null : () => _instantSaveAndOpen(context, c),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  )),
            ]),
            const SizedBox(height: 16),
            Obx(() {
              final ids = c.selectedIds.toList();
              if (ids.isEmpty) return const _EmptyTeam();
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ids
                    .map((id) => TeamCard(id: id, onRemove: () => c.selectedIds.remove(id)))
                    .toList(),
              );
            }),
            const Spacer(),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.list),
                label: const Text('Back to List'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _instantSaveAndOpen(BuildContext context, TeamController c) {
    final savedName = c.teamName.value;
    final id = c.saveCurrentAndGetId(savedName);
    if (id.isEmpty) return; // guard
    c.resetTeam();
    Get.off(() => TeamSavedDetailPage(teamId: id));
    Get.snackbar('Saved', 'Team "$savedName" saved');
  }
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.catching_pokemon, size: 72),
          const SizedBox(height: 10),
          Text('No Pokémon selected', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Pick up to 3 Pokémon from the list'),
        ],
      ),
    );
  }
}