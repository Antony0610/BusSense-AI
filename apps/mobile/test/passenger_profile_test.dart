import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bussense_mobile/core/network/api_client.dart';
import 'package:bussense_mobile/core/storage/secure_token_storage.dart';
import 'package:bussense_mobile/features/auth/controllers/auth_controller.dart';
import 'package:bussense_mobile/features/passenger/data/passenger_repository.dart';
import 'package:bussense_mobile/features/passenger/providers/passenger_providers.dart';
import 'package:bussense_mobile/features/passenger/views/edit_profile_screen.dart';
import 'package:bussense_mobile/features/passenger/views/help_support_screen.dart';
import 'package:bussense_mobile/features/passenger/views/language_appearance_screen.dart';
import 'package:bussense_mobile/features/passenger/views/notification_preferences_screen.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_profile_view.dart';
import 'package:bussense_mobile/features/passenger/views/privacy_data_screen.dart';
import 'package:bussense_mobile/features/passenger/views/report_issue_screen.dart';
import 'package:bussense_mobile/features/passenger/views/saved_places_screen.dart';
import 'package:bussense_mobile/shared/models/ai_message_model.dart';
import 'package:bussense_mobile/shared/models/alert_model.dart';
import 'package:bussense_mobile/shared/models/bus_model.dart';
import 'package:bussense_mobile/shared/models/crowd_model.dart';
import 'package:bussense_mobile/shared/models/location_model.dart';
import 'package:bussense_mobile/shared/models/passenger_report_model.dart';
import 'package:bussense_mobile/shared/models/prediction_model.dart';
import 'package:bussense_mobile/shared/models/recommendation_model.dart';
import 'package:bussense_mobile/shared/models/saved_place_model.dart';
import 'package:bussense_mobile/shared/models/ticket_model.dart';
import 'package:bussense_mobile/shared/models/trip_model.dart';
import 'package:bussense_mobile/shared/models/user_model.dart';
import 'package:bussense_mobile/shared/models/user_preferences_model.dart';
import 'package:bussense_mobile/shared/models/notification_item_model.dart';
import 'package:bussense_mobile/shared/widgets/bussense_button.dart';

const testUser = UserModel(
  id: 'usr-aarav',
  email: 'aarav.nair@bussense.ai',
  fullName: 'Aarav Nair',
  phoneNumber: '+91 98470 12345',
  role: UserRole.passenger,
  preferredLanguage: 'en',
);

class MockProfilePassengerRepository implements IPassengerRepository {
  bool shouldFail;
  List<SavedPlaceModel> savedPlacesList;
  UserPreferencesModel currentPreferences;

  MockProfilePassengerRepository({
    this.shouldFail = false,
    List<SavedPlaceModel>? savedPlaces,
    UserPreferencesModel? preferences,
  })  : savedPlacesList = savedPlaces ?? [
          const SavedPlaceModel(
            id: 'sp-home',
            label: 'Home',
            referenceId: 'Angamaly Bus Station',
            category: PlaceCategory.home,
            createdAt: '2026-09-27T08:00:00Z',
          ),
          const SavedPlaceModel(
            id: 'sp-work',
            label: 'Office Hub',
            referenceId: 'Infopark Phase 1',
            category: PlaceCategory.work,
            createdAt: '2026-09-27T08:00:00Z',
          ),
        ],
        currentPreferences = preferences ?? const UserPreferencesModel();

  @override
  Future<UserModel> getUserProfile() async {
    if (shouldFail) throw Exception('Profile load failed');
    return testUser;
  }

  @override
  Future<UserModel> updateUserProfile({required String fullName, String? preferredLanguage}) async {
    if (shouldFail) throw Exception('Profile update failed');
    return testUser.copyWith(
      fullName: fullName,
      preferredLanguage: preferredLanguage ?? 'en',
    );
  }

  @override
  Future<List<SavedPlaceModel>> getSavedPlaces() async {
    if (shouldFail) throw Exception('Saved places fetch failed');
    return savedPlacesList;
  }

  @override
  Future<SavedPlaceModel> addSavedPlace(SavedPlaceModel place) async {
    if (shouldFail) throw Exception('Failed to add saved place');
    savedPlacesList = [...savedPlacesList, place];
    return place;
  }

  @override
  Future<void> deleteSavedPlace(String placeId) async {
    if (shouldFail) throw Exception('Failed to delete saved place');
    savedPlacesList = savedPlacesList.where((p) => p.id != placeId).toList();
  }

  @override
  Future<UserPreferencesModel> getUserPreferences() async {
    if (shouldFail) throw Exception('Preferences fetch failed');
    return currentPreferences;
  }

  @override
  Future<UserPreferencesModel> updateUserPreferences(UserPreferencesModel preferences) async {
    if (shouldFail) throw Exception('Preferences update failed');
    currentPreferences = preferences;
    return currentPreferences;
  }

