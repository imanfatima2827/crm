import 'package:flutter/material.dart';
import '../../models/profile.dart';
import '../../state/auth_provider.dart';

/// The `can_access_assignee()` rule in the database means:
///   - Admin / Sales Manager: may assign to anyone on their team, or leave
///     unassigned.
///   - Sales Representative: may ONLY assign to themselves \u2014 leaving a
///     record unassigned, or assigning it to someone else, is rejected by
///     Row-Level Security.
/// This widget mirrors that rule client-side so a rep gets a clear,
/// locked "Assigned to: you" field instead of a save that silently fails.
class AssigneeField extends StatelessWidget {
  final AuthProvider auth;
  final List<Profile> users;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  const AssigneeField({
    super.key,
    required this.auth,
    required this.users,
    required this.value,
    required this.onChanged,
    this.label = 'Assigned salesperson',
  });

  @override
  Widget build(BuildContext context) {
    final isRep = !(auth.isAdmin || auth.isManager);
    final myId = auth.profile?.id;

    if (isRep && myId != null) {
      // Force (and keep) the value locked to the current user.
      if (value != myId) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(myId));
      }
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(auth.profile?.fullName ?? 'You'),
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: null, child: Text('Unassigned')),
        for (final u in users)
          DropdownMenuItem(value: u.id, child: Text(u.fullName)),
      ],
      onChanged: onChanged,
    );
  }
}
