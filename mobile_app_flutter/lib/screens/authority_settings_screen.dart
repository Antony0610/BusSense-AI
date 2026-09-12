import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';

class AuthoritySettingsScreen extends StatefulWidget {
  const AuthoritySettingsScreen({super.key});

  @override
  State<AuthoritySettingsScreen> createState() => _AuthoritySettingsScreenState();
}

class _AuthoritySettingsScreenState extends State<AuthoritySettingsScreen> {
  double _rebalanceThreshold = 85.0;
  bool _autoPoliceDispatch = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Dispatcher System Config', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: ObsidianTransitTheme.bgCard,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/authority/settings',
        role: 'authority',
        onNavigate: (route) {
          if (route == '/') {
            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dispatcher Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0x2200FF9D),
                      child: Icon(Icons.security, color: ObsidianTransitTheme.emeraldGreen, size: 28),
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dispatcher KL-AUTH-09', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        SizedBox(height: 2),
                        Text('Trivandrum Central Fleet Command', style: TextStyle(fontSize: 11, color: ObsidianTransitTheme.emeraldGreen, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Autonomous Dispatch Rules
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_mode, color: ObsidianTransitTheme.emeraldGreen, size: 18),
                        SizedBox(width: 8),
                        Text('Autonomous AI Fleet Rules', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Surge Threshold', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                        Text('${_rebalanceThreshold.round()}% Load', style: const TextStyle(color: ObsidianTransitTheme.amberWarn, fontWeight: FontWeight.w800, fontSize: 12)),
                      ],
                    ),
                    Slider(
                      value: _rebalanceThreshold,
                      min: 70,
                      max: 95,
                      divisions: 5,
                      activeColor: ObsidianTransitTheme.emeraldGreen,
                      onChanged: (v) => setState(() => _rebalanceThreshold = v),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Police 112 Auto-Link', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                            Text('Auto-broadcast SOS to police radar', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                        Switch(
                          value: _autoPoliceDispatch,
                          activeThumbColor: ObsidianTransitTheme.emeraldGreen,
                          onChanged: (v) => setState(() => _autoPoliceDispatch = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B6B),
                  side: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Exit Dispatch Terminal to Gateway', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  provider.switchRole('passenger');
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
