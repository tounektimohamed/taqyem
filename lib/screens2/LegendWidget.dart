import 'package:flutter/material.dart';

class LegendWidget extends StatelessWidget {
  final Map<String, Color> layerColors;

  LegendWidget({required this.layerColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Colors.white.withOpacity(0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: layerColors.entries.map((entry) {
          return Row(
            children: [
              Container(
                width: 20,
                height: 20,
                color: entry.value,
              ),
              SizedBox(width: 8),
              Text(entry.key),
            ],
          );
        }).toList(),
      ),
    );
  }
}
