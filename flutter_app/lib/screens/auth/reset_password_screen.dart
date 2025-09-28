import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialToken;
  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;

  // Password criteria state
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }
    _passwordController.addListener(_evaluatePassword);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.removeListener(_evaluatePassword);
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _evaluatePassword() {
    final p = _passwordController.text;
    setState(() {
      _hasMinLength = p.length >= 8;
      _hasUpper = RegExp(r'[A-Z]').hasMatch(p);
      _hasLower = RegExp(r'[a-z]').hasMatch(p);
      _hasDigit = RegExp(r'\d').hasMatch(p);
      const specialChars = "!@#\$%^&*()_+-={}[]:;\\\"'<>?,./";
      _hasSpecial = p.split('').any((c) => specialChars.contains(c));
    });
  }

  Widget _criteriaRow(bool ok, String text){
    final color = ok ? Colors.green : Colors.grey[600];
    return Row(children:[
      Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size:16, color:color),
      const SizedBox(width:6),
      Flexible(child: Text(text, style: TextStyle(fontSize:12,color:color)))
    ]);
  }

  String? _passwordValidator(String? v){
    final loc = AppLocalizations.of(context);
    if(v==null || v.isEmpty) return loc.passwordRequired;
    final missing = <String>[];
    if(!_hasMinLength) missing.add(loc.passwordCriterionMin);
    if(!_hasUpper) missing.add(loc.passwordCriterionUpper);
    if(!_hasLower) missing.add(loc.passwordCriterionLower);
    if(!_hasDigit) missing.add(loc.passwordCriterionDigit);
    if(!_hasSpecial) missing.add(loc.passwordCriterionSpecial);
    if(missing.isEmpty) return null;
    return loc.passwordAddPrefix(missing.join(', '));
  }

  String? _confirmValidator(String? v){
    final loc = AppLocalizations.of(context);
    if(v==null || v.isEmpty) return loc.confirmPasswordRequired;
    if(v != _passwordController.text) return loc.passwordsDoNotMatch;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final token = _tokenController.text.trim();
      final pwd = _passwordController.text;
  await ApiService.resetPassword(token: token, newPassword: pwd);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordResetSuccess)),
      );
      Navigator.popUntil(context, ModalRoute.withName('/login'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).genericError}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && _tokenController.text.isEmpty) {
      _tokenController.text = arg;
    }
    return Scaffold(
      appBar: AppBar(title: Text(loc.resetPasswordTitle), backgroundColor: AppColors.navy, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tokenController,
                decoration: InputDecoration(labelText: loc.resetTokenLabel, border: const OutlineInputBorder(), filled: true, fillColor: AppColors.card),
                validator: (v) => (v==null || v.isEmpty) ? loc.tokenRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePwd,
                decoration: InputDecoration(
                  labelText: loc.newPassword,
                  border: const OutlineInputBorder(), filled: true, fillColor: AppColors.card,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePwd ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(()=> _obscurePwd = !_obscurePwd),
                  ),
                ),
                validator: _passwordValidator,
              ),
              const SizedBox(height:8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _criteriaRow(_hasMinLength, loc.passwordCriterionMin),
                  _criteriaRow(_hasUpper, loc.passwordCriterionUpper),
                  _criteriaRow(_hasLower, loc.passwordCriterionLower),
                  _criteriaRow(_hasDigit, loc.passwordCriterionDigit),
                  _criteriaRow(_hasSpecial, loc.passwordCriterionSpecial),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: loc.confirmNewPassword,
                  border: const OutlineInputBorder(), filled: true, fillColor: AppColors.card,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(()=> _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: _confirmValidator,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkOrange, foregroundColor: Colors.white),
                  child: _submitting ? const CircularProgressIndicator(color: Colors.white) : Text(loc.resetPasswordCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
