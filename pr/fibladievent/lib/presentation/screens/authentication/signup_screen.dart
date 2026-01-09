import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../services/email_service.dart';
import '/../services/api_service.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '../../l10n/app_localizations.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  final ApiService _apiService = ApiService();

  // Role selection
  String _selectedRole = 'participant'; // 'participant' or 'organization'

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength =
          PasswordValidator.getPasswordStrength(_passwordController.text);
      _passwordStrengthText =
          PasswordValidator.getStrengthText(_passwordStrength);
    });
  }

  Future<void> _handleSignup() async {
  // Validate email
  if (_emailController.text.trim().isEmpty) {
    _showError(AppLocalizations.of(context)!.translate('please_enter_email'));
    return;
  }

  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
      .hasMatch(_emailController.text)) {
    _showError(AppLocalizations.of(context)!.translate('please_enter_valid_email'));
    return;
  }

  // Validate username
  if (_usernameController.text.trim().isEmpty) {
    _showError(AppLocalizations.of(context)!.translate('please_enter_username'));
    return;
  }

  if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(_usernameController.text)) {
    _showError(AppLocalizations.of(context)!.translate('username_requirements'));
    return;
  }

  // Check if username already exists via API
  try {
    final response = await _apiService.get(
      '/auth/check-username',
      queryParameters: {'username': _usernameController.text.trim()}
    );
// Check if username already exists via API
try {
  final response = await _apiService.get(
    '/auth/check-username',
    queryParameters: {'username': _usernameController.text.trim()}
  );

  print('✅ Check username response: ${response.data}');
  print('✅ Response type: ${response.data.runtimeType}');
  
  // Handle different response formats
  bool usernameExists = false;
  
  if (response.data is Map<String, dynamic>) {
    usernameExists = response.data['exists'] == true;
  } else if (response.data is bool) {
    usernameExists = response.data;
  }

  if (usernameExists) {
    _showError(AppLocalizations.of(context)!.translate('username_already_taken'));
    return;
  }
} catch (e) {
  print('❌ Error checking username: $e');
  // Don't block signup if check fails - just log it
  print('⚠️ Continuing with signup despite username check failure');
  // Optionally show warning but don't return
  // _showError('Could not verify username availability');
}
    // Check if response.data is a Map and contains 'exists' key
    if (response.data is Map<String, dynamic> && 
        response.data['exists'] == true) {
      _showError(AppLocalizations.of(context)!.translate('username_already_taken'));
      return;
    }
  } catch (e) {
    print('Error checking username: $e');
    _showError('Error checking username. Please try again.');
    return;
  }

  // Validate password
  final passwordError = PasswordValidator.validate(_passwordController.text);
  if (passwordError != null) {
    _showError(passwordError);
    return;
  }

  // Check password match
  if (_passwordController.text != _confirmPasswordController.text) {
    _showError(AppLocalizations.of(context)!.translate('passwords_do_not_match'));
    return;
  }

  // Navigate to email verification with role
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EmailVerificationScreen(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        userRole: _selectedRole,
      ),
    ),
  );
}
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'EVENT',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 66, 22, 79),
                            letterSpacing: 2,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      context.tr('create_account'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 66, 22, 79),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      context.tr('sign_up_to_get_started'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Role Selection
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = 'participant';
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'participant'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedRole == 'participant'
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: _selectedRole == 'participant'
                                          ? const Color.fromARGB(
                                              255, 66, 22, 79)
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('participant'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            _selectedRole == 'participant'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color: _selectedRole == 'participant'
                                            ? const Color.fromARGB(
                                                255, 66, 22, 79)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRole = 'organization';
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'organization'
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedRole == 'organization'
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      color: _selectedRole == 'organization'
                                          ? Colors.orange[700]
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('organization'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            _selectedRole == 'organization'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color: _selectedRole == 'organization'
                                            ? Colors.orange[700]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      hint: context.tr('enter_email'),
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // Username Field
                    _buildTextField(
                      controller: _usernameController,
                      hint: context.tr('enter_username'),
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 16),

                    // Password Field with Strength Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _passwordController,
                          hint: context.tr('enter_password'),
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey[400],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),

                        // Password Strength Indicator
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  backgroundColor: Colors.grey[200],
                                  color: PasswordValidator.getStrengthColor(
                                      _passwordStrength),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _passwordStrengthText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: PasswordValidator.getStrengthColor(
                                      _passwordStrength),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('password_requirements'),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: context.tr('confirm_password'),
                      icon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Signup Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole == 'organization'
                              ? Colors.orange[400]
                              : const Color.fromARGB(255, 66, 22, 79),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          context.tr('sign_up_as_role').replaceAll(
                              '{role}',
                              _selectedRole == 'participant'
                                  ? context.tr('participant')
                                  : context.tr('organization')),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('already_have_account'),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            context.tr('login'),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
