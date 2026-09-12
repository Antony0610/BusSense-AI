import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';

class SosBeaconScreen extends StatefulWidget {
  const SosBeaconScreen({super.key});

  @override
  State<SosBeaconScreen> createState() => _SosBeaconScreenState();
}

class _SosBeaconScreenState extends State<SosBeaconScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransitProvider>(context, listen: false);
      provider.triggerSOS(
        latitude: 8.5241,
        longitude: 76.9366,
        busId: 'COMMUTER-APP-SOS',
        routeNumber: 'R1',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0408),
      appBar: AppBar(
        title: const Text('EMERGENCY DISTRESS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: ObsidianTransitTheme.crimsonDanger, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield, color: ObsidianTransitTheme.crimsonDanger, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'BEACON ACTIVE: POLICE 112 NOTIFIED',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFF6B6B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your live GPS coordinates have been broadcast to the Kerala Police 112 Control Room and the Transit Authority Command Center.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  children: [
                    Text('LATITUDE: 8.5241 | LONGITUDE: 76.9366', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, fontFamily: 'monospace')),
                    SizedBox(height: 4),
                    Text('CORRIDOR: Trivandrum Central • ACCURACY: ±3m', style: TextStyle(color: Colors.amber, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ObsidianTransitTheme.emeraldGreen,
                  foregroundColor: const Color(0xFF050811),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Safe Now / Deactivate Beacon', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/passenger');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
