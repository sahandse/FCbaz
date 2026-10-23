import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../players/domain/player.dart';
import 'domain/squad_models.dart';

class SquadScreenshotAnalysis {
  const SquadScreenshotAnalysis({
    required this.playersBySlot,
    required this.recognizedNames,
    required this.unmatchedNames,
    required this.sourceImagePath,
  });

  final Map<String, Player> playersBySlot;
  final List<String> recognizedNames;
  final List<String> unmatchedNames;
  final String sourceImagePath;

  int get matchedCount => playersBySlot.length;
}

class _DetectedPlayer {
  const _DetectedPlayer({
    required this.player,
    required this.x,
    required this.y,
    required this.confidence,
  });

  final Player player;
  final double x;
  final double y;
  final double confidence;
}

/// Picks a console screenshot, OCRs visible player names and maps detections
/// to the closest formation slots. The result is intentionally reviewable
/// before the current squad is changed.
class SquadScreenshotAnalyzer {
  SquadScreenshotAnalyzer({
    ImagePicker? imagePicker,
    TextRecognizer? textRecognizer,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _textRecognizer = textRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _imagePicker;
  final TextRecognizer _textRecognizer;

  Future<SquadScreenshotAnalysis?> pickAndAnalyze({
    required List<Player> catalog,
    required FormationDefinition formation,
  }) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (image == null) return null;

    final codec = await ui.instantiateImageCodec(await File(image.path).readAsBytes());
    final frame = await codec.getNextFrame();
    final width = frame.image.width.toDouble();
    final height = frame.image.height.toDouble();
    frame.image.dispose();
    codec.dispose();

    final recognized = await _textRecognizer.processImage(
      InputImage.fromFilePath(image.path),
    );

    final lines = <({String text, double x, double y})>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.length < 3) continue;
        final box = line.boundingBox;
        lines.add((
          text: text,
          x: ((box.left + box.right) / 2 / width).clamp(0.0, 1.0),
          y: ((box.top + box.bottom) / 2 / height).clamp(0.0, 1.0),
        ));
      }
    }

    final detected = <_DetectedPlayer>[];
    final unmatched = <String>[];
    final usedIds = <String>{};
    for (final line in lines) {
      final match = _matchPlayer(line.text, catalog, usedIds);
      if (match == null) {
        if (_looksLikeName(line.text)) unmatched.add(line.text);
        continue;
      }
      detected.add(_DetectedPlayer(
        player: match.$1,
        x: line.x,
        y: line.y,
        confidence: match.$2,
      ));
      usedIds.add(match.$1.id);
    }

    final placements = _assignSlots(detected, formation);
    final recognizedNames = detected
        .map((d) => d.player.name)
        .toSet()
        .toList(growable: false);

    return SquadScreenshotAnalysis(
      playersBySlot: placements,
      recognizedNames: recognizedNames,
      unmatchedNames: unmatched.toSet().take(12).toList(),
      sourceImagePath: image.path,
    );
  }

  ({Player, double})? _matchPlayer(
    String raw,
    List<Player> catalog,
    Set<String> usedIds,
  ) {
    final query = _normalize(raw);
    if (query.length < 4) return null;

    Player? best;
    var bestScore = 0.0;
    for (final player in catalog) {
      if (usedIds.contains(player.id)) continue;
      final name = _normalize(player.name);
      if (name.isEmpty) continue;
      double score;
      if (query == name) {
        score = 1;
      } else if (query.contains(name)) {
        score = math.min(query.length, name.length) / math.max(query.length, name.length);
      } else if (name.contains(query) && query.contains(' ')) {
        score = math.min(query.length, name.length) / math.max(query.length, name.length);
      } else {
        final qTokens = query.split(' ').where((e) => e.length > 1).toSet();
        final nTokens = name.split(' ').where((e) => e.length > 1).toSet();
        if (qTokens.isEmpty || nTokens.isEmpty) continue;
        final exactTokens = qTokens.intersection(nTokens).length;
        score = exactTokens / math.max(qTokens.length, nTokens.length);
        if (qTokens.length == 1 &&
            nTokens.any((n) => n == query && n.length >= 4)) {
          score = .84;
        }
        if (qTokens.any((q) =>
            nTokens.any((n) => n.startsWith(q) && q.length >= 3))) {
          score = math.max(score, .72).toDouble();
        }
      }
      if (score > bestScore) {
        best = player;
        bestScore = score;
      }
    }
    if (best == null || bestScore < .62) return null;
    return (best, bestScore);
  }

  Map<String, Player> _assignSlots(
    List<_DetectedPlayer> detected,
    FormationDefinition formation,
  ) {
    if (detected.isEmpty) return const {};
    final slots = formation.slots;
    final transforms = <(double, double) Function(double, double)>[
      (x, y) => (x, y),
      (x, y) => (1 - x, y),
      (x, y) => (x, 1 - y),
      (x, y) => (1 - x, 1 - y),
      (x, y) => (y, x),
      (x, y) => (1 - y, x),
      (x, y) => (y, 1 - x),
      (x, y) => (1 - y, 1 - x),
    ];

    Map<String, Player> bestMap = {};
    var bestCost = double.infinity;
    for (final transform in transforms) {
      final remainingSlots = [...slots];
      final map = <String, Player>{};
      var cost = 0.0;
      final sorted = [...detected]
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      for (final item in sorted) {
        if (remainingSlots.isEmpty) break;
        final point = transform(item.x, item.y);
        FormationSlot? nearest;
        var nearestDistance = double.infinity;
        for (final slot in remainingSlots) {
          final dx = point.$1 - slot.x;
          final dy = point.$2 - slot.y;
          final distance = math.sqrt(dx * dx + dy * dy);
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearest = slot;
          }
        }
        if (nearest == null) continue;
        map[nearest.id] = item.player;
        cost += nearestDistance;
        remainingSlots.remove(nearest);
      }
      if (map.isNotEmpty && cost / map.length < bestCost) {
        bestCost = cost / map.length;
        bestMap = map;
      }
    }
    return bestMap;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"['’.-]"), '')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksLikeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^a-zA-ZÀ-ž ]'), '').trim();
    return cleaned.length >= 5 && cleaned.contains(' ');
  }

  void dispose() {
    unawaited(_textRecognizer.close());
  }
}
