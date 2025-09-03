
// =============================
// pages/saved_teams_page.dart
// =============================
// =============================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import 'team_saved_detail_page.dart';

class SavedTeamsPage extends StatelessWidget {
  const SavedTeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Teams')),
      body: Obx(() {
        if (c.savedTeams.isEmpty) {
          return const Center(child: Text('No saved teams yet'));
        }
        return ListView.separated(
          itemCount: c.savedTeams.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final t = c.savedTeams[i];
            return ListTile(
              title: Text(t.name),
              subtitle: Text('${t.memberIds.length} Pokémon'),
              leading: const Icon(Icons.bookmark),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => c.deleteTeam(t.id),
              ),
              onTap: () => Get.to(() => TeamSavedDetailPage(teamId: t.id)),
            );
          },
        );
      }),
    );
  }
}



