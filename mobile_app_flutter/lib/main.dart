import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transit_provider.dart';
import 'screens/authority_dashboard_screen.dart';
import 'screens/authority_login_screen.dart';
import 'screens/authority_settings_screen.dart';
import 'screens/conductor_verify_screen.dart';
import 'screens/eco_wallet_screen.dart';
import 'screens/gateway_screen.dart';
import 'screens/passenger_login_screen.dart';
import 'screens/passenger_screen.dart';
import 'screens/passenger_settings_screen.dart';
import 'screens/sos_beacon_screen.dart';
import 'screens/ticket_pass_screen.dart';
import 'theme/obsidian_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BusSenseAIApp());
}

class BusSenseAIApp extends StatelessWidget {
  const BusSenseAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransitProvider()),
      ],
      child: MaterialApp(
        title: 'BusSense AI',
        debugShowCheckedModeBanner: false,
        theme: ObsidianTransitTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const GatewayScreen(),
          '/auth/passenger': (context) => const PassengerLoginScreen(),
          '/auth/admin': (context) => const AuthorityLoginScreen(),
          '/passenger': (context) => const PassengerScreen(),
          '/passenger/ticket': (context) => const TicketPassScreen(),
          '/passenger/wallet': (context) => const EcoWalletScreen(),
          '/passenger/settings': (context) => const PassengerSettingsScreen(),
          '/authority/command': (context) => const AuthorityDashboardScreen(),
          '/authority/verify': (context) => const ConductorVerifyScreen(),
          '/authority/settings': (context) => const AuthoritySettingsScreen(),
          '/sos': (context) => const SosBeaconScreen(),
        },
      ),
    );
  }
}
