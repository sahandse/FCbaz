import 'package:flutter/material.dart';

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('تیم‌ساز', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Container(
          height: 430,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF103D24), Color(0xFF0A2918)],
            ),
          ),
          alignment: Alignment.center,
          child: const Text('Squad Builder FC27\nدر مرحله بعد تکمیل می‌شود', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
