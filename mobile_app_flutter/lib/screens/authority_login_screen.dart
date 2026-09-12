import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../theme/obsidian_theme.dart';

class AuthorityLoginScreen extends StatefulWidget {
  const AuthorityLoginScreen({super.key});

  @override
  State<AuthorityLoginScreen> createState() => _AuthorityLoginScreenState();
}

class _AuthorityLoginScreenState extends State<AuthorityLoginScreen> {
  final _emailController = TextEditingController(text: 'dispatcher@kerala.transit.gov');
  final _passController = TextEditingController(text: 'kerala-transit-secure');
  String _selectedStation = 'KL-AUTH-09';

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
                    color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.security, color: ObsidianTransitTheme.emeraldGreen, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transit Authority Terminal',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Official Dispatcher authentication for Kerala Transit Command & Autonomous Fleet HUD.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 28),

              const Text('OFFICIAL DISPATCHER ID', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ObsidianTransitTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),

              const Text('SECURITY PASSCODE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: ObsidianTransitTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),

              const Text('DISPATCH STATION COMMAND BADGE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
                    value: _selectedStation,
                    dropdownColor: ObsidianTransitTheme.bgCard,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'KL-AUTH-09', child: Text('KL-AUTH-09 (Trivandrum Central Command)', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'KL-AUTH-02', child: Text('KL-AUTH-02 (Ernakulam Hub Dispatch)', style: TextStyle(color: Colors.white, fontSize: 13))),
                      DropdownMenuItem(value: 'KL-AUTH-04', child: Text('KL-AUTH-04 (Kozhikode North Hub)', style: TextStyle(color: Colors.white, fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStation = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('🔒 ', style: TextStyle(fontSize: 20)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End-to-End Encrypted Dispatch Protocol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                          Text('Authorized personnel: KSRTC & Motor Vehicles Dept only.', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ObsidianTransitTheme.emeraldGreen,
                  foregroundColor: const Color(0xFF050811),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.switchRole('authority');
                  Navigator.pushReplacementNamed(context, '/authority/command');
                },
                child: const Text('Unlock Command Console', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              const SizedBox(height: 10),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ObsidianTransitTheme.emeraldGreen,
                  side: BorderSide(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  provider.switchRole('authority');
                  Navigator.pushReplacementNamed(context, '/authority/command');
                },
                child: const Text('⚡ 1-Click Dispatcher Demo Access', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
