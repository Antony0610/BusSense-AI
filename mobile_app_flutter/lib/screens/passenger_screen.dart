import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transit_models.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';
import 'seat_booking_screen.dart';

class PassengerScreen extends StatelessWidget {
  const PassengerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/passenger',
        role: provider.currentRole,
        onNavigate: (route) {
          if (route == '/') {
            Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: ObsidianTransitTheme.cyanGlow, size: 20),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                text: 'BusSense ',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                children: [
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(color: ObsidianTransitTheme.cyanGlow),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
          TextButton(
            onPressed: () => provider.toggleLanguage(),
            child: Text(
              provider.currentLang == 'en' ? 'മലയാളം' : 'ENG',
              style: const TextStyle(color: ObsidianTransitTheme.cyanGlow, fontWeight: FontWeight.w800),
            ),
          ),
          // Switch to Gateway
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.grey),
            tooltip: 'Switch Portal',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshBuses(),
        child: Column(
          children: [
            // Route Filter Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildRouteChip(context, provider, 'ALL', 'All Routes'),
                  _buildRouteChip(context, provider, 'R1', 'R1: Kazhakkoottam'),
                  _buildRouteChip(context, provider, 'R2', 'R2: Kovalam'),
                  _buildRouteChip(context, provider, 'R3', 'R3: Technopark'),
                  _buildRouteChip(context, provider, 'R4', 'R4: Medical Col.'),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Bus List
            Expanded(
              child: provider.isLoading && provider.buses.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: ObsidianTransitTheme.cyanGlow))
                  : provider.buses.isEmpty
                      ? const Center(child: Text('No buses currently active on this route.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.buses.length,
                          itemBuilder: (ctx, index) {
                            return _buildBusCard(context, provider, provider.buses[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      // 1-Tap SOS Safety Shield Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ObsidianTransitTheme.crimsonDanger,
        foregroundColor: Colors.white,
        onPressed: () async {
          final alert = await provider.triggerSOS(
            latitude: 8.5241,
            longitude: 76.9366,
            busId: 'KSRTC-101',
            routeNumber: 'R1',
          );
          if (context.mounted && alert != null) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: ObsidianTransitTheme.bgCard,
                title: const Row(
                  children: [
                    Text('🚨 ', style: TextStyle(fontSize: 22)),
                    Text('EMERGENCY SOS TRANSMITTED', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 15, fontWeight: FontWeight.w900)),
                  ],
                ),
                content: Text(
                  'Your GPS coordinates have been beamed to the Kerala Police 112 Control Room and Transit Authority Command Console.\n\nAlert ID: ${alert.sosId}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        },
        icon: const Icon(Icons.shield),
        label: const Text('1-TAP SOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildRouteChip(BuildContext context, TransitProvider provider, String routeCode, String label) {
    final bool isSelected = (provider.activeRoute == routeCode);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        labelStyle: TextStyle(
          color: isSelected ? ObsidianTransitTheme.cyanGlow : const Color(0xFF94A3B8),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected ? ObsidianTransitTheme.cyanGlow : Colors.transparent,
        ),
        onSelected: (_) => provider.setActiveRoute(routeCode),
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, TransitProvider provider, BusModel bus) {
    Color crowdColor = ObsidianTransitTheme.emeraldGreen;
    String crowdLabel = provider.currentLang == 'en' ? 'Seats Available' : 'സീറ്റുകൾ ഉണ്ട്';

    if (bus.occupancyPercentage >= 85) {
      crowdColor = ObsidianTransitTheme.crimsonDanger;
      crowdLabel = provider.currentLang == 'en' ? 'Overcrowded' : 'അമിത തിരക്ക്';
    } else if (bus.occupancyPercentage >= 50) {
      crowdColor = ObsidianTransitTheme.amberWarn;
      crowdLabel = provider.currentLang == 'en' ? 'Standing Only' : 'നിൽക്കാൻ മാത്രം';
    }

    final String routeTitle = provider.currentLang == 'en' ? bus.routeName : bus.routeNameMl;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('🚍 ${bus.busId}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bus.operatorType == 'PRIVATE'
                            ? ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.15)
                            : ObsidianTransitTheme.ksrtcRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bus.operatorType == 'PRIVATE' ? 'PRIVATE' : 'KSRTC',
                        style: TextStyle(
                          color: bus.operatorType == 'PRIVATE' ? ObsidianTransitTheme.emeraldGreen : const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: crowdColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: crowdColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    crowdLabel,
                    style: TextStyle(color: crowdColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(routeTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Route ${bus.routeNumber} • Trivandrum Corridor', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ETA', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('${bus.etaMinutes} min', style: const TextStyle(fontWeight: FontWeight.w900, color: ObsidianTransitTheme.cyanGlow, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FREE SEATS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('${bus.seatAvailability} / ${bus.capacity}', style: const TextStyle(fontWeight: FontWeight.w900, color: ObsidianTransitTheme.emeraldGreen, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CO₂ SAVINGS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('${bus.co2ReductionKg} kg', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ObsidianTransitTheme.cyanGlow,
                      foregroundColor: ObsidianTransitTheme.bgDeep,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SeatBookingScreen(bus: bus)),
                      );
                    },
                    child: const Text('Reserve Seat (-20%)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.alarm, color: ObsidianTransitTheme.cyanGlow),
                  tooltip: 'Wake-Up Proximity Alarm',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔔 Wake-Up Alarm Armed for this bus! Will chime 500m before destination.'),
                        backgroundColor: ObsidianTransitTheme.cyanGlow,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
