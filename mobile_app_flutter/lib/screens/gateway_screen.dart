import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.directions_bus, color: ObsidianTransitTheme.cyanGlow, size: 36),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Climate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  '🌱 KERALA CLIMATE-SMART TRANSIT NETWORK',
                  style: TextStyle(
                    color: ObsidianTransitTheme.emeraldGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  children: [
                    TextSpan(text: 'Next-Gen Intelligent\n'),
                    TextSpan(
                      text: 'Transit Grid',
                      style: TextStyle(color: ObsidianTransitTheme.cyanGlow),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Autonomous fleet crowd tracking, atomic seat reservation with 20% off-peak green savings, and instant emergency triage — 100% powered by Supabase Cloud PostGIS.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 28),

              // Split Choice Cards
              _buildPortalCard(
                context,
                title: 'Passenger Portal',
                subtitle: 'KSRTC & Private Bus Commuter',
                badgeText: 'COMMUTER PASS',
                icon: Icons.directions_walk,
                themeColor: ObsidianTransitTheme.cyanGlow,
                features: const [
                  '📡 Live GPS Radar & Kerala Route Tracking',
                  '👥 Edge YOLOv8 AI Crowding Telemetry',
                  '🌱 20% Off-Peak Green Transit Savings',
                  '💺 Interactive 2x2 Seat Reservation',
                  '🎫 Holographic Smart QR Boarding Pass',
                  '⏰ AI Wake-Up Proximity Geofence Alarm',
                ],
                primaryActionText: '⚡ Quick Commuter Radar',
                secondaryActionText: '👤 Commuter Sign-In',
                onPrimaryTap: () {
                  final provider = Provider.of<TransitProvider>(context, listen: false);
                  provider.switchRole('passenger');
                  Navigator.pushReplacementNamed(context, '/passenger');
                },
                onSecondaryTap: () {
                  Navigator.pushNamed(context, '/auth/passenger');
                },
              ),
              const SizedBox(height: 20),

              _buildPortalCard(
                context,
                title: 'Authority Command',
                subtitle: 'KSRTC & MVD Fleet Dispatch',
                badgeText: 'DISPATCH COMMAND',
                icon: Icons.security,
                themeColor: ObsidianTransitTheme.emeraldGreen,
                features: const [
                  '🗺️ Realtime PostGIS Fleet Telemetry HUD',
                  '🤖 Autonomous AI Fleet Surge Rebalancing',
                  '🚨 Emergency SOS Triage & Police 112 Link',
                  '📷 Conductor Smart QR Verification Terminal',
                  '📹 Edge Camera Anonymized Passenger Feed',
                  '⚡ Instant Relief Electric Bus Deployment',
                ],
                primaryActionText: '🛡️ Dispatcher Command Login',
                onPrimaryTap: () {
                  Navigator.pushNamed(context, '/auth/admin');
                },
              ),
              const SizedBox(height: 28),

              // Cloud Status Bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: ObsidianTransitTheme.emeraldGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Supabase Cloud PostgreSQL 16 (ap-south-1)',
                          style: TextStyle(color: ObsidianTransitTheme.emeraldGreen, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '5 Stored RPCs Active • Direct Client Access • Zero Local Server',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required Color themeColor,
    required List<String> features,
    required String primaryActionText,
    String? secondaryActionText,
    required VoidCallback onPrimaryTap,
    VoidCallback? onSecondaryTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ObsidianTransitTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: themeColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: themeColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  f,
                  style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5),
                ),
              )),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: const Color(0xFF050811),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onPrimaryTap,
            child: Text(primaryActionText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          if (secondaryActionText != null && onSecondaryTap != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onSecondaryTap,
              child: Text(secondaryActionText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
