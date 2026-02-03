import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/error_formatter.dart';
import '../../../../injection_container.dart';

const Color _primaryBlue = Color(0xFF2859E2);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // OTP expiry countdown
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  // Rate limiting
  bool _isRateLimited = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    final now = DateTime.now();
    _secondsRemaining = expiresAt.difference(now).inSeconds;
    if (_secondsRemaining <= 0) _secondsRemaining = 0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String _formatCountdown(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _requestOTP() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      final response = await dioClient.dio.post(
        '/password/request-otp',
        data: {'email': _emailController.text.trim()},
      );

      final data = response.data;
      setState(() {
        _otpSent = true;
        _isRateLimited = false;
      });

      // Start countdown timer if expiresAt is provided
      if (data['expiresAt'] != null) {
        final expiresAt = DateTime.parse(data['expiresAt']);
        _startCountdown(expiresAt);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Rate limited
        setState(() {
          _isRateLimited = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Too many attempts. Please try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${ErrorFormatter.format(e)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${ErrorFormatter.format(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dioClient = sl<DioClient>();
      await dioClient.dio.post(
        '/password/reset-otp',
        data: {
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
          'newPassword': _newPasswordController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorFormatter.format(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInDown(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Password?',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1D1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent
                            ? 'Enter the OTP sent to your email and choose a new password.'
                            : 'Enter your email address and we\'ll send you an OTP to reset your password.',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildEmailField(),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildOTPField(),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      hint: 'Enter new password',
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Confirm new password',
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_otpSent ? _resetPassword : _requestOTP),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                              _otpSent ? 'Reset Password' : 'Send OTP',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  // Show countdown timer
                  if (_secondsRemaining > 0)
                    Center(
                      child: Text(
                        'OTP expires in ${_formatCountdown(_secondsRemaining)}',
                        style: GoogleFonts.outfit(
                          color: _secondsRemaining <= 60
                              ? Colors.red
                              : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (_secondsRemaining == 0 && _otpSent)
                    Center(
                      child: Text(
                        'OTP expired. Please request a new one.',
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Resend OTP button
                  if (_isRateLimited)
                    Center(
                      child: Text(
                        'Too many attempts. Try again later.',
                        style: GoogleFonts.outfit(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isLoading ? null : _requestOTP,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.outfit(color: _primaryBlue),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: !_otpSent,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        labelStyle: GoogleFonts.outfit(),
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        prefixIcon: const Icon(CupertinoIcons.mail, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue),
        ),
      ),
    );
  }

  Widget _buildOTPField() {
    return TextFormField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: 'OTP Code',
        hintText: 'Enter 6-digit OTP',
        labelStyle: GoogleFonts.outfit(),
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        prefixIcon: const Icon(CupertinoIcons.lock, color: Colors.grey),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue),
        ),
      ),
      validator: (value) {
        if (value == null || value.length != 6) {
          return 'Please enter a 6-digit OTP';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(),
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
        prefixIcon: const Icon(CupertinoIcons.lock, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryBlue),
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
    );
  }
}
