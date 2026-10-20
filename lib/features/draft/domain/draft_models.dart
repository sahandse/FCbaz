import 'dart:math';

import '../../players/domain/player.dart';

class DraftSlot {
  const DraftSlot({
    required this.index,
    required this.position,
    required this.category,
    required this.titleFa,
  });

  final int index;
  final String position;
  final String category; // 'GK', 'DEF', 'MID', 'ATT'
  final String titleFa;
}

class DraftState {
  DraftState({
    required this.formation,
    required this.slots,
    Map<int, Player>? picks,
    this.currentSlotIndex = 0,
    this.currentChoices = const [],
  }) : picks = picks ?? {};

  final String formation;
  final List<DraftSlot> slots;
  final Map<int, Player> picks;
  int currentSlotIndex;
  List<Player> currentChoices;

  bool get isCompleted => currentSlotIndex >= slots.length;

  int get teamRating {
    final list = picks.values.toList();
    if (list.isEmpty) return 0;
    final sum = list.fold<int>(0, (prev, p) => prev + p.rating);
    return (sum / list.length).round();
  }

  int get teamChemistry {
    final list = picks.values.toList();
    if (list.isEmpty) return 0;
    int total = 0;
    for (final p in list) {
      double score = 0;
      for (final q in list) {
        if (identical(p, q)) continue;
        if (p.clubName.isNotEmpty && p.clubName == q.clubName) {
          score += 2.0;
        } else if (p.leagueName.isNotEmpty && p.leagueName == q.leagueName) {
          score += 1.5;
        } else if (p.nationName.isNotEmpty && p.nationName == q.nationName) {
          score += 1.0;
        }
      }
      total += min(3, (score / 2.0).floor());
    }
    return min(33, total);
  }
}

class DraftSimulatorService {
  const DraftSimulatorService();

  static const List<DraftSlot> defaultSlots = [
    DraftSlot(index: 0, position: 'GK', category: 'GK', titleFa: 'دروازه‌بان'),
    DraftSlot(index: 1, position: 'RB', category: 'DEF', titleFa: 'مدافع راست'),
    DraftSlot(index: 2, position: 'CB', category: 'DEF', titleFa: 'مدافع میانی ۱'),
    DraftSlot(index: 3, position: 'CB', category: 'DEF', titleFa: 'مدافع میانی ۲'),
    DraftSlot(index: 4, position: 'LB', category: 'DEF', titleFa: 'مدافع چپ'),
    DraftSlot(index: 5, position: 'CDM', category: 'MID', titleFa: 'هافبک دفاعی'),
    DraftSlot(index: 6, position: 'CM', category: 'MID', titleFa: 'هافبک میانی'),
    DraftSlot(index: 7, position: 'CAM', category: 'MID', titleFa: 'هافبک هجومی'),
    DraftSlot(index: 8, position: 'RW', category: 'ATT', titleFa: 'وینگر راست'),
    DraftSlot(index: 9, position: 'ST', category: 'ATT', titleFa: 'مهاجم نوک'),
    DraftSlot(index: 10, position: 'LW', category: 'ATT', titleFa: 'وینگر چپ'),
  ];

  DraftState createNewDraft({List<Player> allPlayers = const []}) {
    final state = DraftState(
      formation: '4-3-3 (Offensive)',
      slots: defaultSlots,
    );
    if (allPlayers.isNotEmpty) {
      state.currentChoices = generateChoices(state, allPlayers);
    }
    return state;
  }

  List<Player> generateChoices(DraftState state, List<Player> pool) {
    if (state.isCompleted) return [];
    final currentSlot = state.slots[state.currentSlotIndex];
    final pickedIds = state.picks.values.map((p) => p.id).toSet();

    // Filter available candidates matching positional category
    final matching = pool.where((p) {
      if (pickedIds.contains(p.id)) return false;
      return _matchesCategory(p, currentSlot);
    }).toList();

    if (matching.isEmpty) {
      // Fallback to any remaining players
      final fallback = pool.where((p) => !pickedIds.contains(p.id)).toList();
      fallback.shuffle(Random());
      return fallback.take(5).toList();
    }

    // Shuffle and pick 5 distinct candidates with good rating spread
    matching.shuffle(Random());
    return matching.take(5).toList();
  }

  bool _matchesCategory(Player p, DraftSlot slot) {
    final pos = p.position.toUpperCase();
    final allPos = p.positions.map((e) => e.toUpperCase()).toSet();
    allPos.add(pos);

    switch (slot.category) {
      case 'GK':
        return allPos.contains('GK');
      case 'DEF':
        return allPos.any((x) => ['CB', 'RB', 'LB', 'RWB', 'LWB'].contains(x));
      case 'MID':
        return allPos.any((x) => ['CDM', 'CM', 'CAM', 'RM', 'LM'].contains(x));
      case 'ATT':
        return allPos.any((x) => ['ST', 'CF', 'RW', 'LW', 'RF', 'LF'].contains(x));
      default:
        return true;
    }
  }

  void pickPlayer(DraftState state, Player player, List<Player> pool) {
    if (state.isCompleted) return;
    state.picks[state.currentSlotIndex] = player;
    state.currentSlotIndex++;
    if (!state.isCompleted) {
      state.currentChoices = generateChoices(state, pool);
    } else {
      state.currentChoices = [];
    }
  }
}
