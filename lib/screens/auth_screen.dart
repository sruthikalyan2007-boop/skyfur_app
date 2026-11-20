import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isFirebaseConfigError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFirebaseConfigError = false;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      if (_isSignUp) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        if (name.isNotEmpty && credential.user != null) {
          await credential.user!.updateDisplayName(name);
        }
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      final isConfig = e.code.contains('configuration') ||
          e.code == 'operation-not-allowed' ||
          (e.message != null &&
              (e.message!.contains('CONFIGURATION_NOT_FOUND') ||
                  e.message!.contains('OPERATION_NOT_ALLOWED')));
      setState(() {
        _isFirebaseConfigError = isConfig;
        _errorMessage = _getFriendlyErrorMessage(e.code, e.message);
      });
    } catch (e) {
      final errStr = e.toString();
      final isConfig = errStr.contains('CONFIGURATION_NOT_FOUND') ||
          errStr.contains('configuration-not-found') ||
          errStr.contains('operation-not-allowed') ||
          errStr.contains('IDENTITY_PROVIDER_NOT_FOUND');
      setState(() {
        _isFirebaseConfigError = isConfig;
        _errorMessage = isConfig
            ? 'Firebase Authentication is not enabled yet in your Firebase Project.'
            : 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(String code, String? defaultMessage) {
    final lowerCode = code.toLowerCase();
    final lowerMsg = (defaultMessage ?? '').toLowerCase();

    if (lowerCode.contains('configuration') ||
        lowerMsg.contains('configuration_not_found') ||
        lowerCode.contains('operation-not-allowed') ||
        lowerMsg.contains('operation-not-allowed')) {
      return 'Email/Password sign-in is not enabled yet in Firebase Project (skyfur-eac18).';
    }

    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please check or create an account.';
      case 'wrong-password':
        return 'Incorrect password. Please verify and try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'This email address is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase project settings.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return defaultMessage ?? 'Authentication failed ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.08),
              Colors.white,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Header
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Skyfur',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F766E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Pet Wellness & Care Companion',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card Form
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Toggle Pill
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _AuthModeTab(
                                        title: 'Sign In',
                                        isSelected: !_isSignUp,
                                        onTap: () {
                                          if (_isSignUp) {
                                            setState(() {
                                              _isSignUp = false;
                                              _errorMessage = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: _AuthModeTab(
                                        title: 'Create Account',
                                        isSelected: _isSignUp,
                                        onTap: () {
                                          if (!_isSignUp) {
                                            setState(() {
                                              _isSignUp = true;
                                              _errorMessage = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Firebase Config Guide Card
                              if (_isFirebaseConfigError) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFCD34D),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.settings_applications,
                                              color: Color(0xFFD97706),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Firebase Setup Needed',
                                              style: TextStyle(
                                                color: Colors.amber.shade900,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Email/Password sign-in has not been turned on yet in your Firebase Project (skyfur-eac18).',
                                        style: TextStyle(
                                          color: Colors.brown.shade800,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFFDE68A)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'To enable real sign-in (takes 30 seconds):',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text('1. Go to console.firebase.google.com',
                                                style: TextStyle(fontSize: 11.5, color: Color(0xFF451A03))),
                                            Text('2. Open Build > Authentication > Sign-in method',
                                                style: TextStyle(fontSize: 11.5, color: Color(0xFF451A03))),
                                            Text('3. Click "Email/Password" -> Toggle "Enable" -> Save',
                                                style: TextStyle(fontSize: 11.5, color: Color(0xFF451A03))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            demoUserLoggedInNotifier.value = true;
                                          },
                                          icon: const Icon(Icons.bolt, size: 18),
                                          label: const Text('Enter App in Demo Mode Now'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D9488),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ] else if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Optional Name for sign-up
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    labelText: 'Pet Parent Name',
                                    hintText: 'e.g. Alex Smith',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'alex@example.com',
                                  prefixIcon: const Icon(Icons.mail_outline),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: _isSignUp
                                      ? 'At least 6 characters'
                                      : 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (_isSignUp && value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isSignUp
                                                ? Icons.person_add_alt_1
                                                : Icons.login,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isSignUp
                                                ? 'Create Account'
                                                : 'Sign In',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 18),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade400,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade300)),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Demo Mode Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  demoUserLoggedInNotifier.value = true;
                                },
                                icon: const Icon(Icons.bolt, color: Color(0xFF0D9488)),
                                label: const Text(
                                  'Explore with Demo Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0D9488),
                                  side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Instant access: test Dog CEO breed photo, scans, vets & insurance',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Protected by Firebase Security',
                      style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthModeTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthModeTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.blueGrey[600],
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
