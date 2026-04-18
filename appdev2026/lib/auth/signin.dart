// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'google_auth_service.dart';
import 'user_profile_service.dart';
import '../screens/main_wrapper.dart';
import '../theme_controller.dart';
import '../widgets/neon_surface.dart';
import 'signup.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const String routeName = '/signin';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleAuthService _googleAuthService = const GoogleAuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final _SignInUiState _uiState;

  @override
  void initState() {
    super.initState();
    _uiState = _SignInUiState();
  }

  @override
  void dispose() {
    _uiState.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _uiState.setLoading(true);

    try {
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _uiState.emailController.text.trim(),
            password: _uiState.passwordController.text,
          );

      final User? user = credential.user;
      if (user != null) {
        final bool synced = await UserProfileService.instance
            .ensureUserDocumentSafely(user: user);
        if (!synced && mounted) {
          _showMessage('Signed in, but Firebase sync needs attention.');
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        MainWrapperScreen.routeName,
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(
        error.message ?? 'Unable to sign in. Please check your credentials.',
      );
    } catch (_) {
      _showMessage('Something went wrong while signing in.');
    } finally {
      if (mounted) {
        _uiState.setLoading(false);
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    _uiState.setLoading(true);

    try {
      final UserCredential credential = await _googleAuthService
          .signInWithGoogle();

      final User? user = credential.user;
      if (user != null) {
        final bool synced = await UserProfileService.instance
            .ensureUserDocumentSafely(user: user);
        if (!synced && mounted) {
          _showMessage('Signed in, but Firebase sync needs attention.');
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        MainWrapperScreen.routeName,
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'google_sign_in_cancelled') {
        _showMessage(error.message ?? 'Unable to sign in with Google.');
      }
    } catch (_) {
      _showMessage('Something went wrong with Google sign-in.');
    } finally {
      if (mounted) {
        _uiState.setLoading(false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<_SignInUiState>.value(
      value: _uiState,
      child: Consumer<_SignInUiState>(
        builder: (BuildContext context, _SignInUiState uiState, _) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Sign In'),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Toggle theme',
                  onPressed: appThemeController.toggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: NeonBackground(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: GlassCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const SizedBox(height: 20),
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: uiState.emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (String? value) {
                                final String text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Enter your email address.';
                                }
                                if (!text.contains('@')) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: uiState.passwordController,
                              obscureText: uiState.obscurePassword,
                              autofillHints: const <String>[
                                AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: uiState.toggleObscurePassword,
                                  icon: Icon(
                                    uiState.obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                  ),
                                ),
                              ),
                              validator: (String? value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Enter your password.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: uiState.isLoading ? null : _submit,
                              child: uiState.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: uiState.isLoading
                                  ? null
                                  : _continueWithGoogle,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.35),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _GoogleGlyph(),
                                  SizedBox(width: 12),
                                  Text('Continue with Google'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: uiState.isLoading
                                  ? null
                                  : () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(SignUpScreen.routeName);
                                    },
                              child: const Text(
                                'Don\'t have an account? Sign up',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignInUiState extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  void toggleObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void setLoading(bool value) {
    if (isLoading == value) {
      return;
    }

    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: <Color>[
              Color(0xFF4285F4),
              Color(0xFFEA4335),
              Color(0xFFFABB05),
              Color(0xFF34A853),
            ],
          ).createShader(bounds);
        },
        child: const Text(
          'G',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
