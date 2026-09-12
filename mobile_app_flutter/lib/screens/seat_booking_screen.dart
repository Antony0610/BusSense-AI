import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/transit_models.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';

class SeatBookingScreen extends StatefulWidget {
  final BusModel bus;

  const SeatBookingScreen({super.key, required this.bus});

  @override
  State<SeatBookingScreen> createState() => _SeatBookingScreenState();
}

class _SeatBookingScreenState extends State<SeatBookingScreen> {
  int? _selectedSeat;
  TicketModel? _confirmedTicket;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bus.busId} Seat Reservation'),
        backgroundColor: ObsidianTransitTheme.bgDeep,
      ),
      body: _confirmedTicket != null
          ? _buildTicketConfirmedView(_confirmedTicket!)
          : _buildSeatSelectionView(provider),
    );
  }

  Widget _buildSeatSelectionView(TransitProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Route Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ObsidianTransitTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bus.routeName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Route ${widget.bus.routeNumber} | Operator: ${widget.bus.operatorType}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ObsidianTransitTheme.emeraldGreen),
                  ),
                  child: const Text('20% GREEN DISC.', style: TextStyle(color: ObsidianTransitTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bus Cabin Shell
          Center(
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ObsidianTransitTheme.bgDeep,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(8)),
                border: Border.all(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🚪 FRONT DOOR', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('☸ DRIVER CABIN', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  // 2x2 Grid of 40 Seats
                  Column(
                    children: List.generate(10, (row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSeatButton(row * 4 + 1),
                            _buildSeatButton(row * 4 + 2),
                            const SizedBox(width: 24), // Aisle
                            _buildSeatButton(row * 4 + 3),
                            _buildSeatButton(row * 4 + 4),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ObsidianTransitTheme.cyanGlow,
              foregroundColor: ObsidianTransitTheme.bgDeep,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: (_selectedSeat != null && !_isBooking)
                ? () async {
                    setState(() => _isBooking = true);
                    final t = await provider.bookSeat(
                      busId: widget.bus.busId,
                      routeNumber: widget.bus.routeNumber,
                      seatNumber: '$_selectedSeat',
                      originStop: 'Thampanoor Central',
                      destinationStop: 'Technopark Phase 1',
                      fareAmount: 32.0,
                    );
                    setState(() {
                      _isBooking = false;
                      _confirmedTicket = t;
                    });
                  }
                : null,
            child: _isBooking
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _selectedSeat == null
                        ? 'Select a Seat to Continue'
                        : 'Confirm Seat #$_selectedSeat (₹32.00 - 20% OFF)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatButton(int seatNum) {
    final bool isBooked = (seatNum % 5 == 0);
    final bool isWomen = (seatNum <= 8);
    final bool isSelected = (_selectedSeat == seatNum);

    Color bg = ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.12);
    Color border = ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.4);
    Color text = ObsidianTransitTheme.emeraldGreen;

    if (isBooked) {
      bg = Colors.white10;
      border = Colors.white12;
      text = Colors.grey;
    } else if (isSelected) {
      bg = ObsidianTransitTheme.cyanGlow;
      border = Colors.white;
      text = Colors.black;
    } else if (isWomen) {
      bg = const Color(0x26FF66CC);
      border = const Color(0xFFFF66CC);
      text = const Color(0xFFFF85D5);
    }

    return GestureDetector(
      onTap: isBooked
          ? null
          : () {
              setState(() => _selectedSeat = seatNum);
            },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          '$seatNum',
          style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTicketConfirmedView(TicketModel ticket) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BUSSENSE SMART PASS', style: TextStyle(color: ObsidianTransitTheme.cyanGlow, fontWeight: FontWeight.w900)),
                    Text('● VERIFIED', style: TextStyle(color: ObsidianTransitTheme.emeraldGreen, fontWeight: FontWeight.w800, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: ticket.qrCodeHash,
                  version: QrVersions.auto,
                  size: 160.0,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ObsidianTransitTheme.cyanGlow),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ObsidianTransitTheme.cyanGlow),
                  backgroundColor: ObsidianTransitTheme.bgCard,
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Seat Number:', style: TextStyle(color: Colors.grey)),
                    Text('Seat #${ticket.seatNumber}', style: const TextStyle(color: ObsidianTransitTheme.cyanGlow, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bus & Route:', style: TextStyle(color: Colors.grey)),
                    Text('${ticket.busId} (${ticket.routeNumber})', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fare Paid:', style: TextStyle(color: Colors.grey)),
                    Text('₹${ticket.fareAmount.toStringAsFixed(2)} (Green Disc)', style: const TextStyle(color: ObsidianTransitTheme.emeraldGreen, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ObsidianTransitTheme.cyanGlow,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Live Tracking', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
