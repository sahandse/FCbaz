import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dns_repository.dart';
import '../domain/dns_model.dart';
import 'package:fcbaz/src/app_dependencies.dart';

class DnsScreen extends StatefulWidget {
  const DnsScreen({super.key});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  final repository = AppDependencies.instance.dns;
  String selectedCategory = 'all';
  String searchQuery = '';
  bool showTutorial = true;
  final TextEditingController searchController = TextEditingController();
  final Map<String, int?> _livePings = {};
  final Set<String> _pingingServers = {};
  bool _isTestingAll = false;
  bool _sortByPing = false;

  Future<void> _pingServer(DnsServer server) async {
    if (_pingingServers.contains(server.id)) return;
    setState(() => _pingingServers.add(server.id));
    final ping = await repository.measurePing(server.primary);
    if (mounted) {
      setState(() {
        _pingingServers.remove(server.id);
        _livePings[server.id] = ping;
      });
    }
  }

  Future<void> _testAllPings(List<DnsServer> servers) async {
    if (_isTestingAll) return;
    setState(() => _isTestingAll = true);
    for (final s in servers) {
      if (!mounted) break;
      await _pingServer(s);
    }
    if (mounted) {
      setState(() => _isTestingAll = false);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('$label ($text) کپی شد'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var servers = repository.filter(
      category: selectedCategory,
      query: searchQuery,
    );
    if (_sortByPing) {
      servers = List.of(servers)
        ..sort((a, b) {
          final pA = _livePings[a.id];
          final pB = _livePings[b.id];
          if (pA != null && pB != null) return pA.compareTo(pB);
          if (pA != null) return -1;
          if (pB != null) return 1;
          return 0;
        });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DNS گیمینگ و ضدتحریم'),
        actions: [
          IconButton(
            tooltip: showTutorial ? 'مخفی کردن راهنما' : 'نمایش راهنمای تنظیم',
            icon: Icon(
              showTutorial ? Icons.help_rounded : Icons.help_outline_rounded,
            ),
            onPressed: () => setState(() => showTutorial = !showTutorial),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (showTutorial) ...[
            _TutorialCard(onClose: () => setState(() => showTutorial = false)),
            const SizedBox(height: 14),
          ],
          _SearchBar(
            controller: searchController,
            onChanged: (val) => setState(() => searchQuery = val),
            onClear: () {
              searchController.clear();
              setState(() => searchQuery = '');
            },
          ),
          const SizedBox(height: 12),
          _CategoryFilterChips(
            selectedCategory: selectedCategory,
            repository: repository,
            onSelected: (cat) => setState(() => selectedCategory = cat),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.primary.withValues(alpha: .2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ تست پینگ زنده',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isTestingAll
                            ? 'در حال پینگ گرفتن...'
                            : 'سنجش تاخیر واقعی پکت‌ها از نت شما',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_livePings.isNotEmpty) ...[
                  IconButton(
                    tooltip: _sortByPing
                        ? 'حالت عادی'
                        : 'مرتب‌سازی بر اساس کمترین پینگ',
                    icon: Icon(
                      _sortByPing
                          ? Icons.sort_rounded
                          : Icons.filter_list_rounded,
                      color: _sortByPing
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _sortByPing = !_sortByPing),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: _isTestingAll
                      ? null
                      : () => _testAllPings(servers),
                  icon: _isTestingAll
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.network_check_rounded, size: 16),
                  label: Text(
                    _isTestingAll ? 'سنجش...' : 'تست همه',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فهرست سرورهای DNS',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${servers.length} سرور فعال',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (servers.isEmpty)
            _EmptyState(
              onReset: () {
                searchController.clear();
                setState(() {
                  searchQuery = '';
                  selectedCategory = 'all';
                });
              },
            )
          else
            for (final server in servers) ...[
              _DnsCard(
                server: server,
                onCopyPrimary: () =>
                    _copyToClipboard(server.primary, 'Primary DNS'),
                onCopySecondary: () =>
                    _copyToClipboard(server.secondary, 'Secondary DNS'),
                onCopyBoth: () => _copyToClipboard(
                  'Primary: ${server.primary}\nSecondary: ${server.secondary}',
                  'هر دو DNS',
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: .24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'راهنمای تنظیم سریع DNS در PS5 و کنسول',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _StepRow(
            num: '۱',
            text: 'وارد Settings کنسول شده و بخش Network را باز کنید.',
          ),
          const _StepRow(
            num: '۲',
            text: 'به Settings > Set Up Internet Connection بروید.',
          ),
          const _StepRow(
            num: '۳',
            text:
                'روی وای‌فای یا کابل متصل دکمه Options را زده و Advanced Settings را انتخاب کنید.',
          ),
          const _StepRow(
            num: '۴',
            text:
                'بخش DNS Settings را روی Manual قرار داده و Primary و Secondary را وارد کنید.',
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.num, required this.text});
  final String num;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              num,
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'جستجوی نام دی‌ان‌اس (مثلاً الکترو، رادار، کلودفلر)...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.selectedCategory,
    required this.repository,
    required this.onSelected,
  });

  final String selectedCategory;
  final DnsRepository repository;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('all', 'همه', repository.countForCategory('all')),
      (
        'anti-sanction',
        '🇮🇷 ضدتحریم گیمینگ',
        repository.countForCategory('anti-sanction'),
      ),
      ('speed', '⚡ سریع و کم‌پینگ', repository.countForCategory('speed')),
      (
        'stability',
        '🛡️ پایدار و امن',
        repository.countForCategory('stability'),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              selected: isSelected,
              label: Text('${cat.$2} (${cat.$3})'),
              onSelected: (_) => onSelected(cat.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DnsCard extends StatelessWidget {
  const _DnsCard({
    required this.server,
    required this.onCopyPrimary,
    required this.onCopySecondary,
    required this.onCopyBoth,
  });

  final DnsServer server;
  final VoidCallback onCopyPrimary;
  final VoidCallback onCopySecondary;
  final VoidCallback onCopyBoth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAntiSanction = server.category == 'anti-sanction';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAntiSanction
              ? scheme.primary.withValues(alpha: .32)
              : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        server.nameEn,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAntiSanction
                        ? scheme.primary.withValues(alpha: .18)
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    server.badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isAntiSanction ? scheme.primary : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IpBox(
                    label: 'Primary DNS',
                    ip: server.primary,
                    onCopy: onCopyPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IpBox(
                    label: 'Secondary DNS',
                    ip: server.secondary,
                    onCopy: onCopySecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  'پینگ: ${server.ping}',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCopyBoth,
                  icon: const Icon(Icons.copy_all_rounded, size: 14),
                  label: const Text(
                    'کپی هر دو',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              server.desc,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'مناسب برای: ${server.suitable}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IpBox extends StatelessWidget {
  const _IpBox({required this.label, required this.ip, required this.onCopy});

  final String label;
  final String ip;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ip,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: .5,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'سرور DNS مورد نظر یافت نشد',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('لطفاً عبارت جستجو یا فیلتر دسته‌بندی را تغییر دهید.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onReset,
            child: const Text('مشاهده همه DNSها'),
          ),
        ],
      ),
    );
  }
}
