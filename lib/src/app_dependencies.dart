import '../features/club/data/my_club_repository.dart';
import '../features/dns/data/dns_repository.dart';
import '../features/evolutions/data/evolution_repository.dart';
import '../features/home/home_repository.dart';
import '../features/home/objective_progress_repository.dart';
import '../features/market/data/market_repository.dart';
import '../features/market/data/price_snapshot_store.dart';
import '../features/market/data/watchlist_repository.dart';
import '../features/meta/data/meta_repository.dart';
import '../features/navigation/app_navigation_repository.dart';
import '../features/news/data/news_repository.dart';
import '../features/notifications/background_sync_status_repository.dart';
import '../features/notifications/notification_preferences_repository.dart';
import '../features/notifications/notification_repository.dart';
import '../features/notifications/price_alert_service.dart';
import '../features/players/data/player_repository.dart';
import '../features/players/data/player_review_repository.dart';
import '../features/sbc/data/sbc_repository.dart';
import '../features/search/search_history_repository.dart';
import '../features/settings/app_settings_repository.dart';
import '../features/settings/local_profile_repository.dart';
import '../features/settings/update_repository.dart';
import '../features/squad/data/squad_repository.dart';

/// Lazily created, app-wide repository singletons.
///
/// Screens share these instances instead of constructing their own copies, so
/// caches, persisted settings and in-flight loads stay consistent across tabs.
class AppDependencies {
  AppDependencies();

  static final AppDependencies instance = AppDependencies();

  late final PlayerRepository players = PlayerRepository();
  late final PlayerReviewRepository reviews = PlayerReviewRepository();
  late final NewsRepository news = NewsRepository();
  late final MarketRepository market = MarketRepository();
  late final WatchlistRepository watchlist = WatchlistRepository();
  late final PriceSnapshotStore priceSnapshots = PriceSnapshotStore();
  late final SquadRepository squads = SquadRepository();
  late final MyClubRepository club = MyClubRepository();
  late final SbcRepository sbc = SbcRepository();
  late final EvolutionRepository evolutions = EvolutionRepository();
  late final MetaRepository meta = MetaRepository();
  late final HomeRepository home = HomeRepository();
  late final ObjectiveProgressRepository objectives =
      ObjectiveProgressRepository();
  late final NotificationRepository notifications = NotificationRepository();
  late final NotificationPreferencesRepository notificationPreferences =
      NotificationPreferencesRepository();
  late final PriceAlertService priceAlerts = PriceAlertService(
    marketRepository: market,
    watchlistRepository: watchlist,
    notificationRepository: notifications,
    settingsRepository: settings,
  );
  late final BackgroundSyncStatusRepository syncStatus =
      BackgroundSyncStatusRepository();
  late final AppSettingsRepository settings = AppSettingsRepository();
  late final LocalProfileRepository profile = LocalProfileRepository();
  late final UpdateRepository update = UpdateRepository();
  late final SearchHistoryRepository history = SearchHistoryRepository();
  late final AppNavigationRepository navigation = AppNavigationRepository();
  late final DnsRepository dns = const DnsRepository();
}
