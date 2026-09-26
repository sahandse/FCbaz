import 'package:flutter/material.dart';

import '../domain/squad_models.dart';

class FormationPickerSheet extends StatelessWidget {
  const FormationPickerSheet({
    required this.currentId,
    super.key,
  });

  final String currentId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'انتخاب آرایش',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${Formations.all.length} آرایش',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.18,
                ),
                itemCount: Formations.all.length,
                itemBuilder: (context, index) {
                  final formation = Formations.all[index];
                  final selected = formation.id == currentId;
                  return _FormationCard(
                    formation: formation,
                    selected: selected,
                    onTap: () => Navigator.pop(context, formation.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationCard extends StatelessWidget {
  const _FormationCard({
    required this.formation,
    required this.selected,
    required this.onTap,
  });

  final FormationDefinition formation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: .55)
          : scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formation.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: scheme.outline.withValues(alpha: .45),
                            ),
                          ),
                        ),
                      ),
                      for (final slot in formation.slots)
                        Positioned(
                          left: (constraints.maxWidth - 20) * slot.x,
                          top: (constraints.maxHeight - 20) * slot.y,
                          child: Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              slot.position.length > 2
                                  ? slot.position.substring(0, 2)
                                  : slot.position,
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
