import 'dart:math';
import 'package:flutter/material.dart';
   import 'package:mailer/mailer.dart';
   import 'package:mailer/smtp_server.dart';

class EmailService {
  static final EmailService instance = EmailService._init();
  EmailService._init();

  // For demo purposes, we'll store codes in memory
  // In production, use Firebase or a backend service
  final Map<String, String> _verificationCodes = {};
  final Map<String, DateTime> _codeExpiry = {};

  // Generate a 6-digit verification code
  String generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Store verification code
  void storeVerificationCode(String email, String code) {
    _verificationCodes[email.toLowerCase()] = code;
    _codeExpiry[email.toLowerCase()] = DateTime.now().add(const Duration(minutes: 10));
    
    // For demo: print code to console
    print('📧 Verification code for $email: $code');
  }

  // Verify code
  bool verifyCode(String email, String code) {
    final storedCode = _verificationCodes[email.toLowerCase()];
    final expiry = _codeExpiry[email.toLowerCase()];
    
    if (storedCode == null || expiry == null) {
      return false;
    }
    
    if (DateTime.now().isAfter(expiry)) {
      _verificationCodes.remove(email.toLowerCase());
      _codeExpiry.remove(email.toLowerCase());
      return false;
    }
    
    if (storedCode == code) {
      _verificationCodes.remove(email.toLowerCase());
      _codeExpiry.remove(email.toLowerCase());
      return true;
    }
    
    return false;
  }

  // Send verification email (mock for demo)
Future<void> sendVerificationEmail(String email, String code) async {
  print('📧 Sending verification email to: $email');
  print('📧 Verification Code: $code');
  print('📧 Code expires in 10 minutes');

  try {
    // Use a valid Gmail app password here
    final smtpServer = gmail('fibladievent@gmail.com', 'ifbdljvvzfacvxhh');

    final message = Message()
      ..from = Address('fibladievent@gmail.com', 'Event App')
      ..recipients.add(email)
      ..subject = 'Email Verification Code'
      ..html = '''
        <h2>Email Verification</h2>
        <p>Your verification code is: <strong>$code</strong></p>
        <p>This code will expire in 10 minutes.</p>
      ''';

    final sendReport = await send(message, smtpServer);
    print('✅ Email sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('❌ Email not sent. MailerException: $e');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
    throw Exception('Failed to send verification email');
  } catch (e) {
    print('❌ Unexpected error sending email: $e');
    throw Exception('Failed to send verification email');
  }
}


  // Send password reset email
  Future<void> sendPasswordResetEmail(String email, String code) async {
    print('📧 Sending password reset email to: $email');
    print('📧 Reset Code: $code');
    print('📧 Code expires in 10 minutes');
  }
}

// Password validation utility
class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 50;

  static String? validate(String password) {
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    if (password.length > maxLength) {
      return 'Password must be less than $maxLength characters';
    }
    
    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*()\,.?\:{}|<>]'))) {
      return 'Password must contain at least one special character (!@#%^&*...)';
    }
    
    return null;
  }

  static double getPasswordStrength(String password) {
    double strength = 0.0;
    
    if (password.length >= minLength) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*()\,.?\:{}|<>]'))) strength += 0.15;
    
    return strength.clamp(0.0, 1.0);
  }

  static String getStrengthText(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Medium';
    if (strength < 0.8) return 'Strong';
    return 'Very Strong';
  }

  static Color getStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.blue;
    return Colors.green;
  }
}