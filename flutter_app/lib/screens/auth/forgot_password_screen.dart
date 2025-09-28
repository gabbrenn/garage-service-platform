import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _resultToken; // for dev/testing

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final resp = await ApiService.requestPasswordReset(_emailController.text);
      setState(() {
        _resultToken = resp['resetToken'];
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordResetEmailSent)),
      );
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
    return Scaffold(
      appBar: AppBar(title: Text(loc.forgotPasswordTitle), backgroundColor: AppColors.navy, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(loc.forgotPasswordSubtitle, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: loc.loginEmail, border: const OutlineInputBorder(), filled: true, fillColor: AppColors.card),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return loc.emailRequired;
                  if (!v.contains('@')) return loc.emailInvalid;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkOrange, foregroundColor: Colors.white),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(loc.sendResetLink),
              ),
            ),
            if (_resultToken != null) ...[
              const SizedBox(height: 12),
              Text('${loc.devResetToken}: $_resultToken', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/reset-password', arguments: _resultToken);
                },
                child: Text(loc.goToResetWithToken),
              )
            ]
          ],
        ),
      ),
    );
  }
}
