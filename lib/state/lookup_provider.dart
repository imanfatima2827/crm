import 'package:flutter/foundation.dart';
import '../models/lookups.dart';
import '../models/profile.dart';
import '../services/lookup_repository.dart';

class LookupProvider extends ChangeNotifier {
  final LookupRepository _repo = LookupRepository();

  List<LeadSource> sources = [];
  List<OpportunityStage> stages = [];
  List<Product> products = [];
  List<Profile> users = [];
  List<RoleOption> roles = [];
  bool loaded = false;
  bool loading = false;

  Future<void> loadAll({bool force = false}) async {
    if (loaded && !force) return;
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchLeadSources(),
        _repo.fetchStages(),
        _repo.fetchProducts(),
        _repo.fetchAssignableUsers(),
        _repo.fetchRoles(),
      ]);
      sources = results[0] as List<LeadSource>;
      stages = results[1] as List<OpportunityStage>;
      products = results[2] as List<Product>;
      users = results[3] as List<Profile>;
      roles = results[4] as List<RoleOption>;
      loaded = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    products = await _repo.fetchProducts();
    notifyListeners();
  }

  String userName(String? id) {
    if (id == null) return 'Unassigned';
    final match = users.where((u) => u.id == id);
    return match.isEmpty ? 'Unassigned' : match.first.fullName;
  }

  OpportunityStage stageById(int id) =>
      stages.firstWhere((s) => s.id == id, orElse: () => stages.first);
}
