import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/auth_entry_screen.dart';
import '../../features/authority/views/authority_overview_screen.dart';
import '../../features/conductor/views/conductor_shell.dart';
import '../../features/passenger/views/passenger_shell.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/bussense_loading.dart';
import '../theme/app_colors.dart';

/// Central Role-Based Dynamic Router — Google Stitch Multi-Persona Routing
/// Supports all BusSense AI personas: Commuter (Passenger), Transit Crew (Conductor),
/// and Operations Authority.
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return switch (authState) {
      AuthInitial() => const Scaffold(
          backgroundColor: AppColors.surface,
          body: BusSenseLoading(message: 'Restoring secure transit session...'),
        ),
      AuthLoading() => const Scaffold(
          backgroundColor: AppColors.surface,
          body: BusSenseLoading(message: 'Authenticating with BusSense Central...'),
        ),
      Unauthenticated() => const AuthEntryScreen(),
      AuthError() => const AuthEntryScreen(),
      Authenticated(user: final user) => _routeByRole(user, ref),
    };
  }

  Widget _routeByRole(UserModel user, WidgetRef ref) {
    switch (user.role) {
      case UserRole.passenger:
        return PassengerShell(user: user);

      case UserRole.driverConductor:
        return ConductorShell(user: user);

      case UserRole.authority:
        return AuthorityOverviewScreen(user: user);
    }
  }
}
