import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/platform_util.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ApiService.login(username, password);

    if (!mounted) return;

    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Wrong username or password';
      });
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final tokenCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    String? targetEmail = await ApiService.getResetTargetEmail();
    if (!mounted) return;

    int step = 1;
    bool submitting = false;
    String? dialogError;
    String? infoMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: !submitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                step == 1 ? 'Forgot Password' : 'Reset Password',
                style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (step == 1) ...[
                      Text(
                        targetEmail != null && targetEmail!.isNotEmpty
                            ? 'A 6-digit password reset code will be sent to:\n$targetEmail'
                            : 'Tap Send Code to receive a 6-digit password reset code on your configured recovery email.',
                        style: GoogleFonts.mukta(fontSize: 14, color: AppColors.ink),
                      ),
                    ] else ...[
                      if (infoMessage != null) ...[
                        Text(
                          infoMessage!,
                          style: GoogleFonts.mukta(fontSize: 13, color: AppColors.pri, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: tokenCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '6-Digit Reset Code',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: newPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dialogError!,
                        style: GoogleFonts.mukta(fontSize: 13, color: AppColors.bad, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          setDialogState(() {
                            submitting = true;
                            dialogError = null;
                          });

                          if (step == 1) {
                            final (ok, msg, email, devToken) = await ApiService.forgotPassword();
                            if (!dialogContext.mounted) return;
                            if (ok) {
                              if (email != null && email.isNotEmpty) {
                                targetEmail = email;
                              }
                              if (devToken != null && devToken.isNotEmpty) {
                                tokenCtrl.text = devToken;
                              }
                              setDialogState(() {
                                submitting = false;
                                step = 2;
                                infoMessage = devToken != null
                                    ? 'Local dev code pre-filled. Enter your new password.'
                                    : msg;
                              });
                            } else {
                              setDialogState(() {
                                submitting = false;
                                dialogError = msg;
                              });
                            }
                          } else {
                            final token = tokenCtrl.text.trim();
                            final pass = newPasswordCtrl.text;
                            final confirm = confirmPasswordCtrl.text;
                            if (token.isEmpty || pass.length < 6) {
                              setDialogState(() {
                                submitting = false;
                                dialogError = 'Valid 6-digit code and password (min 6 chars) required';
                              });
                              return;
                            }
                            if (pass != confirm) {
                              setDialogState(() {
                                submitting = false;
                                dialogError = 'Passwords do not match';
                              });
                              return;
                            }
                            final (ok, msg) = await ApiService.resetPassword(
                              token: token,
                              newPassword: pass,
                            );
                            if (!dialogContext.mounted) return;
                            if (ok) {
                              Navigator.of(dialogContext).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              }
                            } else {
                              setDialogState(() {
                                submitting = false;
                                dialogError = msg;
                              });
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(step == 1 ? 'Send Code' : 'Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF06B6D4)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10), // Top spacer
                        // Center Login Card
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(20, 23, 58, 0.18),
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SSRSM Accounts',
                                    style: GoogleFonts.sora(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Username',
                                    style: GoogleFonts.mukta(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mut,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your username',
                                      filled: true,
                                      fillColor: AppColors.card,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.pri, width: 2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Password',
                                    style: GoogleFonts.mukta(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mut,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      filled: true,
                                      fillColor: AppColors.card,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: AppColors.pri, width: 2),
                                      ),
                                    ),
                                  ),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _errorMessage!,
                                      style: GoogleFonts.mukta(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.bad,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading ? null : _showForgotPasswordDialog,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot password?',
                                        style: GoogleFonts.mukta(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.pri,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 4,
                                        shadowColor: const Color.fromRGBO(79, 70, 229, 0.35),
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: AppColors.buttonGradient,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                                )
                                              : Text(
                                                  'Log in',
                                                  style: GoogleFonts.mukta(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bottom Footer Tag at the bottom of the screen
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: _buildFooterLink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    if (kIsWeb) {
      openWebUrl(url);
    } else {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri);
        }
      } catch (e) {
        debugPrint('Could not launch $url: $e');
      }
    }
  }

  Widget _buildFooterLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Powered by ',
                style: GoogleFonts.mukta(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              InkWell(
                onTap: () => _openUrl('https://portfolio.fdhs-solution.com/'),
                child: Text(
                  'FDHS Solutions',
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF38BDF8), // Electric Vivid Sky Blue
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: () => _openUrl('mailto:fdhssolutions@gmail.com'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 15,
                  color: Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 6),
                Text(
                  'fdhssolutions@gmail.com',
                  style: GoogleFonts.mukta(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF1F5F9),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

