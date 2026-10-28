import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/contact_config.dart';
import '../services/auth_service.dart';
import '../services/trial_service.dart';
import 'email_handoff.dart';

class ConsultationUtils {
  /// Opens the request form. [plan] is the plan the visitor chose (Entry, Mid, High).
  /// The app does not send anything itself: it prepares an email to Cloudora and
  /// the visitor presses Send in their own email app.
  static void showConsultationDialog(BuildContext context, {String? plan}) {
    showDialog<void>(
      context: context,
      builder: (_) => _ConsultationDialog(plan: plan),
    );
  }
}

/// Pure validators (unit-tested).
class ConsultationValidators {
  static String? name(String? value) =>
      (value == null || value.trim().length < 2)
          ? 'Please enter your name'
          : null;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
        ? null
        : 'Please enter a valid email address';
  }

  static String? phone(String? value) {
    final digits = RegExp(r'\d').allMatches(value ?? '').length;
    return digits >= 9 ? null : 'Please enter a valid phone number';
  }
}

/// Builds the plain-text body of the request email (unit-tested).
class ConsultationRequest {
  static String buildBody({
    required String plan,
    required String name,
    required String email,
    required String phone,
    String company = '',
    String businessType = '',
    required String role,
    required String timeline,
    required List<String> contactMethods,
    String source = 'Website',
    int? trialDaysLeft,
    String? trialReference,
  }) {
    final lines = <String>[
      'Plan: $plan',
      'Name: $name',
      'Email: $email',
      'Phone: $phone',
      if (company.trim().isNotEmpty) 'Company: ${company.trim()}',
      if (businessType.trim().isNotEmpty)
        'Business type: ${businessType.trim()}',
      'Role: $role',
      'Wants to start: $timeline',
      'Preferred contact: ${contactMethods.join(', ')}',
      'Source: $source',
      if (trialDaysLeft != null) 'Trial days left: $trialDaysLeft',
      if (trialReference != null && trialReference.isNotEmpty)
        'Trial reference: $trialReference',
    ];
    return lines.join('\n');
  }
}

const Color _orange = Color(0xFFFF6B00);
const Color _ink = Color(0xFF333333);
const Color _muted = Color(0xFF666666);

class _ConsultationDialog extends StatefulWidget {
  final String? plan;
  const _ConsultationDialog({this.plan});

  @override
  State<_ConsultationDialog> createState() => _ConsultationDialogState();
}

class _ConsultationDialogState extends State<_ConsultationDialog> {
  static const _roles = ['Owner/Founder', 'Manager', 'Employee', 'Other'];
  static const _timelines = [
    'Immediately',
    'Within 1-3 months',
    'Just exploring'
  ];
  static const _methods = ['Email', 'WhatsApp', 'Phone', 'SMS'];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _businessType = TextEditingController();

