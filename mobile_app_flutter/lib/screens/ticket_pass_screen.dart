import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';

class TicketPassScreen extends StatelessWidget {
  const TicketPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final ticket = provider.activeTicket;

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Smart Holographic Pass', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: ObsidianTransitTheme.bgCard,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/passenger/ticket',
        role: provider.currentRole,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ticket == null) ...[
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: ObsidianTransitTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No Active Ticket Booked', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('Reserve a seat from the Live Radar to generate your holographic boarding pass.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ObsidianTransitTheme.cyanGlow, foregroundColor: const Color(0xFF050811)),
                          onPressed: () => Navigator.pushReplacementNamed(context, '/passenger'),
                          child: const Text('Explore Nearby Buses', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Holographic Pass Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ObsidianTransitTheme.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('BUSSENSE SMART PASS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ObsidianTransitTheme.cyanGlow, letterSpacing: 0.8)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.4)),
                            ),
                            child: const Text('● VERIFIED', style: TextStyle(color: ObsidianTransitTheme.emeraldGreen, fontWeight: FontWeight.w800, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: ticket.qrCodeHash,
                          version: QrVersions.auto,
                          size: 160.0,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Grid details
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('PASSENGER', 'Commuter User', 'SEAT ALLOTMENT', 'Seat #${ticket.seatNumber}', isHighlight: true),
                            const SizedBox(height: 12),
                            _buildDetailRow('BUS ID & ROUTE', '${ticket.busId} (${ticket.routeNumber})', 'FARE (20% OFF)', '₹${ticket.fareAmount.toStringAsFixed(2)}', isGreen: true),
                            const SizedBox(height: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CRYPTOGRAPHIC QR TOKEN', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Text(
                                    ticket.qrCodeHash,
                                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ObsidianTransitTheme.cyanGlow,
                    foregroundColor: const Color(0xFF050811),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.radar, size: 18),
                  label: const Text('Return to Live Fleet Radar', style: TextStyle(fontWeight: FontWeight.w900)),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/passenger'),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Verification Token', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ticket.qrCodeHash));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket Hash copied to clipboard!')),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String k1, String v1, String k2, String v2, {bool isHighlight = false, bool isGreen = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k1, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(v1, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k2, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                v2,
                style: TextStyle(
                  color: isHighlight ? ObsidianTransitTheme.cyanGlow : (isGreen ? ObsidianTransitTheme.emeraldGreen : Colors.white),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: isHighlight ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
