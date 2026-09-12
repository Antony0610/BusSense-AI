import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';

class PassengerLoginScreen extends StatefulWidget {
  const PassengerLoginScreen({super.key});

  @override
  State<PassengerLoginScreen> createState() => _PassengerLoginScreenState();
}

class _PassengerLoginScreenState extends State<PassengerLoginScreen> {
  final _nameController = TextEditingController(text: 'Commuter User');
  final _phoneController = TextEditingController(text: '+91 98470 12345');
  String _selectedRoute = 'R1';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Back to Gateway', style: TextStyle(fontSize: 14, color: Colors.grey)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.directions_walk, color: ObsidianTransitTheme.cyanGlow, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Commuter Sign-In',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Access your eco-savings wallet, saved passes, and destination alarms.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Form
              const Text('COMMUTER FULL NAME', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Rahul Nair',
                  filled: true,
                  fillColor: ObsidianTransitTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),

              const Text('MOBILE NUMBER', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+91 XXXXX XXXXX',
                  filled: true,
                  fillColor: ObsidianTransitTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),

              const Text('PREFERRED TRAVEL CORRIDOR', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoute,
                    dropdownColor: ObsidianTransitTheme.bgCard,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'R1', child: Text('Route R1: Thampanoor ➔ Kazhakkoottam', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'R2', child: Text('Route R2: East Fort ➔ Kovalam', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'R3', child: Text('Route R3: Thampanoor ➔ Technopark', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'R4', child: Text('Route R4: East Fort ➔ Medical College', style: TextStyle(color: Colors.white, fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoute = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Eco Perks Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('🌱 ', style: TextStyle(fontSize: 20)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('+50 BusSense EcoPoints Credited', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                          Text('Redeem for 20% off-peak green tickets across Kerala.', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ObsidianTransitTheme.cyanGlow,
                  foregroundColor: const Color(0xFF050811),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.switchRole('passenger');
                  provider.setActiveRoute(_selectedRoute);
                  Navigator.pushReplacementNamed(context, '/passenger');
                },
                child: const Text('Launch Commuter Live Radar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              const SizedBox(height: 10),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ObsidianTransitTheme.cyanGlow,
                  side: BorderSide(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.switchRole('passenger');
                  Navigator.pushReplacementNamed(context, '/passenger');
                },
                child: const Text('⚡ Quick Access as Guest (No Setup)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
