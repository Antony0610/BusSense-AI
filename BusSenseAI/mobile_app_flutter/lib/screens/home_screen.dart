import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bus_provider.dart';
import '../widgets/bus_card_widget.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hero Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00796B), Color(0xFF26A69A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAlignment.spaceBetween,
                  children: [
                    Text(
                      'CLIMATE-SMART TRANSIT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('AI Live', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the Smartest Bus Now',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.4),
                ),
                const SizedBox(height: 16),
                _searchTextField('SOURCE LOCATION', 'Thampanoor Central Stop', Icons.my_location),
                const SizedBox(height: 10),
                _searchTextField('DESTINATION', 'Technopark Campus Corridor', Icons.location_on),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filtering optimal low-crowd buses for your corridor...')),
                      );
                    },
                    child: const Text(
                      'FIND LESS-CROWDED BUSES',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick Executive Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _ecoOverviewCard('NEARBY FLEET', '${busProvider.buses.length}', Icons.directions_bus),
                const SizedBox(width: 10),
                _ecoOverviewCard('BEST COMFORT', '${busProvider.sortedByComfort.firstOrNull?.comfortScore ?? 85}/100', Icons.auto_awesome),
                const SizedBox(width: 10),
                _ecoOverviewCard('CO₂ SAVED', '${busProvider.stats['estimated_co2_reduction_kg'] ?? 42.6} kg', Icons.eco),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended Buses',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
                ),
                Text(
                  'Updated Just Now',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (busProvider.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(30.0), child: CircularProgressIndicator()))
          else
            ...busProvider.sortedByComfort.map((bus) => BusCardWidget(bus: bus)).toList(),
        ],
      ),
    );
  }

  Widget _searchTextField(String label, String initialVal, IconData icon) {
    return TextField(
      controller: TextEditingController(text: initialVal),
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        filled: true,
        fillColor: Colors.white.withOpacity(0.16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _ecoOverviewCard(String label, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF12232E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentTeal, size: 20),
            const SizedBox(height: 6),
            Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}
