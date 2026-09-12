import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';

class PassengerSettingsScreen extends StatefulWidget {
  const PassengerSettingsScreen({super.key});

  @override
  State<PassengerSettingsScreen> createState() => _PassengerSettingsScreenState();
}

class _PassengerSettingsScreenState extends State<PassengerSettingsScreen> {
  int _selectedRadius = 500;
  String _selectedStop = 'Technopark Phase 1';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Commuter Preferences', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: ObsidianTransitTheme.bgCard,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/passenger/settings',
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
              // Commuter Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: ObsidianTransitTheme.cyanGlow, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Commuter User', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                            SizedBox(height: 2),
                            Text('🌱 Silver Eco-Commuter • BusSense Kerala', style: TextStyle(fontSize: 11, color: ObsidianTransitTheme.emeraldGreen, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.only(top: 14),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(val: '14.8 kg', label: 'CO₂ Prevented', color: ObsidianTransitTheme.cyanGlow),
                          _StatItem(val: '120 pts', label: 'Green Points', color: ObsidianTransitTheme.emeraldGreen),
                          _StatItem(val: '8', label: 'Clean Trips', color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Language & Localization
              _buildSection(
                title: 'Language & Localization',
                icon: Icons.language,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Interface Language', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('English or authentic മലയാളം', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('English'),
                            selected: provider.currentLang == 'en',
                            selectedColor: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2),
                            onSelected: (_) {
                              if (provider.currentLang != 'en') provider.toggleLanguage();
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('മലയാളം'),
                            selected: provider.currentLang == 'ml',
                            selectedColor: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2),
                            onSelected: (_) {
                              if (provider.currentLang != 'ml') provider.toggleLanguage();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: AI Wake-Up Proximity Geofence
              _buildSection(
                title: 'AI Wake-Up Destination Alarm',
                icon: Icons.alarm,
                children: [
                  const Text('Geofence Proximity Radius', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Trigger wake-up chime before reaching destination bus stop', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [300, 500, 1000].map((radius) {
                      final isSelected = _selectedRadius == radius;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(radius >= 1000 ? '1 km' : '${radius}m'),
                          selected: isSelected,
                          selectedColor: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.2),
                          onSelected: (_) => setState(() => _selectedRadius = radius),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text('Monitored Destination Stop', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: ObsidianTransitTheme.bgDeep,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStop,
                        isExpanded: true,
                        dropdownColor: ObsidianTransitTheme.bgCard,
                        items: const [
                          DropdownMenuItem(value: 'Technopark Phase 1', child: Text('Technopark Phase 1 (Route R1/R3)', style: TextStyle(fontSize: 12, color: Colors.white))),
                          DropdownMenuItem(value: 'Kazhakkoottam Junction', child: Text('Kazhakkoottam Junction (Route R1)', style: TextStyle(fontSize: 12, color: Colors.white))),
                          DropdownMenuItem(value: 'Kovalam Junction', child: Text('Kovalam Junction (Route R2)', style: TextStyle(fontSize: 12, color: Colors.white))),
                          DropdownMenuItem(value: 'Medical College', child: Text('Medical College (Route R4)', style: TextStyle(fontSize: 12, color: Colors.white))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStop = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: Supabase Cloud Diagnostics
              _buildSection(
                title: 'Supabase Cloud Diagnostics',
                icon: Icons.cloud_done,
                children: [
                  _buildDiagRow('Cloud Endpoint', 'https://kxeixcnqoudxicorxlxs.supabase.co'),
                  _buildDiagRow('PostgreSQL 16 Engine', 'PostGIS 3.4 (ap-south-1)'),
                  _buildDiagRow('Direct Stored RPCs', '5 Functions Registered & Verified'),
                  _buildDiagRow('Connection Latency', '● 24ms (Healthy)', highlightColor: ObsidianTransitTheme.emeraldGreen),
                  _buildDiagRow('Backend Architecture', '100% Serverless Direct (0 Local Daemons)'),
                ],
              ),
              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B6B),
                  side: BorderSide(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Switch Portal / Return to Gateway', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ObsidianTransitTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ObsidianTransitTheme.cyanGlow, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: highlightColor ?? Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String val;
  final String label;
  final Color color;

  const _StatItem({required this.val, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, fontFamily: 'monospace')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
