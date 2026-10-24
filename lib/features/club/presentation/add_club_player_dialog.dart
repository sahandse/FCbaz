import 'package:flutter/material.dart';

import '../../players/domain/player.dart';

class AddClubPlayerResult {
  const AddClubPlayerResult({required this.price, required this.untradeable});

  final int price;
  final bool untradeable;
}

class AddClubPlayerDialog extends StatefulWidget {
  const AddClubPlayerDialog({required this.player, super.key});

  final Player player;

  static Future<AddClubPlayerResult?> show(
    BuildContext context,
    Player player,
  ) {
    return showDialog<AddClubPlayerResult>(
      context: context,
      builder: (_) => AddClubPlayerDialog(player: player),
    );
  }

  @override
  State<AddClubPlayerDialog> createState() => _AddClubPlayerDialogState();
}

class _AddClubPlayerDialogState extends State<AddClubPlayerDialog> {
  final controller = TextEditingController();
  bool untradeable = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.player.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.player.rating} • ${widget.player.position}',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: untradeable,
            onChanged: (value) => setState(() => untradeable = value),
            title: const Text('غیرقابل فروش'),
          ),
          if (!untradeable)
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'قیمت خرید واقعی',
                suffixText: 'Coins',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            AddClubPlayerResult(
              price: untradeable
                  ? 0
                  : int.tryParse(controller.text.trim()) ?? 0,
              untradeable: untradeable,
            ),
          ),
          child: const Text('ذخیره'),
        ),
      ],
    );
  }
}
