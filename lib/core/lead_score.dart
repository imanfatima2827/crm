import '../models/lead.dart';

/// A simple, transparent lead-scoring heuristic (0-100) combining pipeline
/// status, how recently the lead was touched, and contact-info completeness.
/// This is intentionally rule-based (not ML) so sales reps can trust and
/// reason about the number rather than treating it as a black box.
class LeadScore {
  final int score;
  final String tier; // Hot / Warm / Cool / Cold

  const LeadScore(this.score, this.tier);

  static LeadScore compute(Lead lead) {
    int score;
    switch (lead.status) {
      case 'qualified':
        score = 80;
        break;
      case 'interested':
        score = 55;
        break;
      case 'contacted':
        score = 35;
        break;
      case 'converted':
        score = 100;
        break;
      case 'lost':
        score = 0;
        break;
      default: // new
        score = 15;
    }

    // Recency: fresher leads score higher within their status band.
    final daysOld = DateTime.now().difference(lead.createdAt).inDays;
    if (lead.status != 'lost' && lead.status != 'converted') {
      if (daysOld <= 2) {
        score += 10;
      } else if (daysOld <= 7) {
        score += 4;
      } else if (daysOld > 30) {
        score -= 15;
      } else if (daysOld > 14) {
        score -= 7;
      }
    }

    // Completeness: leads with both phone and email are easier to close.
    if ((lead.phone?.isNotEmpty ?? false) &&
        (lead.email?.isNotEmpty ?? false)) {
      score += 5;
    }

    score = score.clamp(0, 100);

    final tier = score >= 75
        ? 'Hot'
        : score >= 50
        ? 'Warm'
        : score >= 25
        ? 'Cool'
        : 'Cold';

    return LeadScore(score, tier);
  }
}
