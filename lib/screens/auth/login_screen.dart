import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../navigation/main_navigation_screen.dart';
import '../superadmin/super_admin_dashboard.dart';
import '../choyxona_admin/choyxona_admin_dashboard.dart';
import 'register_screen.dart';

/// Экран входа
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Определяем, ввёл ли пользователь телефон или email
    String loginValue = _emailController.text.trim();
    String emailToUse;
    
    // Если начинается с + или содержит только цифры — это телефон
    if (loginValue.startsWith('+') || RegExp(r'^[0-9]+$').hasMatch(loginValue)) {
      // Конвертируем телефон в email
      final cleanPhone = loginValue.replaceAll(RegExp(r'[^0-9]'), '');
      emailToUse = '$cleanPhone@choyxona.local';
    } else {
      emailToUse = loginValue;
    }

    final result = await _authService.signInWithEmail(
      email: emailToUse,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final user = result['user'] as UserModel;

      // Редирект в зависимости от роли
      Widget destination;
      switch (user.role) {
        case UserRole.superAdmin:
          destination = const SuperAdminDashboard();
          break;
        case UserRole.choyxonaAdmin:
        case UserRole.choyxonaOwner:
          destination = const ChoyxonaAdminDashboard();
          break;
        default:
          destination = const MainNavigationScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      _showErrorSnackbar(result['message']);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fill entire screen
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.authGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),

                            // Лого и приветствие
                            _buildHeader(),

                            const SizedBox(height: 48),

                            // Email
                            _buildEmailField(),

                            const SizedBox(height: 16),

                            // Пароль
                            _buildPasswordField(),

                            const SizedBox(height: 12),

                            // Забыли пароль
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                child: Text(
                                  'Parolni unutdingizmi?',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.emeraldGreen,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Кнопка входа
                            _buildLoginButton(),

                            const SizedBox(height: 24),

                            // Разделитель
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white24)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'yoki',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white24)),
                              ],
                            ),

                            const Spacer(),

                            // Регистрация - pushed to bottom
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Akkauntingiz yo\'qmi? ',
                                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Ro\'yxatdan o\'tish',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.emeraldGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo rasmi
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.emeraldGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/choyxona_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Xush kelibsiz!',
          style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Davom etish uchun tizimga kiring',
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Telefon yoki Email',
        hintText: '+998 90 123 45 67 yoki email@example.com',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Telefon yoki email kiriting';
        }
        
        // Telefon yoki email formatini tekshirish
        final cleanValue = value.trim();
        
        // Telefon formati (+998 bilan boshlansa yoki faqat raqamlar)
        if (cleanValue.startsWith('+') || RegExp(r'^[0-9]+$').hasMatch(cleanValue.replaceAll(' ', ''))) {
          final cleanPhone = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanPhone.length < 9) {
            return 'Telefon raqami kamida 9 ta raqam bo\'lishi kerak';
          }
          if (cleanPhone.length > 12) {
            return 'Telefon raqami juda uzun';
          }
        } else {
          // Email formati
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(cleanValue)) {
            return 'Noto\'g\'ri email formati';
          }
        }
        
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Parol',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Parolni kiriting';
        }
        if (value.length < 6) {
          return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldGreen, // Brand color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: AppColors.textWhite,
            strokeWidth: 2,
          ),
        )
            : Text(
          'Kirish',
          style: AppTextStyles.button,
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (context) => _ForgotPasswordDialog(),
    );

    if (email == null || email.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(email: email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? AppColors.success : AppColors.error,
      ),
    );
  }
}

/// Диалог восстановления пароля
class _ForgotPasswordDialog extends StatefulWidget {
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Восстановление пароля',
        style: AppTextStyles.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Введите email для восстановления пароля',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@mail.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _emailController.text.trim());
          },
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}