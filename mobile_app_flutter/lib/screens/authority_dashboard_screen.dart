import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transit_models.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';

class AuthorityDashboardScreen extends StatelessWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    final int activeCount = provider.buses.length;
    final int avgLoad = provider.buses.isEmpty
        ? 0
        : (provider.buses.fold<double>(0.0, (acc, b) => acc + b.occupancyPercentage) / provider.buses.length).round();

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/authority/command',
        role: 'authority',
        onNavigate: (route) {
          if (route == '/') {
            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xEB0B132B),
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text('🛡️ ', style: TextStyle(fontSize: 20)),
            Text(
              'AUTHORITY COMMAND HUD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFFF6B6B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Exit to Gateway',
            onPressed: () {
              provider.switchRole('passenger');
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshBuses(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Metrics Strip
              Row(
                children: [
                  _buildMetricBox('Active Buses', '$activeCount', ObsidianTransitTheme.cyanGlow, '🚍'),
                  const SizedBox(width: 12),
                  _buildMetricBox('Avg Fleet Load', '$avgLoad%', ObsidianTransitTheme.emeraldGreen, '👥'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricBox('Overcrowded', '1 Route', ObsidianTransitTheme.amberWarn, '⚠️'),
                  const SizedBox(width: 12),
                  _buildMetricBox('Active SOS', '${provider.activeSosIncidents.length}', ObsidianTransitTheme.crimsonDanger, '🚨'),
                ],
              ),
              const SizedBox(height: 20),

              // Autonomous AI Fleet Rebalance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('🤖 ', style: TextStyle(fontSize: 18)),
                              Text(
                                'AI Autonomous Fleet Rebalance',
                                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ),
                          Text('POSTGIS REALTIME', style: TextStyle(color: ObsidianTransitTheme.cyanGlow, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Route R3 (Thampanoor ➔ Technopark) detected at 96% peak capacity. Recommend deploying reserve electric bus.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ObsidianTransitTheme.emeraldGreen,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () async {
                          final ok = await provider.deployReliefBus(
                            routeNumber: 'R3',
                            reason: 'Autonomous rebalance: Route R3 at 96% critical capacity',
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? '⚡ Autonomous Relief Bus RELIEF-EV-901 Dispatched!' : 'Dispatch failed'),
                                backgroundColor: ObsidianTransitTheme.emeraldGreen,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.flash_on, color: Colors.black),
                        label: const Text('Deploy Relief Electric Bus', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Emergency SOS Incident Triage Queue
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('🚨 ', style: TextStyle(fontSize: 18)),
                              Text(
                                'Emergency SOS Radar',
                                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('POLICE 112 ACTIVE', style: TextStyle(color: ObsidianTransitTheme.crimsonDanger, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.activeSosIncidents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No active distress calls. Corridors clear.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...provider.activeSosIncidents.map((sos) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ObsidianTransitTheme.crimsonDanger.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('DISTRESS: ${sos.sosId}', style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('Lat: ${sos.latitude.toStringAsFixed(4)}, Lng: ${sos.longitude.toStringAsFixed(4)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.local_police, color: Colors.white, size: 20),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Police Unit 112 Dispatched!')),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: ObsidianTransitTheme.emeraldGreen, size: 20),
                                        onPressed: () => provider.resolveSOS(sos.sosId),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Fleet Telemetry List
              const Text('LIVE FLEET STATUS', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 10),
              ...provider.buses.map((bus) => _buildBusTelemetryRow(bus)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color, String icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ObsidianTransitTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusTelemetryRow(BusModel bus) {
    Color loadColor = bus.occupancyPercentage >= 85
        ? ObsidianTransitTheme.crimsonDanger
        : (bus.occupancyPercentage >= 50 ? ObsidianTransitTheme.amberWarn : ObsidianTransitTheme.emeraldGreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ObsidianTransitTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${bus.busId} (${bus.routeNumber})', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              Text('${bus.speedKmh} km/h • ETA: ${bus.etaMinutes} min', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text(
            '${bus.occupancyPercentage.toStringAsFixed(0)}% Load',
            style: TextStyle(color: loadColor, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
