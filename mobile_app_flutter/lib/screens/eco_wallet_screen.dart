import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';

class EcoWalletScreen extends StatefulWidget {
  const EcoWalletScreen({super.key});

  @override
  State<EcoWalletScreen> createState() => _EcoWalletScreenState();
}

class _EcoWalletScreenState extends State<EcoWalletScreen> {
  int _ecoPoints = 170;
  final double _co2SavedKg = 18.2;
  String? _redeemedCoupon;

  void _redeemPerk(String title, int cost) {
    if (_ecoPoints >= cost) {
      setState(() {
        _ecoPoints -= cost;
        _redeemedCoupon = 'REDEEMED: $title (Code: ECO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)})';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher claimed: $title!'),
          backgroundColor: ObsidianTransitTheme.emeraldGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient EcoPoints. Take off-peak bus trips to earn more!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      appBar: AppBar(
        title: const Text('EcoPass CO₂ Wallet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: ObsidianTransitTheme.bgCard,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/passenger/wallet',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // EcoPoints Holographic Hero Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.25),
                      ObsidianTransitTheme.bgCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.15),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.eco, color: ObsidianTransitTheme.emeraldGreen, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'ECOPASS BALANCE',
                              style: TextStyle(
                                color: ObsidianTransitTheme.emeraldGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Text('🌱 Green Tier 2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '$_ecoPoints',
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text('Green EcoPoints Available', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MetricCol(val: '${_co2SavedKg.toStringAsFixed(1)} kg', label: 'CO₂ Avoided', color: ObsidianTransitTheme.cyanGlow),
                          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.1)),
                          const _MetricCol(val: '1.4 Trees', label: 'Oxygen Credit', color: ObsidianTransitTheme.emeraldGreen),
                          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.1)),
                          const _MetricCol(val: '9 Trips', label: 'Electric Transit', color: Colors.amberAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_redeemedCoupon != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: ObsidianTransitTheme.emeraldGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _redeemedCoupon!,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text(
                'REDEEM GREEN TRANSIT PERKS',
                style: TextStyle(
                  color: ObsidianTransitTheme.cyanGlow,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Redeem Cards
              _PerkCard(
                title: '20% Off-Peak Commuter Coupon',
                desc: 'Valid on all KSRTC Fast Passenger corridors 10am-4pm.',
                cost: 50,
                icon: Icons.percent,
                onRedeem: () => _redeemPerk('20% Off-Peak Coupon', 50),
              ),
              const SizedBox(height: 10),
              _PerkCard(
                title: '1 Free Electric City Hop',
                desc: 'Free ride on Thiruvananthapuram City Electric Swift buses.',
                cost: 100,
                icon: Icons.directions_bus_filled,
                onRedeem: () => _redeemPerk('Free Electric City Hop', 100),
              ),
              const SizedBox(height: 10),
              _PerkCard(
                title: 'KSRTC Swift Priority Pass',
                desc: 'Advance boarding guarantee on peak IT corridor routes.',
                cost: 250,
                icon: Icons.verified,
                onRedeem: () => _redeemPerk('Priority Boarding Pass', 250),
              ),

              const SizedBox(height: 24),
              const Text(
                'CARBON REDUCTION LEDGER',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Column(
                  children: [
                    _LedgerRow(
                      title: 'Route R1 Off-Peak Trip',
                      subtitle: 'Technopark -> Central Station (12.4 km)',
                      points: '+15 pts',
                      co2: '-2.1 kg CO₂',
                    ),
                    Divider(color: Colors.white10, height: 1),
                    _LedgerRow(
                      title: 'Electric Shuttle Commute',
                      subtitle: 'Kazhakkoottam -> Infosys Campus',
                      points: '+20 pts',
                      co2: '-3.4 kg CO₂',
                    ),
                    Divider(color: Colors.white10, height: 1),
                    _LedgerRow(
                      title: 'BusSense Sign-Up Bonus',
                      subtitle: 'Kerala Green Commuter Incentive',
                      points: '+50 pts',
                      co2: 'EcoPass Activated',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _MetricCol({required this.val, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _PerkCard extends StatelessWidget {
  final String title;
  final String desc;
  final int cost;
  final IconData icon;
  final VoidCallback onRedeem;

  const _PerkCard({
    required this.title,
    required this.desc,
    required this.cost,
    required this.icon,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ObsidianTransitTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ObsidianTransitTheme.emeraldGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onRedeem,
            style: ElevatedButton.styleFrom(
              backgroundColor: ObsidianTransitTheme.emeraldGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
            child: Text('$cost pts'),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String points;
  final String co2;

  const _LedgerRow({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.co2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: ObsidianTransitTheme.cyanGlow, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(points, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: ObsidianTransitTheme.emeraldGreen)),
              Text(co2, style: const TextStyle(fontSize: 10, color: ObsidianTransitTheme.cyanGlow)),
            ],
          ),
        ],
      ),
    );
  }
}
