import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../l10n/gen/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  UserType _selectedUserType = UserType.CUSTOMER;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password criteria state
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_evaluatePassword);
  }

  void _evaluatePassword() {
    final p = _passwordController.text;
    setState(() {
      _hasMinLength = p.length >= 8; // backend requires 8
      _hasUpper = RegExp(r'[A-Z]').hasMatch(p);
      _hasLower = RegExp(r'[a-z]').hasMatch(p);
      _hasDigit = RegExp(r'\d').hasMatch(p);
      // Special characters (same as backend set simplified)
      const specialChars = "!@#\$%^&*()_+-={}[]:;\\\"'<>?,./"; // note: includes backslash
      _hasSpecial = p.split('').any((c) => specialChars.contains(c));
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.removeListener(_evaluatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        userType: _selectedUserType,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCriteriaRow(bool ok, String text) {
    final color = ok ? Colors.green : Colors.grey[600];
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: color)))
      ],
    );
  }

  String? _passwordValidator(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return loc.passwordRequired;
    final missing = <String>[];
    if (!_hasMinLength) missing.add(loc.passwordCriterionMin);
    if (!_hasUpper) missing.add(loc.passwordCriterionUpper);
    if (!_hasLower) missing.add(loc.passwordCriterionLower);
    if (!_hasDigit) missing.add(loc.passwordCriterionDigit);
    if (!_hasSpecial) missing.add(loc.passwordCriterionSpecial);
    if (missing.isEmpty) return null;
    // If only one missing show short form, else use prefix
    final list = missing.join(', ');
    return loc.passwordAddPrefix(list);
  }

  String? _confirmPasswordValidator(String? value) {
    final loc = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return loc.confirmPasswordRequired;
    if (value != _passwordController.text) return loc.passwordsDoNotMatch;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(loc.createAccountTitle),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.joinGarageService,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: loc.firstName,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.requiredField;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: loc.lastName,
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.requiredField;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: loc.loginEmail,
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.emailRequired;
                    }
                    if (!value.contains('@')) {
                      return loc.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: loc.phoneNumber,
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc.phoneRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserType>(
                      value: _selectedUserType,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: UserType.CUSTOMER,
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(loc.customer),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: UserType.GARAGE_OWNER,
                          child: Row(
                            children: [
                              Icon(Icons.build, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(loc.garageOwner),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (UserType? value) {
                        if (value != null) {
                          setState(() {
                            _selectedUserType = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: loc.password,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 8),
                // Password criteria checklist
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCriteriaRow(_hasMinLength, loc.passwordCriterionMin),
                    _buildCriteriaRow(_hasUpper, loc.passwordCriterionUpper),
                    _buildCriteriaRow(_hasLower, loc.passwordCriterionLower),
                    _buildCriteriaRow(_hasDigit, loc.passwordCriterionDigit),
                    _buildCriteriaRow(_hasSpecial, loc.passwordCriterionSpecial),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: loc.confirmPassword,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _confirmPasswordValidator,
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                loc.createAccountButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}