import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

/// Экран регистрации
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController(); // Ixtiyoriy email
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showErrorSnackbar('Примите условия использования');
      return;
    }

    setState(() => _isLoading = true);

    // Agar email kiritilgan bo'lsa - uni ishlatamiz, aks holda telefon bilan generatsiya
    final cleanPhone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final email = _emailController.text.trim().isNotEmpty 
        ? _emailController.text.trim() 
        : '$cleanPhone@choyxona.local';

    final result = await _authService.signUpWithEmail(
      email: email,
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: 'client',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // Показываем успешное сообщение
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SuccessDialog(
          message: result['message'],
          onContinue: () {
            Navigator.of(context).pop(); // Закрыть диалог
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // Имя
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'Имя',
                    hint: 'Рустам',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите имя';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Фамилия
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Фамилия',
                    hint: 'Абдувахобов',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите фамилию';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Телефон
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefon *',
                    hint: '+998 90 123 45 67',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefon raqamini kiriting';
                      }
                      // Telefon raqamini tekshirish
                      final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleanPhone.length < 9) {
                        return 'Telefon raqami kamida 9 ta raqamdan iborat bo\'lishi kerak';
                      }
                      if (cleanPhone.length > 12) {
                        return 'Telefon raqami juda uzun';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email (ixtiyoriy)
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email (ixtiyoriy)',
                    hint: 'example@gmail.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        // Email formatini tekshirish
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Noto\'g\'ri email formati';
                        }
                      }
                      return null; // Ixtiyoriy
                    },
                  ),

                  const SizedBox(height: 16),

                  // Пароль
                  _buildPasswordField(
                    controller: _passwordController,
                    label: 'Пароль',
                    obscure: _obscurePassword,
                    onToggle: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      if (value.length < 6) {
                        return 'Минимум 6 символов';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Подтверждение пароля
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Подтвердите пароль',
                    obscure: _obscureConfirmPassword,
                    onToggle: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Подтвердите пароль';
                      }
                      if (value != _passwordController.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Согласие с условиями
                  _buildTermsCheckbox(),

                  const SizedBox(height: 24),

                  // Кнопка регистрации
                  _buildRegisterButton(),

                  const SizedBox(height: 24),

                  // Уже есть аккаунт
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Уже есть аккаунт? ',
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Войти',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Создать аккаунт',
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Заполните данные для регистрации',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() => _agreeToTerms = value ?? false);
          },
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _agreeToTerms = !_agreeToTerms);
            },
            child: Text(
              'Я согласен с условиями использования и политикой конфиденциальности',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
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
          'Зарегистрироваться',
          style: AppTextStyles.button,
        ),
      ),
    );
  }
}

/// Диалог успешной регистрации
class _SuccessDialog extends StatelessWidget {
  final String message;
  final VoidCallback onContinue;

  const _SuccessDialog({
    required this.message,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 50,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Регистрация успешна!',
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            child: const Text('Продолжить'),
          ),
        ),
      ],
    );
  }
}