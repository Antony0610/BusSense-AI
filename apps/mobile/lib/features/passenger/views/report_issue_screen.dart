import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/passenger_report_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';

/// Screen allowing commuters to submit service, vehicle, crowding, and app issues
class ReportIssueScreen extends ConsumerStatefulWidget {
  final String? initialBusNumber;
  final String? initialRouteNumber;

  const ReportIssueScreen({
    super.key,
    this.initialBusNumber,
    this.initialRouteNumber,
  });

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'BUS_VEHICLE';
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _busController;
  late final TextEditingController _routeController;
  bool _isSubmitting = false;
  PassengerReportModel? _submittedReport;

  static const List<Map<String, String>> categories = [
    {'value': 'BUS_VEHICLE', 'label': 'Bus / Vehicle Condition'},
    {'value': 'ROUTE_DELAY', 'label': 'Route Delay / Missed Stop'},
    {'value': 'TICKET_PAYMENT', 'label': 'Ticket / QR / Payment'},
    {'value': 'LOCATION_ETA', 'label': 'Incorrect GPS Location / ETA'},
    {'value': 'CROWD_FORECAST', 'label': 'Inaccurate Crowd Forecast'},
    {'value': 'APP_BUG', 'label': 'Application Bug'},
    {'value': 'OTHER', 'label': 'Other Feedback'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _busController = TextEditingController(text: widget.initialBusNumber ?? '');
    _routeController = TextEditingController(text: widget.initialRouteNumber ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _busController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final report = PassengerReportModel(
      id: '',
      category: _category,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      busNumber: _busController.text.trim().isNotEmpty ? _busController.text.trim() : null,
      routeNumber: _routeController.text.trim().isNotEmpty ? _routeController.text.trim() : null,
      createdAt: DateTime.now().toIso8601String(),
    );

    final result = await ref.read(passengerReportsProvider.notifier).submitReport(report);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submittedReport = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Report an Issue', style: AppTypography.titleLarge),
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
          child: _submittedReport != null
              ? _buildSuccessView()
              : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.check_circle_outline_rounded, color: AppColors.accent, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Report Submitted',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your transit issue report has been logged to the BusSense incident queue.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Report Reference:', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                    BusSenseStatusBadge(label: _submittedReport!.id, tone: BadgeTone.info),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Category: ${_submittedReport!.categoryDisplay}', style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('Title: ${_submittedReport!.title}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          BusSenseButton(
            label: 'Submit Another Report',
            variant: ButtonVariant.outline,
            onPressed: () {
              setState(() {
                _submittedReport = null;
                _titleController.clear();
                _descriptionController.clear();
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          BusSenseButton(
            label: 'Back to Profile',
            variant: ButtonVariant.primary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tell us what went wrong',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Reports help improve Kochi bus reliability and crowd intelligence.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Category Dropdown
          Text('Issue Category', style: AppTypography.labelLarge),
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
                value: _category,
                isExpanded: true,
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat['value'], child: Text(cat['label']!));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text('Title / Summary', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Brief summary of the issue',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSm,
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please provide an issue title';
              if (val.trim().length < 3) return 'Title must be at least 3 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Bus / Route (Optional)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bus Number (Optional)', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _busController,
                      decoration: InputDecoration(
                        hintText: 'e.g. 205',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedSm,
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Route (Optional)', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _routeController,
                      decoration: InputDecoration(
                        hintText: 'e.g. 12',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedSm,
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text('Description', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe details such as stop location, delay length, or vehicle condition...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSm,
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please describe the issue';
              if (val.trim().length < 5) return 'Description must be at least 5 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          BusSenseButton(
            label: _isSubmitting ? 'Submitting Report...' : 'Submit Issue Report',
            variant: ButtonVariant.primary,
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}
