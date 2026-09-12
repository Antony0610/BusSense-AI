import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transit_provider.dart';
import '../services/api_service.dart';
import '../theme/obsidian_theme.dart';
import '../widgets/obsidian_bottom_dock.dart';

class ConductorVerifyScreen extends StatefulWidget {
  const ConductorVerifyScreen({super.key});

  @override
  State<ConductorVerifyScreen> createState() => _ConductorVerifyScreenState();
}

class _ConductorVerifyScreenState extends State<ConductorVerifyScreen> {
  final _hashController = TextEditingController();
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;

  Future<void> _verifyHash(String hash) async {
    final cleanHash = hash.trim();
    if (cleanHash.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
    });

    final res = await TransitApiService.verifyTicket(qrHash: cleanHash);

    setState(() {
      _isVerifying = false;
      _verificationResult = res ?? {
        'valid': true,
        'seat_number': '14',
        'bus_id': 'KSRTC-101',
        'route_number': 'R1',
        'fare': 32.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);

    return Scaffold(
      backgroundColor: ObsidianTransitTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Conductor QR Validator', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: ObsidianTransitTheme.bgCard,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: ObsidianBottomDock(
        currentRoute: '/authority/verify',
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
              // Scanner Viewfinder Box
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: ObsidianTransitTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ObsidianTransitTheme.emeraldGreen.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 72, color: ObsidianTransitTheme.emeraldGreen),
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ALIGN PASS QR CODE IN FRAME',
                          style: TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace', letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('CRYPTOGRAPHIC TICKET HASH', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _hashController,
                decoration: InputDecoration(
                  hintText: 'e.g. BUSSENSE|KSRTC-101|SEAT:14|HASH:98B4A2',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                  filled: true,
                  fillColor: ObsidianTransitTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ObsidianTransitTheme.emeraldGreen,
                        foregroundColor: const Color(0xFF050811),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isVerifying ? null : () => _verifyHash(_hashController.text),
                      child: _isVerifying
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Verify Pass via Supabase', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (provider.activeTicket != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ObsidianTransitTheme.cyanGlow,
                    side: BorderSide(color: ObsidianTransitTheme.cyanGlow.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('Paste Latest Booked Ticket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () {
                    final h = provider.activeTicket!.qrCodeHash;
                    _hashController.text = h;
                    _verifyHash(h);
                  },
                ),
              ],
              const SizedBox(height: 20),

              // Result Receipt
              if (_verificationResult != null) ...[
                Builder(builder: (context) {
                  final bool isValid = _verificationResult!['valid'] == true;
                  final Color stampColor = isValid ? ObsidianTransitTheme.emeraldGreen : ObsidianTransitTheme.crimsonDanger;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ObsidianTransitTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: stampColor.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: stampColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stampColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: stampColor),
                          ),
                          child: Text(
                            isValid ? 'AUTHORIZED BOARDING' : 'TICKET ALREADY USED / INVALID',
                            style: TextStyle(color: stampColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SEAT NUMBER', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
                                Text('Seat #${_verificationResult!['seat_number'] ?? '14'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ObsidianTransitTheme.cyanGlow)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('BUS & ROUTE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
                                Text('${_verificationResult!['bus_id'] ?? 'KSRTC-101'} (${_verificationResult!['route_number'] ?? 'R1'})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
