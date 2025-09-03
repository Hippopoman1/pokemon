// =============================
// widgets/pokemon_tile.dart
// =============================
import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonTile extends StatelessWidget {
  final Pokemon pokemon;
  final bool selected;
  final VoidCallback onTap;

  const PokemonTile({
    super.key,
    required this.pokemon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: selected ? 0.98 : 1.0,
      child: Card(
        elevation: selected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    pokemon.imageUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pokemon.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                AnimatedContainer
                (
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? Icons.check : Icons.add,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selected ? 'Select' : 'Add', // เปลี่ยนข้อความตามที่ขอ
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