  String? _role;
  String _timeline = _timelines.first;
  final Set<String> _selectedMethods = {};
  bool _showChoiceErrors = false;
  bool _submitting = false;
  int? _trialDaysLeft;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    if (AuthService.isTrialSession) {
      TrialService.getRemainingDays().then((days) {
        if (mounted) _trialDaysLeft = days;
      });
    } else if (user != null) {
      if (user.displayName.isNotEmpty) _name.text = user.displayName;
      if (user.email.isNotEmpty) _email.text = user.email;
      if (user.phone.isNotEmpty) _phone.text = user.phone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _businessType.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final choicesValid = _role != null && _selectedMethods.isNotEmpty;
    setState(() => _showChoiceErrors = true);
    if (!formValid || !choicesValid || _submitting) return;

    setState(() => _submitting = true);

    final plan = widget.plan ?? 'Consultation only';
    final isTrial = AuthService.isTrialSession;
    final body = ConsultationRequest.buildBody(
      plan: plan,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      company: _company.text,
      businessType: _businessType.text,
      role: _role!,
      timeline: _timeline,
      contactMethods: _methods.where(_selectedMethods.contains).toList(),
      source: isTrial ? 'In-app (free trial)' : 'Website',
      trialDaysLeft: isTrial ? _trialDaysLeft : null,
      trialReference: isTrial ? AuthService.currentUser?.id : null,
    );

    await EmailHandoff.start(context,
        subject: 'StockSense request - $plan', body: body);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 480;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: EdgeInsets.all(narrow ? 20 : 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(child: _buildForm()),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.plan != null
                      ? 'Get started with the ${widget.plan} plan'
                      : 'Book a consultation',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.bold, color: _ink),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your business and we will contact you with the right StockSense plan and next steps.',
            style:
                GoogleFonts.poppins(fontSize: 14, height: 1.5, color: _muted),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Your details'),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final twoCol = constraints.maxWidth > 520;

            Widget pair(Widget a, Widget b) => twoCol
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: a),
                      const SizedBox(width: 16),
                      Expanded(child: b),
                    ],
                  )
                : Column(children: [a, const SizedBox(height: 16), b]);

            return Column(
              children: [
                pair(
                  _field(
                    label: 'Name',
                    hint: 'e.g., Wanjiku Mwangi',
                    controller: _name,
                    required: true,
                    validator: ConsultationValidators.name,
                  ),
                  _field(
                    label: 'Email',
                    hint: 'e.g., wanjiku@example.com',
                    controller: _email,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: ConsultationValidators.email,
                  ),
                ),
                const SizedBox(height: 16),
                pair(
                  _field(
                    label: 'Phone',
                    hint: '+254 712 345 678',
                    controller: _phone,
                    required: true,
                    keyboardType: TextInputType.phone,
                    validator: ConsultationValidators.phone,
                  ),
                  _field(
                    label: 'Company name',
                    hint: 'e.g., Mama Njeri General Store',
                    controller: _company,
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'Business type',
                  hint: 'e.g., Retail shop, Wholesale, Pharmacy',
                  controller: _businessType,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
          _sectionTitle('Your role *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final role in _roles)
                _choice(
                  label: role,
                  selected: _role == role,
                  onTap: () => setState(() => _role = role),
                ),
            ],
          ),
          if (_showChoiceErrors && _role == null)
            _errorText('Please choose your role'),
          const SizedBox(height: 24),
          _sectionTitle('When would you like to start? *'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final t in _timelines)
                _choice(
                  label: t,
                  selected: _timeline == t,
                  icon: _timeline == t
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  onTap: () => setState(() => _timeline = t),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('How should we contact you? *'),
          const SizedBox(height: 4),
          Text('Choose one or more.',
              style: GoogleFonts.poppins(fontSize: 12, color: _muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final m in _methods)
                _choice(
                  label: m,
                  selected: _selectedMethods.contains(m),
                  icon: _selectedMethods.contains(m)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  onTap: () => setState(() {
                    if (!_selectedMethods.remove(m)) _selectedMethods.add(m);
                  }),
                ),
            ],
          ),
          if (_showChoiceErrors && _selectedMethods.isEmpty)
            _errorText('Please choose at least one way to contact you'),
          const SizedBox(height: 28),
          Text(
            'Continuing opens an email to ${ContactConfig.email} with your details. '
            'Nothing is sent until you press Send in your email app.',
            style:
                GoogleFonts.poppins(fontSize: 12, height: 1.5, color: _muted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: _muted),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Continue by email',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: _ink),
      );

  Widget _errorText(String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[700])),
      );

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w500, color: _ink),
            children: required
                ? const [
                    TextSpan(text: ' *', style: TextStyle(color: Colors.red))
                  ]
                : const [
                    TextSpan(
                      text: ' (optional)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.poppins(fontSize: 14, color: _ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? _orange.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _orange : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 20, color: selected ? _orange : Colors.grey[400]),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? _orange : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
