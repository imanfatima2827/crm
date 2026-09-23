import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../core/widgets/assignee_field.dart';
import '../../core/widgets/common.dart';
import '../../models/customer.dart';
import '../../services/customer_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/lookup_provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? existing;
  const CustomerFormScreen({super.key, this.existing});
  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CustomerRepository();
  late TextEditingController _name,
      _company,
      _email,
      _phone,
      _addr1,
      _addr2,
      _city,
      _state,
      _postal,
      _country,
      _notes;
  String? _assignedTo;
  String _type = 'individual';
  String _status = 'active';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.customerName ?? '');
    _company = TextEditingController(text: e?.companyName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _addr1 = TextEditingController(text: e?.addressLine1 ?? '');
    _addr2 = TextEditingController(text: e?.addressLine2 ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _state = TextEditingController(text: e?.stateRegion ?? '');
    _postal = TextEditingController(text: e?.postalCode ?? '');
    _country = TextEditingController(text: e?.country ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _assignedTo = e?.assignedTo;
    _type = e?.customerType ?? 'individual';
    _status = e?.status ?? 'active';
    if (widget.existing == null) {
      final auth = context.read<AuthProvider>();
      if (!(auth.isAdmin || auth.isManager)) {
        _assignedTo = auth.profile?.id;
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final c = Customer(
        id: widget.existing?.id ?? '',
        customerName: _name.text.trim(),
        companyName: _company.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        addressLine1: _addr1.text.trim(),
        addressLine2: _addr2.text.trim(),
        city: _city.text.trim(),
        stateRegion: _state.text.trim(),
        postalCode: _postal.text.trim(),
        country: _country.text.trim(),
        assignedTo: _assignedTo,
        customerType: _type,
        status: _status,
        notes: _notes.text.trim(),
        createdAt: DateTime.now(),
      );
      if (widget.existing == null) {
        await _repo.createCustomer(c);
      } else {
        await _repo.updateCustomer(widget.existing!.id, c.toInsertMap());
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e, prefix: 'Save failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _addr1.dispose();
    _addr2.dispose();
    _city.dispose();
    _state.dispose();
    _postal.dispose();
    _country.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookups = context.watch<LookupProvider>();
    final title = widget.existing == null ? 'New Customer' : 'Edit Customer';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Customer'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            _CustomerHeader(title: title, status: _status),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Customer profile',
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Customer name *',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  validator: FieldValidators.requiredText,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _company,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: FieldValidators.optionalEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                  validator: FieldValidators.optionalPhone,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Address',
              children: [
                TextFormField(
                  controller: _addr1,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Address line 1',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addr2,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Address line 2',
                    prefixIcon: Icon(Icons.add_road_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                _ResponsiveFieldPair(
                  first: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  second: TextFormField(
                    controller: _state,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'State/Region'),
                  ),
                ),
                const SizedBox(height: 14),
                _ResponsiveFieldPair(
                  first: TextFormField(
                    controller: _postal,
                    decoration: const InputDecoration(labelText: 'Postal code'),
                  ),
                  second: TextFormField(
                    controller: _country,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Ownership',
              children: [
                AssigneeField(
                  auth: context.watch<AuthProvider>(),
                  users: lookups.users,
                  value: _assignedTo,
                  onChanged: (v) => setState(() => _assignedTo = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Customer type',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: [
                    for (final t in CustomerType.values)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: [
                    for (final s in CustomerStatus.values)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Notes',
              children: [
                TextFormField(
                  controller: _notes,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps paired form fields side-by-side on roomy layouts and stacks them on
/// phones, preventing horizontal RenderFlex overflows.
class _ResponsiveFieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsiveFieldPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [first, const SizedBox(height: 14), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  final String title;
  final String status;
  const _CustomerHeader({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.overlayOnDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textOnPrimaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(status: status),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: title),
            ...children,
          ],
        ),
      ),
    );
  }
}
