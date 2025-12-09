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

    _codeExpiry[email.toLowerCase()] =
        DateTime.now().add(const Duration(minutes: 10));

    // For demo: print code to console

    print('ðŸ“§ Verification code for $email: $code');
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
    print('ðŸ“§ Sending verification email to: $email');

    print('ðŸ“§ Verification Code: $code');

    print('ðŸ“§ Code expires in 10 minutes');

    try {
      // Use a valid Gmail app password here

      final smtpServer = gmail('fibladievent@gmail.com', 'bnxczfpekjnnihpp');

      final message = Message()
        ..from = Address('fibladievent@gmail.com', 'FiBladiEvent')
        ..recipients.add(email)
        ..subject = 'Email Verification Code'
        ..html = '''

        <h2>Email Verification</h2>

        <p>Your verification code is: <strong>$code</strong></p>

        <p>This code will expire in 10 minutes.</p>

      ''';

      final sendReport = await send(message, smtpServer);

      print('âœ… Email sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('âŒ Email not sent. MailerException: $e');

      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }

      throw Exception('Failed to send verification email');
    } catch (e) {
      print('âŒ Unexpected error sending email: $e');

      throw Exception('Failed to send verification email');
    }
  }

  // Send password reset email

  Future<void> sendPasswordResetEmail(String email, String code) async {
    print('ðŸ“§ Sending password reset email to: $email');

    print('ðŸ“§ Reset Code: $code');

    print('ðŸ“§ Code expires in 10 minutes');
  }

Future<void> sendRegistrationApprovalEmail(
  String email, 
  String userName, 
  String eventTitle,
  String eventDate,
  String eventLocation,
) async {
  print('📧 Sending registration approval email to: $email');
  
  try {
    final smtpServer = gmail('fibladievent@gmail.com', 'bnxczfpekjnnihpp');

    final message = Message()
      ..from = Address('fibladievent@gmail.com', 'Event App')
      ..recipients.add(email)
      ..subject = '✅ Registration Approved - $eventTitle'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #4CAF50;">🎉 Registration Approved!</h2>
          <p>Dear <strong>$userName</strong>,</p>
          <p>Great news! Your registration for the following event has been approved:</p>
          
          <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin-top: 0; color: #333;">$eventTitle</h3>
            <p style="margin: 8px 0;"><strong>📅 Date:</strong> $eventDate</p>
            <p style="margin: 8px 0;"><strong>📍 Location:</strong> $eventLocation</p>
          </div>
          
          <p>We look forward to seeing you at the event!</p>
          
          <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
            <p style="color: #666; font-size: 12px;">
              This is an automated message from Event App. Please do not reply to this email.
            </p>
          </div>
        </div>
      ''';

    final sendReport = await send(message, smtpServer);
    print('✅ Approval email sent: ${sendReport.toString()}');
  } on MailerException catch (e) {
    print('❌ Email not sent. MailerException: $e');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  } catch (e) {
    print('❌ Unexpected error sending approval email: $e');
  }
}

// ✅ NEW: Send registration rejection email
Future<void> sendRegistrationRejectionEmail(
  String email, 
  String userName, 
  String eventTitle,
) async {
  print('📧 Sending registration rejection email to: $email');
  
  try {
    final smtpServer = gmail('fibladievent@gmail.com', 'bnxczfpekjnnihpp');

    final message = Message()
      ..from = Address('fibladievent@gmail.com', 'Event App')
      ..recipients.add(email)
      ..subject = 'Registration Update - $eventTitle'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #FF9800;">Registration Update</h2>
          <p>Dear <strong>$userName</strong>,</p>
          <p>Thank you for your interest in the following event:</p>
          
          <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin-top: 0; color: #333;">$eventTitle</h3>
          </div>
          
          <p>Unfortunately, we are unable to approve your registration at this time. This could be due to:</p>
          <ul>
            <li>Event capacity has been reached</li>
            <li>Registration requirements not met</li>
            <li>Event has been modified or cancelled</li>
          </ul>
          
          <p>We encourage you to explore other exciting events on our platform!</p>
          
          <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
            <p style="color: #666; font-size: 12px;">
              This is an automated message from Event App. Please do not reply to this email.
            </p>
          </div>
        </div>
      ''';

    final sendReport = await send(message, smtpServer);
    print('✅ Rejection email sent: ${sendReport.toString()}');
  } on MailerException catch (e) {
    print('❌ Email not sent. MailerException: $e');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  } catch (e) {
    print('❌ Unexpected error sending rejection email: $e');
  }
}

// ✅ NEW: Send 24-hour reminder email
Future<void> sendEventReminderEmail(
  String email, 
  String userName, 
  String eventTitle,
  String eventDate,
  String eventLocation,
  String eventAddress,
) async {
  print('📧 Sending 24-hour reminder email to: $email');
  
  try {
    final smtpServer = gmail('fibladievent@gmail.com', 'ifbdljvvzfacvxhh');

    final message = Message()
      ..from = Address('fibladievent@gmail.com', 'Event App')
      ..recipients.add(email)
      ..subject = '⏰ Reminder: $eventTitle is Tomorrow!'
      ..html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #8B5CF6;">⏰ Event Reminder</h2>
          <p>Dear <strong>$userName</strong>,</p>
          <p>This is a friendly reminder that your registered event is coming up soon!</p>
          
          <div style="background-color: #f5f3ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #8B5CF6;">
            <h3 style="margin-top: 0; color: #8B5CF6;">$eventTitle</h3>
            <p style="margin: 8px 0;"><strong>📅 Date & Time:</strong> $eventDate</p>
            <p style="margin: 8px 0;"><strong>📍 Location:</strong> $eventLocation</p>
            <p style="margin: 8px 0;"><strong>🗺️ Address:</strong> $eventAddress</p>
          </div>
          
          <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 0; color: #856404;">
              <strong>⚠️ Don't forget:</strong> Make sure to arrive on time and bring any required items or tickets.
            </p>
          </div>
          
          <p>We're excited to see you there!</p>
          
          <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
            <p style="color: #666; font-size: 12px;">
              This is an automated reminder from Event App. Please do not reply to this email.
            </p>
          </div>
        </div>
      ''';

    final sendReport = await send(message, smtpServer);
    print('✅ Reminder email sent: ${sendReport.toString()}');
  } on MailerException catch (e) {
    print('❌ Email not sent. MailerException: $e');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  } catch (e) {
    print('❌ Unexpected error sending reminder email: $e');
  }
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