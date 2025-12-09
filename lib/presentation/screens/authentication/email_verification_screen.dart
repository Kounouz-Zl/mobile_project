import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../services/email_service.dart';
import '/../data/databases/database_helper.dart';
import '/../logic/cubits/auth/auth_bloc.dart';
import '/../logic/cubits/auth/auth_event.dart';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '../../l10n/app_localizations_ar.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_fr.dart';
import '../../l10n/app_localizations.dart';

import 'profile_photo_screen.dart';


class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String username;
  final String userRole; // 'participant' or 'organization'

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.username,
    required this.userRole,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _verificationCode = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
    
    // Add listeners to scroll when keyboard appears
    for (var focusNode in _focusNodes) {
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          _scrollToFocusedField();
        }
      });
    }
  }

  void _scrollToFocusedField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    _verificationCode = EmailService.instance.generateVerificationCode();
    EmailService.instance.storeVerificationCode(widget.email, _verificationCode);
    
    try {
      await EmailService.instance.sendVerificationEmail(widget.email, _verificationCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.translate('verification_code_sent_to')} ${widget.email}'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.translate('failed_to_send_email')}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('please_enter_all_6_digits')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = EmailService.instance.verifyCode(widget.email, code);
      
      if (!isValid) {
        throw Exception(AppLocalizations.of(context)!.translate('invalid_or_expired_verification_code'));
      }

      // Mark email as verified in database
      await DatabaseHelper.instance.verifyUserEmail(widget.email);

      // ✅ FIXED: Use AuthRepository directly to complete signup synchronously
      final db = DatabaseHelper.instance;
      
      // Register user with role
      final newUser = await db.registerUser(
        email: widget.email,
        username: widget.username,
        password: widget.password,
        role: widget.userRole,
      );

      if (newUser == null) {
        throw Exception(AppLocalizations.of(context)!.translate('failed_to_create_user_account'));
      }

      // Update UserCubit with the new user
      if (mounted) {
        context.read<UserCubit>().setUser(newUser);
      }

      // Also trigger auth bloc to update state
      if (mounted) {
        context.read<AuthBloc>().add(SignupRequested(
          email: widget.email,
          username: widget.username,
          password: widget.password,
          role: widget.userRole,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('email_verified_successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // ✅ Now navigate to profile photo screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePhotoScreen(
              username: widget.username,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 50,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      AppLocalizations.of(context)!.translate('verify_your_email'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    Text(
                      '${AppLocalizations.of(context)!.translate('enter_the_6_digit_code_sent_to')}\n${widget.email}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Code Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.orange, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              
                              // Auto-verify when all fields are filled
                              if (index == 5 && value.isNotEmpty) {
                                FocusScope.of(context).unfocus();
                                _verifyCode();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.translate('verify_email'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Resend Code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('didnt_receive_the_code'),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        TextButton(
                          onPressed: () {
                            _sendVerificationCode();
                            // Clear existing inputs
                            for (var controller in _controllers) {
                              controller.clear();
                            }
                            _focusNodes[0].requestFocus();
                          },
                          child: Text(
                            AppLocalizations.of(context)!.translate('resend'),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Extra space for keyboard
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}