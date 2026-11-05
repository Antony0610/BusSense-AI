import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/saved_place_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_empty_state.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../providers/passenger_providers.dart';
import 'passenger_explore_view.dart';

/// Screen managing commuter favorite destinations (Home, Work, College, Custom)
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  static const List<String> kochiStops = [
    'Aluva Metro Stand',
    'Edappally Toll',
    'Palarivattom Jn',
    'Kaloor Metro Stand',
    'Maharajas Ground',
    'Kakkanad Infopark Gate 1',
    'Vyttila Mobility Hub',
    'MG Road Metro',
  ];

  void _showAddPlaceSheet(BuildContext context, WidgetRef ref) {
    String label = 'Home';
    String selectedStop = kochiStops.first;
    final textController = TextEditingController(text: 'Home');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Saved Place', style: AppTypography.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Preset chips
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: ['Home', 'Work', 'College', 'Custom'].map((preset) {
                      final isSelected = label == preset;
                      return ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setSheetState(() {
                              label = preset;
                              textController.text = preset;
                            });
                          }
                        },
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Label input
                  Text('Place Label', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Home, Work, Infopark',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.roundedSm,
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                    ),
                    onChanged: (val) => label = val,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Stop Picker
                  Text('Destination Stop', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStop,
                        isExpanded: true,
                        items: kochiStops.map((stop) {
                          return DropdownMenuItem(value: stop, child: Text(stop));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedStop = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Save button
                  BusSenseButton(
                    label: 'Save Place',
                    variant: ButtonVariant.primary,
                    icon: Icons.bookmark_add_rounded,
                    onPressed: () {
                      final cleanLabel = label.trim().isNotEmpty ? label.trim() : 'Saved Place';
                      final newPlace = SavedPlaceModel(
                        id: 'fav-new-${DateTime.now().millisecondsSinceEpoch}',
                        label: cleanLabel,
                        itemType: 'DESTINATION',
                        referenceId: selectedStop,
                        address: '$selectedStop, Greater Kochi',
                        category: PlaceCategory.fromString(cleanLabel),
                      );
                      ref.read(savedPlacesProvider.notifier).addPlace(newPlace);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved "$cleanLabel" destination'),
                          backgroundColor: AppColors.secondary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SavedPlaceModel place) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Saved Place?'),
          content: Text('Are you sure you want to remove "${place.label}" from your saved destinations?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(savedPlacesProvider.notifier).deletePlace(place.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${place.label}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForCategory(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.home:
        return Icons.home_rounded;
      case PlaceCategory.work:
        return Icons.business_rounded;
      case PlaceCategory.college:
        return Icons.school_rounded;
      case PlaceCategory.custom:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlacesAsync = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Saved Places', style: AppTypography.titleLarge),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.secondary),
            tooltip: 'Add Place',
            onPressed: () => _showAddPlaceSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: savedPlacesAsync.when(
          loading: () => const BusSenseLoading(message: 'Loading saved destinations...'),
          error: (err, st) => Center(
            child: Padding(
              padding: AppSpacing.paddingScreen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Failed to load saved places', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  BusSenseButton(
                    label: 'Retry',
                    variant: ButtonVariant.outline,
                    onPressed: () => ref.read(savedPlacesProvider.notifier).fetchSavedPlaces(),
                  ),
                ],
              ),
            ),
          ),
          data: (places) {
            if (places.isEmpty) {
              return Center(
                child: Padding(
                  padding: AppSpacing.paddingScreen,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BusSenseEmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No Saved Places',
                        message: 'Save places you travel to often for rapid 1-tap route planning.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      BusSenseButton(
                        label: 'Add First Place',
                        variant: ButtonVariant.primary,
                        icon: Icons.add_location_alt_rounded,
                        onPressed: () => _showAddPlaceSheet(context, ref),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: AppSpacing.paddingScreen,
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final place = places[index];
                return Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getIconForCategory(place.category), color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.label, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              place.referenceId,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                            ),
                            if (place.address != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                place.address!,
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Plan Journey Action
                      IconButton(
                        icon: const Icon(Icons.alt_route_rounded, color: AppColors.secondary),
                        tooltip: 'Plan Journey',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PassengerExploreView(initialDestination: place.referenceId),
                            ),
                          );
                        },
                      ),
                      // Delete Action
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, ref, place),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
