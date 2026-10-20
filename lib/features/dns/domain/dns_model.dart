class DnsServer {
  const DnsServer({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.badge,
    required this.primary,
    required this.secondary,
    required this.ping,
    required this.desc,
    required this.suitable,
  });

  final String id;
  final String name;
  final String nameEn;
  final String category; // 'anti-sanction', 'speed', 'stability'
  final String badge;
  final String primary;
  final String secondary;
  final String ping;
  final String desc;
  final String suitable;

  factory DnsServer.fromJson(Map<String, dynamic> json) {
    return DnsServer(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nameEn: (json['nameEN'] ?? json['name_en'] ?? '').toString(),
      category: (json['cat'] ?? json['category'] ?? 'speed').toString(),
      badge: (json['badge'] ?? '').toString(),
      primary: (json['primary'] ?? '').toString(),
      secondary: (json['secondary'] ?? '').toString(),
      ping: (json['ping'] ?? '').toString(),
      desc: (json['desc'] ?? json['description'] ?? '').toString(),
      suitable: (json['suitable'] ?? '').toString(),
    );
  }

  DnsServer copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? category,
    String? badge,
    String? primary,
    String? secondary,
    String? ping,
    String? desc,
    String? suitable,
  }) {
    return DnsServer(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      badge: badge ?? this.badge,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      ping: ping ?? this.ping,
      desc: desc ?? this.desc,
      suitable: suitable ?? this.suitable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEN': nameEn,
        'cat': category,
        'badge': badge,
        'primary': primary,
        'secondary': secondary,
        'ping': ping,
        'desc': desc,
        'suitable': suitable,
      };
}
