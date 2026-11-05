import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../providers/passenger_providers.dart';

/// Screen allowing commuters to update supported profile details (Full Name, Preferred Language)
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedLanguage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _selectedLanguage = widget.user.preferredLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(passengerRepositoryProvider);
      final updatedUser = await repository.updateUserProfile(
        fullName: _nameController.text.trim(),
        preferredLanguage: _selectedLanguage,
      );

      // Refresh preferences notifier
      ref.read(userPreferencesProvider.notifier).setLanguage(_selectedLanguage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to update profile. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Edit Profile', style: AppTypography.titleLarge),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar representation
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'P',
                          style: AppTypography.displayMedium.copyWith(color: AppColors.accent),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, size: 18, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Error Banner if present
                if (_errorMessage != null) ...[
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Full Name
                Text('Full Name', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Email (Read-Only)
                Text('Email Address', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  initialValue: widget.user.email,
                  readOnly: true,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Authentication-controlled identity. Email cannot be modified.',
                  style: AppTypography.labelSmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                // Phone Number (Read-Only)
                Text('Mobile Number', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  initialValue: widget.user.phoneNumber,
                  readOnly: true,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedSm,
                      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified mobile identifier used for security sessions.',
                  style: AppTypography.labelSmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Preferred Language
                Text('Preferred Language', style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English (India)')),
                        DropdownMenuItem(value: 'ml', child: Text('മലയാളം (Malayalam)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLanguage = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Action
                BusSenseButton(
                  label: _isLoading ? 'Saving Changes...' : 'Save Changes',
                  variant: ButtonVariant.primary,
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
