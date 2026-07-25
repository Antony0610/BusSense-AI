import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../theme/app_theme.dart';

class BusCardWidget extends StatelessWidget {
  final BusModel bus;
  final VoidCallback? onTap;

  const BusCardWidget({Key? key, required this.bus, this.onTap}) : super(key: key);

  Color _getBadgeColor(String level) {
    switch (level.toLowerCase()) {
      case 'red':
        return AppTheme.redCrowd;
      case 'yellow':
        return AppTheme.yellowCrowd;
      default:
        return AppTheme.greenCrowd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor(bus.crowdLevel);
    final isKsrtc = bus.operatorType == 'KSRTC';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row
              Row(
                mainAxisAlignment: MainAlignment.between,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isKsrtc
                              ? const Color(0xFF00796B).withOpacity(0.18)
                              : const Color(0xFFF59E0B).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isKsrtc ? const Color(0xFF00796B).withOpacity(0.4) : const Color(0xFFF59E0B).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          isKsrtc ? '🚍' : '🚌',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bus.operatorType} ${bus.busId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'ROUTE ${bus.routeNumber}',
                                style: const TextStyle(
                                  color: Color(0xFF26A69A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ETA ${bus.etaMinutes} MINS',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Crowd Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: badgeColor.withOpacity(0.6), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${bus.occupancyPercentage.round()}% ${bus.crowdLevel.toUpperCase()}',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Organized Key-Value Statistics Grid
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAlignment.spaceAround,
                  children: [
                    _metricBlock('SEATS FREE', '${bus.seatAvailability}', Icons.event_seat_outlined),
                    _verticalDivider(),
                    _metricBlock('SEAT CHANCE', '${bus.seatProbability}%', Icons.airline_seat_recline_normal),
                    _verticalDivider(),
                    _metricBlock('COMFORT SCORE', '${bus.comfortScore}/100', Icons.auto_awesome),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Comfort Progress Gauge with Aesthetic Labels
              Row(
                mainAxisAlignment: MainAlignment.spaceBetween,
                children: [
                  Text(
                    'Passenger Comfort Index',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    bus.comfortScore >= 65 ? 'High Comfort ✨' : bus.comfortScore >= 40 ? 'Moderate 🟡' : 'Limited Seats 🔴',
                    style: TextStyle(
                      color: bus.comfortScore >= 65 ? AppTheme.greenCrowd : AppTheme.yellowCrowd,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: bus.comfortScore / 100.0,
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  color: bus.comfortScore >= 65 ? AppTheme.greenCrowd : AppTheme.yellowCrowd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricBlock(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF26A69A)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 24, width: 1, color: Colors.white.withOpacity(0.08));
  }
}
