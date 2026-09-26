import 'package:flutter/material.dart';

import '../domain/squad_models.dart';

class TacticsEditorSheet extends StatefulWidget {
  const TacticsEditorSheet({
    required this.current,
    super.key,
  });

  final TacticProfile current;

  @override
  State<TacticsEditorSheet> createState() => _TacticsEditorSheetState();
}

class _TacticsEditorSheetState extends State<TacticsEditorSheet> {
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController notes;
  late String buildUpStyle;
  late String defensiveApproach;
  late double lineHeight;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.current.name);
    code = TextEditingController(text: widget.current.code);
    notes = TextEditingController(text: widget.current.notes);
    buildUpStyle = TacticProfile.buildUpStyles.contains(widget.current.buildUpStyle)
        ? widget.current.buildUpStyle
        : 'Balanced';
    defensiveApproach = TacticProfile.defensiveApproaches.contains(widget.current.defensiveApproach)
        ? widget.current.defensiveApproach
        : 'Balanced';
    lineHeight = (widget.current.lineHeight ?? 50).toDouble();
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    notes.dispose();
    super.dispose();
  }

  String _fa(String value) {
    const labels = {
      'Balanced': 'متعادل',
      'Counter': 'ضدحمله',
      'Short Passing': 'پاس کوتاه',
      'Deep': 'عمیق',
      'High': 'بالا',
      'Aggressive': 'تهاجمی',
    };
    return labels[value] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('تاکتیک تیم', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'فقط تنظیماتی که خودت داخل بازی استفاده می‌کنی ذخیره می‌شوند؛ FCBaz تاکتیک ساختگی تولید نمی‌کند.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام پلن'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'کد تاکتیک',
                hintText: 'کد واقعی داخل بازی',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: buildUpStyle,
              decoration: const InputDecoration(labelText: 'ساخت بازی'),
              items: [
                for (final value in TacticProfile.buildUpStyles)
                  DropdownMenuItem(value: value, child: Text(_fa(value))),
              ],
              onChanged: (value) {
                if (value != null) setState(() => buildUpStyle = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: defensiveApproach,
              decoration: const InputDecoration(labelText: 'رویکرد دفاعی'),
              items: [
                for (final value in TacticProfile.defensiveApproaches)
                  DropdownMenuItem(value: value, child: Text(_fa(value))),
              ],
              onChanged: (value) {
                if (value != null) setState(() => defensiveApproach = value);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'ارتفاع خط دفاعی',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(lineHeight.round().toString()),
              ],
            ),
            Slider(
              value: lineHeight,
              min: 1,
              max: 100,
              divisions: 99,
              label: lineHeight.round().toString(),
              onChanged: (value) => setState(() => lineHeight = value),
            ),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'یادداشت'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                TacticProfile(
                  name: name.text.trim().isEmpty ? 'پلن اصلی' : name.text.trim(),
                  code: code.text.trim(),
                  buildUpStyle: buildUpStyle,
                  defensiveApproach: defensiveApproach,
                  lineHeight: lineHeight.round(),
                  notes: notes.text.trim(),
                ),
              ),
              icon: const Icon(Icons.save_rounded),
              label: const Text('ذخیره تاکتیک'),
            ),
          ],
        ),
      ),
    );
  }
}
