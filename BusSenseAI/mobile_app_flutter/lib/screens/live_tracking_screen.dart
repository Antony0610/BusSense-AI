import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bus_provider.dart';
import '../widgets/bus_card_widget.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({Key? key}) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  String _selectedOperator = 'ALL';

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final filteredBuses = busProvider.buses.where((b) {
      if (_selectedOperator == 'ALL') return true;
      return b.operatorType == _selectedOperator;
    }).toList();

    return Column(
      children: [
        // Operator Filter Segment Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _filterChip('ALL', 'All Operators'),
              const SizedBox(width: 8),
              _filterChip('KSRTC', 'KSRTC State'),
              const SizedBox(width: 8),
              _filterChip('PRIVATE', 'Private Bus'),
            ],
          ),
        ),

        // Live Bus List
        Expanded(
          child: ListView.builder(
            itemCount: filteredBuses.length,
            itemBuilder: (context, index) {
              return BusCardWidget(bus: filteredBuses[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedOperator == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedOperator = key);
      },
      selectedColor: const Color(0xFF00796B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
    );
  }
}