  @override
  Future<PassengerReportModel> submitPassengerReport(PassengerReportModel report) async {
    if (shouldFail) throw Exception('Report submission failed');
    return report.copyWith(
      id: 'rep-mock-9988',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<Map<String, dynamic>> exportUserData() async {
    if (shouldFail) throw Exception('Export request failed');
    return {
      'status': 'OK',
      'user_id': 'usr-aarav',
      'email': 'aarav.nair@bussense.ai',
      'tickets_count': 1,
      'saved_places_count': savedPlacesList.length,
      'classification': 'PROTOTYPE EXPORT ARCHIVE',
    };
  }

  @override
  Future<void> deactivateAccount() async {
    if (shouldFail) throw Exception('Deactivation failed');
  }

  // Baseline stubs for other interface methods
  @override
  Future<List<BusModel>> getLiveBuses() async => [];
  @override
  Future<BusModel> getBusDetails(String busNumber) async => throw UnimplementedError();
  @override
  Future<List<LocationModel>> getLiveLocations() async => [];
  @override
  Future<LocationModel?> getBusLocation(String busIdentifier) async => null;
  @override
  Future<List<CrowdModel>> getFleetCrowd() async => [];
  @override
  Future<CrowdModel?> getBusCrowd(String busIdentifier) async => null;
  @override
  Future<PredictionModel> getBusPrediction(String busNumber) async => throw UnimplementedError();
  @override
  Future<JourneyPlanModel> getJourneyPlan({required String origin, required String destination}) async => throw UnimplementedError();
  @override
  Future<List<AlertModel>> getActiveAlerts() async => [];
  @override
  Future<List<TripModel>> getActiveTrips() async => [];
  @override
  Future<TicketModel> bookTicket({required String busNumber, required String routeNumber, required String originStop, required String destinationStop, required String passengerName, required double fareAmount, String? tripId, String paymentMethod = 'SIMULATED_UPI'}) async => throw UnimplementedError();
  @override
  Future<List<TicketModel>> getMyTickets() async => [];
  @override
  Future<AIQueryResponse> askAiAssistant({required String question, String? activeBusContext, String? destinationContext, String? ticketId}) async => throw UnimplementedError();

  @override
  Future<List<NotificationItemModel>> getNotifications({bool unreadOnly = false, int limit = 20, int offset = 0}) async => [];

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<bool> markNotificationRead(String notificationId) async => true;

  @override
  Future<int> markAllNotificationsRead() async => 0;
}

class FakeAuthController extends AuthController {
  bool didLogout = false;

  FakeAuthController()
      : super(
          ApiClient(tokenStorage: InMemoryTokenStorage()),
          InMemoryTokenStorage(),
        ) {
    state = const Authenticated(testUser);
  }

  @override
  Future<void> logout() async {
    didLogout = true;
    state = const Unauthenticated();
  }
}

void main() {
  Widget createWidget({
    required Widget child,
    MockProfilePassengerRepository? repository,
    FakeAuthController? authController,
  }) {
    return ProviderScope(
      overrides: [
        if (repository != null)
          passengerRepositoryProvider.overrideWithValue(repository),
        if (authController != null)
          authControllerProvider.overrideWith((ref) => authController),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Phase H5 Batch 4 — Passenger Profile & Settings Tests', () {
    testWidgets('1. Profile screen renders commuter identity and core sections', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const Scaffold(body: PassengerProfileView(user: testUser)),
          repository: MockProfilePassengerRepository(),
        ),
      );
      await tester.pumpAndSettle();

      // Identity
      expect(find.text('Aarav Nair'), findsOneWidget);
      expect(find.text('aarav.nair@bussense.ai'), findsOneWidget);
      expect(find.text('PASSENGER'), findsOneWidget);

      // Section titles
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('TRAVEL & SHORTCUTS'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('PRIVACY & CONTROL'), findsOneWidget);
      expect(find.text('SUPPORT & FEEDBACK'), findsOneWidget);

      // Core action rows
      expect(find.text('Saved Places'), findsOneWidget);
      expect(find.text('Favorite Route'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy & Data Controls'), findsOneWidget);
      expect(find.text('Help & FAQ'), findsOneWidget);
      expect(find.text('Report an Issue'), findsOneWidget);
      expect(find.text('About BusSense AI'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('2. Edit Profile screen renders current user details and read-only phone', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const EditProfileScreen(user: testUser),
          repository: MockProfilePassengerRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Aarav Nair'), findsOneWidget);
      expect(find.text('aarav.nair@bussense.ai'), findsOneWidget);
      expect(find.text('+91 98470 12345'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('3. Edit Profile validates empty full name', (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const EditProfileScreen(user: testUser),
          repository: MockProfilePassengerRepository(),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('4. Edit Profile updates profile and pops with updated model', (tester) async {
      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen(user: testUser)),
                  ),
                  child: const Text('Launch Edit'),
                ),
              ),
            ),
          ),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);

      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Aarav G. Nair');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Launch Edit'), findsOneWidget);
      expect(find.text('Edit Profile'), findsNothing);
    });

    testWidgets('5. Saved Places populated state renders saved destinations', (tester) async {
      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const SavedPlacesScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Places'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Angamaly Bus Station'), findsOneWidget);
      expect(find.text('Office Hub'), findsOneWidget);
      expect(find.text('Infopark Phase 1'), findsOneWidget);
    });

    testWidgets('6. Saved Places empty state renders informative prompt', (tester) async {
      final repo = MockProfilePassengerRepository(savedPlaces: []);
      await tester.pumpWidget(
        createWidget(
          child: const SavedPlacesScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Saved Places'), findsOneWidget);
      expect(find.text('Add First Place'), findsOneWidget);
    });

    testWidgets('7. Saved Places opens Add Place bottom sheet and adds destination', (tester) async {
      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const SavedPlacesScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap + button
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Add Saved Place'), findsOneWidget);
      expect(find.text('Save Place'), findsOneWidget);

      // Enter label
      final labelField = find.byType(TextField).first;
      await tester.enterText(labelField, 'Campus');

      await tester.tap(find.text('Save Place'));
      await tester.pumpAndSettle();

      expect(find.text('Campus'), findsOneWidget);
    });

    testWidgets('8. Saved Places delete confirmation removes destination', (tester) async {
      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const SavedPlacesScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);

      // Tap delete icon on first item
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Saved Place?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
    });

    testWidgets('9. Notification preferences screen renders toggles and push deferral notice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const NotificationPreferencesScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Allow Notifications'), findsOneWidget);
      expect(find.text('Bus Arrival Alerts'), findsOneWidget);
      expect(find.text('Journey & Delay Updates'), findsOneWidget);
      expect(find.text('Crowd Pressure Warnings'), findsOneWidget);
      expect(find.text('Route & Corridor Advisories'), findsOneWidget);
      expect(find.text('Booking & Pass Expiration'), findsOneWidget);
      expect(find.textContaining('PUSH DELIVERY DEFERRED'), findsOneWidget);
    });

