import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/passenger_report_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';

/// Screen allowing conductor/driver to report real-time transit hazards and operational incidents
class ConductorIncidentScreen extends ConsumerStatefulWidget {
  final String busNumber;
  final String routeNumber;

  const ConductorIncidentScreen({
    super.key,
    this.busNumber = '205',
    this.routeNumber = '12',
  });

  @override
  ConsumerState<ConductorIncidentScreen> createState() => _ConductorIncidentScreenState();
}

class _ConductorIncidentScreenState extends ConsumerState<ConductorIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'ROUTE_OBSTRUCTION';
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  PassengerReportModel? _submittedReport;

  static const List<Map<String, String>> kCategories = [
    {'value': 'ROUTE_OBSTRUCTION', 'label': 'Route Obstruction'},
    {'value': 'VEHICLE_ISSUE', 'label': 'Vehicle / Mechanical'},
    {'value': 'OVERCROWDING', 'label': 'Heavy Overcrowding'},
    {'value': 'DELAY', 'label': 'Severe Corridor Delay'},
    {'value': 'SAFETY_MEDICAL', 'label': 'Safety / Medical Alert'},
    {'value': 'OTHER', 'label': 'Other Operational Issue'},
  ];

  static const List<String> kQuickPresets = [
    'Waterlogging at Edappally bypass',
    'Cabin AC cooling unit non-functional',
    'Severe intersection gridlock at Palarivattom',
    'Medical assistance requested by passenger',
    'Low tyre pressure indicator alert',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Waterlogging at Edappally bypass');
    _descriptionController = TextEditingController(
      text: 'Heavy monsoon runoff causing 15 min crawl along the priority transit lane.',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final report = PassengerReportModel(
      id: '',
      category: _selectedCategory,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      busNumber: widget.busNumber,
      routeNumber: widget.routeNumber,
      createdAt: DateTime.now().toIso8601String(),
    );

    final repo = ref.read(conductorRepositoryProvider);
    final result = await repo.reportIncident(report);

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
        title: Text('Crew Incident Report', style: AppTypography.titleLarge),
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
          child: _submittedReport != null ? _buildSuccessView() : _buildFormView(),
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
            'Incident Logged to Dispatch',
            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Operational hazard report recorded in BusSense incident queue.',
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
                    Text('Incident Reference:', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                    BusSenseStatusBadge(label: _submittedReport!.id, tone: BadgeTone.info),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Vehicle: Bus ${widget.busNumber} • Route ${widget.routeNumber}', style: AppTypography.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('Title: ${_submittedReport!.title}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          BusSenseButton(
            label: 'Back to Operational Cockpit',
            variant: ButtonVariant.primary,
            icon: Icons.navigation_rounded,
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
          // Safety note
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'SAFETY NOTICE: Log hazards only when vehicle is safely stopped.',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Vehicle Context
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Text('Vehicle: Bus ${widget.busNumber}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Text('Route: Route ${widget.routeNumber}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Category Dropdown
          Text('Incident Category', style: AppTypography.labelLarge),
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
                value: _selectedCategory,
                isExpanded: true,
                items: kCategories.map((c) {
                  return DropdownMenuItem(value: c['value'], child: Text(c['label']!));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Presets
          Text('Quick Hazard Presets', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: kQuickPresets.map((preset) {
              return ActionChip(
                label: Text(preset, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                onPressed: () {
                  setState(() {
                    _titleController.text = preset;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text('Incident Summary', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _titleController,
            style: AppTypography.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Brief summary of the incident',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSm,
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please specify an incident summary';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text('Operational Details', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Describe lane condition, passenger impact, or delay extent...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.roundedSm,
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please provide operational details';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Truth Label
          Container(
            padding: AppSpacing.paddingSm,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'PROTOTYPE INCIDENT QUEUE: Reports are logged to the BusSense operational database.',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          BusSenseButton(
            label: _isSubmitting ? 'Reporting Hazard...' : 'Report Incident',
            variant: ButtonVariant.danger,
            icon: Icons.report_problem_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}
