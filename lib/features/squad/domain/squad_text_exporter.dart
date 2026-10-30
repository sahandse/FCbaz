import 'package:fcbaz/src/utils/persian_formatters.dart';

import 'chemistry_engine.dart';
import 'squad_models.dart';

/// Builds a plain-text squad summary from the saved squad only, so nothing
/// that is not in the squad appears in the shared text.
class SquadTextExporter {
  const SquadTextExporter({this.engine = const ChemistryEngineFC27()});

  final ChemistryEngineFC27 engine;

  String export(SquadStateModel squad) {
    final formation = Formations.byId(squad.formationId);
    final players = squad.playersBySlot;
    final name = squad.name.trim().isEmpty ? 'ترکیب من' : squad.name.trim();
    final buffer = StringBuffer()
      ..writeln('FCBaz • $name')
      ..writeln('FC 27 • آرایش ${formation.name}');

    if (players.isEmpty) {
      buffer
        ..writeln()
        ..writeln('هنوز بازیکنی به ترکیب اضافه نشده است.');
    } else {
      final chemistry = engine.calculate(
        formation: formation,
        playersBySlot: players,
        manager: squad.manager,
      );
      final ratings = players.values.map((p) => p.rating).toList();
      final average =
          (ratings.fold<int>(0, (sum, rating) => sum + rating) / ratings.length)
              .round();
      buffer
        ..writeln(
          'ریتینگ میانگین: ${faDigits(average)} • '
          'شیمی: ${faDigits('${chemistry.total}/${chemistry.maxForFilledPlayers}')}',
        )
        ..writeln();

      for (final slot in formation.slots) {
        final player = players[slot.id];
        if (player == null) continue;
        buffer.writeln(
          '${slot.position} | ${player.name} | ${faDigits(player.rating)}',
        );
      }

      final missingPositions = [
        for (final slot in formation.slots)
          if (!players.containsKey(slot.id)) slot.position,
      ];
      if (missingPositions.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('جای خالی: ${missingPositions.join('، ')}');
      }
    }

    final manager = squad.manager;
    if (manager != null && !manager.isEmpty) {
      final parts = [
        if (manager.name.trim().isNotEmpty) manager.name.trim(),
        if (manager.nationName.trim().isNotEmpty) manager.nationName.trim(),
        if (manager.leagueName.trim().isNotEmpty) manager.leagueName.trim(),
      ];
      if (parts.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('سرمربی: ${parts.join(' • ')}');
      }
    }

    final tactics = squad.tactics;
    if (tactics.hasStructuredTactics) {
      final parts = [
        if (tactics.buildUpStyle.trim().isNotEmpty) tactics.buildUpStyle.trim(),
        if (tactics.defensiveApproach.trim().isNotEmpty)
          tactics.defensiveApproach.trim(),
        if (tactics.lineHeight != null) 'خط ${faDigits(tactics.lineHeight!)}',
      ];
      if (parts.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('تاکتیک: ${parts.join(' • ')}');
      }
    }

    buffer
      ..writeln()
      ..writeln('ساخته‌شده با FCBaz');

    return buffer.toString().trimRight();
  }
}
