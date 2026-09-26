import '../club/data/my_club_repository.dart';
import '../market/data/watchlist_repository.dart';
import '../squad/data/squad_repository.dart';
import 'objective_progress_repository.dart';

class HomeLocalDashboard {
  const HomeLocalDashboard({
    required this.clubCount,
    required this.tradeableCount,
    required this.watchlistCount,
    required this.reachedTargets,
    required this.savedSquads,
    required this.objectiveTasks,
    required this.completedObjectiveTasks,
  });

  final int clubCount;
  final int tradeableCount;
  final int watchlistCount;
  final int reachedTargets;
  final int savedSquads;
  final int objectiveTasks;
  final int completedObjectiveTasks;

  double get objectiveProgress => objectiveTasks == 0
      ? 0
      : completedObjectiveTasks / objectiveTasks;
}

class HomeLocalDashboardService {
  HomeLocalDashboardService({
    MyClubRepository? clubRepository,
    WatchlistRepository? watchlistRepository,
    SquadRepository? squadRepository,
    ObjectiveProgressRepository? objectiveRepository,
  })  : clubRepository = clubRepository ?? MyClubRepository(),
        watchlistRepository = watchlistRepository ?? WatchlistRepository(),
        squadRepository = squadRepository ?? SquadRepository(),
        objectiveRepository = objectiveRepository ?? ObjectiveProgressRepository();

  final MyClubRepository clubRepository;
  final WatchlistRepository watchlistRepository;
  final SquadRepository squadRepository;
  final ObjectiveProgressRepository objectiveRepository;

  Future<HomeLocalDashboard> load() async {
    final clubFuture = clubRepository.getAll();
    final watchlistFuture = watchlistRepository.getAll();
    final squadsFuture = squadRepository.getAll();
    final objectivesFuture = objectiveRepository.getAll();

    final club = await clubFuture;
    final watchlist = await watchlistFuture;
    final squads = await squadsFuture;
    final objectives = await objectivesFuture;

    return HomeLocalDashboard(
      clubCount: club.length,
      tradeableCount: club.where((item) => !item.untradeable).length,
      watchlistCount: watchlist.length,
      reachedTargets: watchlist.where((item) => item.targetReached).length,
      savedSquads: squads.length,
      objectiveTasks: objectives.length,
      completedObjectiveTasks:
          objectives.values.where((entry) => entry.completed).length,
    );
  }
}
