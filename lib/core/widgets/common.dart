import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final foreground = statusForegroundColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        (label ?? status).replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class LeadScoreBadge extends StatelessWidget {
  final int score;
  final String tier;
  final bool compact;
  const LeadScoreBadge({
    super.key,
    required this.score,
    required this.tier,
    this.compact = false,
  });

  Color get _color {
    if (score >= 75) return AppColors.danger; // Hot
    if (score >= 50) return AppColors.warning; // Warm
    if (score >= 25) return AppColors.gold; // Cool
    return AppColors.textSecondary; // Cold
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: '$tier lead \u2014 score $score/100',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 12, color: _color),
              const SizedBox(width: 3),
              Text(
                '$score',
                style: TextStyle(
                  color: _color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, size: 16, color: _color),
        const SizedBox(width: 4),
        Text(
          '$tier \u00b7 $score/100',
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class PriorityDot extends StatelessWidget {
  final String priority;
  const PriorityDot({super.key, required this.priority});
  @override
  Widget build(BuildContext context) {
    final color = priority == 'high'
        ? AppColors.danger
        : priority == 'low'
        ? AppColors.iconMuted
        : AppColors.warning;
    return Icon(iconForPriority(priority), size: 16, color: color);
  }
}

/// KPI card with an optional small trend/subtitle line under the value.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ).copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section header used above lists of cards ("Opportunities", "Activities"...)
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Horizontal row of filter chips, e.g. status filters on list screens.
class FilterChipsRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;
  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    const unselectedLabelColor = AppColors.textPrimary;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(allLabel),
              selected: selected == null,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected == null
                    ? AppColors.textOnPrimary
                    : unselectedLabelColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(o.replaceAll('_', ' ')),
                selected: selected == o,
                showCheckmark: false,
                selectedColor: statusColor(o),
                labelStyle: TextStyle(
                  color: selected == o
                      ? statusForegroundColor(o)
                      : unselectedLabelColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                onSelected: (_) => onSelected(o),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple shimmer-style loading placeholder for lists, used instead of a
/// bare spinner so content areas don't "pop" once data arrives.
class ShimmerList extends StatefulWidget {
  final int itemCount;
  final Color baseColor;
  final Color highlightColor;
  const ShimmerList({
    super.key,
    this.itemCount = 6,
    this.baseColor = AppColors.shimmerBase,
    this.highlightColor = AppColors.shimmerHighlight,
  });
  @override
  State<ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => Container(
            height: 64,
            decoration: BoxDecoration(
              color: Color.lerp(widget.baseColor, widget.highlightColor, t),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}

class LoadingView extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;
  const LoadingView({
    super.key,
    this.baseColor = AppColors.shimmerBase,
    this.highlightColor = AppColors.shimmerHighlight,
  });
  @override
  Widget build(BuildContext context) =>
      ShimmerList(baseColor: baseColor, highlightColor: highlightColor);
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color textColor;
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.iconBackgroundColor = AppColors.surfaceAlt,
    this.iconColor = AppColors.iconMuted,
    this.textColor = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = friendlyDisplayError(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 34,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

const _networkErrorMessage =
    'Internet connection unavailable. Please check your connection and try again.';

/// Translates raw Supabase/Postgres errors into a message a business user
/// can actually act on, instead of leaking `PostgrestException(...)` text.
/// Falls back to the original message (trimmed) for anything unrecognized.
String friendlyError(Object error) {
  if (error is PostgrestException) {
    final code = error.code;
    final msg = error.message;

    // RLS denial: 42501 = insufficient_privilege
    if (code == '42501') {
      return 'You don\u2019t have permission to do that. '
          'This action may be restricted to Admins or Managers.';
    }
    // Check constraint violation: 23514
    if (code == '23514') {
      if (msg.contains('leads_converted_at_check')) {
        return 'Converted leads must use the Convert Lead action from a qualified lead.';
      }
      return msg; // These are already written as human-readable rule text
      // by the schema (e.g. "Estimated value must be greater than 0").
    }
    // Foreign key violation
    if (code == '23503') {
      return 'This record is linked to other data and can\u2019t be changed that way.';
    }
    // Unique violation
    if (code == '23505') {
      return 'That value is already in use \u2014 please use a different one.';
    }
    // Not-null violation
    if (code == '23502') {
      return 'Please fill in all required fields.';
    }
    return msg;
  }
  final text = error.toString();
  if (_looksLikeNetworkError(text)) {
    return _networkErrorMessage;
  }
  // Strip the "Exception: " / "PostgrestException(...)" wrapper if present.
  final match = RegExp(r'message:\s*([^,]+)').firstMatch(text);
  if (match != null) return match.group(1)!.trim();
  return text;
}

String friendlyDisplayError(String message) {
  if (_looksLikeNetworkError(message)) return _networkErrorMessage;

  final parts = message.split('\n');
  if (parts.length < 2) return message;

  final title = parts.first.trim();
  final detail = parts.skip(1).join('\n').trim();
  if (title.isEmpty || detail.isEmpty) return message;

  final friendlyDetail = friendlyError(detail);
  if (friendlyDetail == detail) return message;
  return '$title\n$friendlyDetail';
}

bool _looksLikeNetworkError(String text) {
  final lower = text.toLowerCase();
  return lower.contains('socketexception') ||
      lower.contains('no route to host') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection timed out') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('timeoutexception');
}

/// Shorthand for showing a friendly-translated error snackbar.
void showError(BuildContext context, Object error, {String? prefix}) {
  final message = friendlyError(error);
  showSnack(
    context,
    prefix != null ? '$prefix: $message' : message,
    error: true,
  );
}

void showSnack(
  BuildContext context,
  String message, {
  bool error = false,
  bool success = false,
}) {
  final displayMessage = error ? friendlyDisplayError(message) : message;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline
                : (success ? Icons.check_circle_outline : Icons.info_outline),
            color: AppColors.textOnPrimary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayMessage,
              maxLines: error ? 3 : null,
              overflow: error ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
      backgroundColor: error
          ? AppColors.danger
          : (success ? AppColors.success : null),
      duration: Duration(seconds: error ? 5 : 3),
      showCloseIcon: error,
      closeIconColor: AppColors.textOnPrimary,
    ),
  );
}

/// Confirmation dialog helper, used for destructive actions.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
