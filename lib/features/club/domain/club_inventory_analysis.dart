import '../data/my_club_repository.dart';

enum ClubTradeFilter { all, tradeable, untradeable }

enum ClubSort { rating, name, acquisitionPrice }

class ClubInventoryFilter {
  const ClubInventoryFilter({
    this.query = '',
    this.position = '',
    this.trade = ClubTradeFilter.all,
    this.sort = ClubSort.rating,
  });

  final String query;
  final String position;
  final ClubTradeFilter trade;
  final ClubSort sort;

  ClubInventoryFilter copyWith({
    String? query,
    String? position,
    ClubTradeFilter? trade,
    ClubSort? sort,
  }) => ClubInventoryFilter(
        query: query ?? this.query,
        position: position ?? this.position,
        trade: trade ?? this.trade,
        sort: sort ?? this.sort,
      );
}

class ClubDuplicateGroup {
  const ClubDuplicateGroup({required this.key, required this.items});

  final String key;
  final List<MyClubItem> items;
}

class ClubInventoryAnalysis {
  const ClubInventoryAnalysis();

  List<MyClubItem> filter(
    List<MyClubItem> source,
    ClubInventoryFilter filter,
  ) {
    final q = filter.query.trim().toLowerCase();
    final position = filter.position.trim().toUpperCase();

    final result = source.where((item) {
      if (q.isNotEmpty) {
        final haystack = [
          item.playerName,
          item.clubName,
          item.leagueName,
          item.nationName,
          item.version,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }

      if (position.isNotEmpty) {
        final positions = <String>{
          item.position.toUpperCase(),
          ...item.positions.map((e) => e.toUpperCase()),
        };
        if (!positions.contains(position)) return false;
      }

      if (filter.trade == ClubTradeFilter.tradeable && item.untradeable) {
        return false;
      }
      if (filter.trade == ClubTradeFilter.untradeable && !item.untradeable) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sort) {
      case ClubSort.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case ClubSort.name:
        result.sort((a, b) => a.playerName.compareTo(b.playerName));
      case ClubSort.acquisitionPrice:
        result.sort((a, b) => b.acquisitionPrice.compareTo(a.acquisitionPrice));
    }
    return result;
  }

  List<ClubDuplicateGroup> duplicateGroups(List<MyClubItem> source) {
    final buckets = <String, List<MyClubItem>>{};
    for (final item in source) {
      final key = _duplicateKey(item);
      buckets.putIfAbsent(key, () => <MyClubItem>[]).add(item);
    }

    final groups = buckets.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => ClubDuplicateGroup(key: entry.key, items: entry.value))
        .toList();
    groups.sort((a, b) => b.items.length.compareTo(a.items.length));
    return groups;
  }

  Set<String> positions(List<MyClubItem> source) {
    final values = <String>{};
    for (final item in source) {
      if (item.position.trim().isNotEmpty) values.add(item.position.toUpperCase());
      values.addAll(item.positions.where((e) => e.trim().isNotEmpty).map((e) => e.toUpperCase()));
    }
    final sorted = values.toList()..sort();
    return sorted.toSet();
  }

  String _duplicateKey(MyClubItem item) {
    final name = item.playerName.trim().toLowerCase();
    final version = item.version.trim().toLowerCase();
    return '$name|${item.rating}|${item.position.toUpperCase()}|$version';
  }
}
