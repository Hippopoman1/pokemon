
// =============================
// pages/team_saved_detail_page.dart
// =============================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import '../widgets/team_card.dart';

class TeamSavedDetailPage extends StatelessWidget {
  final String teamId;
  const TeamSavedDetailPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamController>();
    final t = c.savedTeams.firstWhere((e) => e.id == teamId);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        actions: [
          IconButton(
            tooltip: 'Load as Working Team',
            onPressed: () {
              c.loadSavedIntoWorking(t);
              Get.snackbar('Loaded', 'Loaded team "${t.name}"');
            },
            icon: const Icon(Icons.download_done),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () {
              c.deleteTeam(t.id);
              Get.back();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: t.memberIds
                  .map((id) => TeamCard(id: id, onRemove: () {}))
                  .toList(),
            ),
            const Spacer(),
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  c.loadSavedIntoWorking(t);
                  Get.offAllNamed('/preview');
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit This Team'),
              ),
            )
          ],
        ),
      ),
    );
  }
}