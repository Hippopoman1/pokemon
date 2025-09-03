// =============================
// controllers/team_controller.dart
// =============================
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/pokemon.dart';
import 'dart:convert';

class SavedTeam {
  final String id; // unique id
  final String name;
  final List<int> memberIds;
  SavedTeam({required this.id, required this.name, required this.memberIds});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberIds': memberIds,
      };

  static SavedTeam fromJson(Map<String, dynamic> m) => SavedTeam(
        id: m['id'] as String,
        name: m['name'] as String,
        memberIds: (m['memberIds'] as List).cast<int>(),
      );
}

class TeamController extends GetxController {
  static const int maxTeamSize = 3;
  static const String storageKeyTeamIds = 'team_ids';
  static const String storageKeyTeamName = 'team_name';
  static const String storageKeySavedTeams = 'saved_teams_v1';

  final box = GetStorage();

  final RxList<int> selectedIds = <int>[].obs; // current working team IDs
  final RxString teamName = 'My Team'.obs;
  final RxString query = ''.obs; // search text

  // Saved teams list
  final RxList<SavedTeam> savedTeams = <SavedTeam>[].obs;

  @override
  void onInit() {
    super.onInit();
    // load working team
    final savedIds = (box.read<List>(storageKeyTeamIds) ?? []).cast<int>();
    selectedIds.assignAll(savedIds);

    final savedName = box.read<String>(storageKeyTeamName);
    if (savedName != null && savedName.trim().isNotEmpty) {
      teamName.value = savedName;
    }

    // load saved teams
    final raw = box.read<String>(storageKeySavedTeams);
    if (raw != null) {
      try {
        final List list = jsonDecode(raw) as List;
        savedTeams.assignAll(list.map((e) => SavedTeam.fromJson(Map<String, dynamic>.from(e))).toList());
      } catch (_) {}
    }

    ever<List<int>>(selectedIds, (_) => _persistWorking());
    ever<String>(teamName, (_) => _persistWorking());
    ever<List<SavedTeam>>(savedTeams, (_) => _persistSaved());
  }

  void _persistWorking() {
    box.write(storageKeyTeamIds, selectedIds.toList());
    box.write(storageKeyTeamName, teamName.value);
  }

  void _persistSaved() {
    final s = jsonEncode(savedTeams.map((e) => e.toJson()).toList());
    box.write(storageKeySavedTeams, s);
  }

  bool isSelected(int id) => selectedIds.contains(id);

  // Core: toggle with limit = 3
  void togglePokemon(Pokemon p) {
    if (isSelected(p.id)) {
      selectedIds.remove(p.id);
      Get.snackbar('Removed', '${p.name} removed', snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 900));
    } else {
      if (selectedIds.length >= maxTeamSize) {
        Get.snackbar('Limit reached', 'You can only pick $maxTeamSize Pokémon',
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
        return;
      }
      selectedIds.add(p.id);
      Get.snackbar('Added', '${p.name} added', snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 900));
    }
  }

  void setTeamName(String name) => teamName.value = name;
  void resetTeam() => selectedIds.clear();

  // Save as NEW team (legacy)
  void saveCurrentAsNew(String name) {
    if (selectedIds.isEmpty) {
      Get.snackbar('Empty team', 'Pick at least 1 Pokémon');
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final t = SavedTeam(id: id, name: name.trim().isEmpty ? 'My Team' : name.trim(), memberIds: selectedIds.toList());
    savedTeams.add(t);
    Get.snackbar('Saved', 'Team "${t.name}" saved');
  }

  // NEW: Save and return teamId (for immediate navigation)
  String saveCurrentAndGetId([String? name]) {
    if (selectedIds.isEmpty) {
      Get.snackbar('Empty team', 'Pick at least 1 Pokémon');
      return '';
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final effectiveName = (name ?? teamName.value).trim();
    final t = SavedTeam(
      id: id,
      name: effectiveName.isEmpty ? 'My Team' : effectiveName,
      memberIds: selectedIds.toList(),
    );
    savedTeams.add(t);
    return id;
  }

  // Overwrite an existing team by id
  void overwriteTeam(String teamId, {String? newName}) {
    final idx = savedTeams.indexWhere((e) => e.id == teamId);
    if (idx == -1) return;
    final updated = SavedTeam(
      id: savedTeams[idx].id,
      name: (newName ?? savedTeams[idx].name),
      memberIds: selectedIds.toList(),
    );
    savedTeams[idx] = updated;
    Get.snackbar('Updated', 'Team "${updated.name}" updated');
  }

  void deleteTeam(String teamId) {
    savedTeams.removeWhere((e) => e.id == teamId);
  }

  void loadSavedIntoWorking(SavedTeam t) {
    selectedIds.assignAll(t.memberIds);
    teamName.value = t.name;
  }
}