    testWidgets('10. Language & Appearance screen renders language selection and Stitch surfaces', (tester) async {
      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const LanguageAppearanceScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Language & Appearance'), findsOneWidget);
      expect(find.text('English (India)'), findsOneWidget);
      expect(find.textContaining('മലയാളം'), findsOneWidget);
      expect(find.text('PARTIAL / PREPARED'), findsOneWidget);
      expect(find.text('Light Surface'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('11. Privacy & Data screen displays factual disclosures and download UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const PrivacyDataScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data'), findsOneWidget);
      expect(find.text('BusSense AI Factual Privacy Disclosures'), findsOneWidget);
      expect(find.text('Onboard Computer Vision'), findsOneWidget);
      expect(find.text('ZERO BIOMETRICS'), findsOneWidget);
      expect(find.text('GPS & Telemetry'), findsOneWidget);
      expect(find.text('NO BACKGROUND TRACKING'), findsOneWidget);
      expect(find.text('Download My Data'), findsOneWidget);
      expect(find.text('Request Export'), findsOneWidget);
      expect(find.text('Deactivate Account'), findsOneWidget);
    });

    testWidgets('12. Help & FAQ renders grounded FAQs with expandable accordion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createWidget(
          child: const HelpSupportScreen(),
          repository: MockProfilePassengerRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & FAQ'), findsOneWidget);
      expect(find.text('How is cabin crowd level calculated?'), findsOneWidget);
      expect(find.text('Why did BusSense recommend this bus?'), findsOneWidget);
      expect(find.text('How does the digital QR boarding pass work?'), findsOneWidget);
      expect(find.text('Report an Issue'), findsWidgets);

      // Expand first FAQ
      await tester.tap(find.text('How is cabin crowd level calculated?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('YOLOv8'), findsOneWidget);
    });

    testWidgets('13. Report Issue screen validates input and submits report with reference ID', (tester) async {
      final repo = MockProfilePassengerRepository();
      await tester.pumpWidget(
        createWidget(
          child: const ReportIssueScreen(),
          repository: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report an Issue'), findsOneWidget);
      expect(find.text('Submit Issue Report'), findsOneWidget);

      // Enter title and description
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'Trip Delay Issue');
      await tester.enterText(textFields.last, 'Bus 205 was delayed by 15 minutes due to heavy rain at Edappally.');

      await tester.ensureVisible(find.widgetWithText(BusSenseButton, 'Submit Issue Report'));
      await tester.tap(find.widgetWithText(BusSenseButton, 'Submit Issue Report'));
      await tester.pumpAndSettle();

      expect(find.text('Report Submitted'), findsOneWidget);
      expect(find.text('REP-MOCK-9988'), findsOneWidget);
    });

    testWidgets('14. Sign Out button triggers logout immediately', (tester) async {
      final authCtrl = FakeAuthController();
      await tester.pumpWidget(
        createWidget(
          child: const Scaffold(body: PassengerProfileView(user: testUser)),
          repository: MockProfilePassengerRepository(),
          authController: authCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Out
      final signOutButton = find.widgetWithText(BusSenseButton, 'Sign Out');
      expect(signOutButton, findsOneWidget);
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      expect(authCtrl.didLogout, isTrue);
    });
  });
}
