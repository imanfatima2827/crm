import '../core/supabase_client.dart';
import '../core/constants.dart';

class AppSetting {
  final String key;
  final Map<String, dynamic> value;
  final String? description;
  final DateTime updatedAt;

  AppSetting({
    required this.key,
    required this.value,
    this.description,
    required this.updatedAt,
  });

  factory AppSetting.fromMap(Map<String, dynamic> map) => AppSetting(
    key: map['setting_key'] as String,
    value: Map<String, dynamic>.from(map['setting_value'] as Map),
    description: map['description'] as String?,
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}

class AppSettingsRepository {
  /// Admin-only per RLS.
  Future<List<AppSetting>> fetchAll() async {
    final data = await sb
        .from(Tables.appSettings)
        .select()
        .order('setting_key');
    return (data as List).map((e) => AppSetting.fromMap(e)).toList();
  }

  Future<void> upsert(
    String key,
    Map<String, dynamic> value, {
    String? description,
  }) async {
    final payload = {
      'setting_key': key,
      'setting_value': value,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (description != null) payload['description'] = description;
    await sb.from(Tables.appSettings).upsert(payload);
  }
}
