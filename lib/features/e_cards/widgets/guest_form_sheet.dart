import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/ecard_guest.dart';

/// Category options shown as a dropdown when the occasion has a fixed
/// set (wedding, conference); other occasions get a plain optional
/// text field instead, since EcardGuest.category is free-form by
/// design (see the model's doc comment).
const _categoryOptions = <EcardOccasion, List<String>>{
  EcardOccasion.wedding: ['Single', 'Double'],
  EcardOccasion.conference: ['VIP', 'General', 'Speaker'],
};

/// Add/edit guest form, shown as a modal bottom sheet from
/// GuestListScreen. Returns the (fullName, phone, category) the
/// organizer entered via the Navigator result — the caller decides
/// whether that means addEcardGuest or updateEcardGuest.
class GuestFormResult {
  final String fullName;
  final String? phone;
  final String? category;
  const GuestFormResult({required this.fullName, this.phone, this.category});
}

Future<GuestFormResult?> showGuestFormSheet(
  BuildContext context, {
  required EcardOccasion occasion,
  EcardGuest? existing,
}) {
  return showModalBottomSheet<GuestFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _GuestFormSheet(occasion: occasion, existing: existing),
  );
}

class _GuestFormSheet extends StatefulWidget {
  final EcardOccasion occasion;
  final EcardGuest? existing;
  const _GuestFormSheet({required this.occasion, this.existing});

  @override
  State<_GuestFormSheet> createState() => _GuestFormSheetState();
}

class _GuestFormSheetState extends State<_GuestFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.fullName ?? '');
  late final _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
  late final _categoryTextController = TextEditingController(text: widget.existing?.category ?? '');
  String? _categoryDropdownValue;

  List<String>? get _fixedCategories => _categoryOptions[widget.occasion];

  @override
  void initState() {
    super.initState();
    final fixed = _fixedCategories;
    if (fixed != null && widget.existing?.category != null && fixed.contains(widget.existing!.category)) {
      _categoryDropdownValue = widget.existing!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _categoryTextController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final category = _fixedCategories != null ? _categoryDropdownValue : _categoryTextController.text.trim();
    Navigator.of(context).pop(GuestFormResult(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      category: (category == null || category.isEmpty) ? null : category,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fixed = _fixedCategories;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add guest' : 'Edit guest',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => Validators.required(v, field: 'Full name'),
              autofocus: widget.existing == null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            if (fixed != null)
              DropdownButtonFormField<String>(
                value: _categoryDropdownValue,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
                items: fixed.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categoryDropdownValue = v),
              )
            else
              TextFormField(
                controller: _categoryTextController,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(widget.existing == null ? 'Add guest' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
