
// =============================
// widgets/team_card.dart
// =============================
import 'package:flutter/material.dart';

class TeamCard extends StatelessWidget {
  final int id;
  final VoidCallback onRemove;
  const TeamCard({super.key, required this.id, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

    return SizedBox(
      width: 140,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 72),
                ),
              ),
              const SizedBox(height: 8),
              Text('#$id', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Remove'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
