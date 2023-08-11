import 'package:flutter/material.dart';
import 'package:mymeds_app/components/event_card.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimeLine extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast; //to the show progress within the timeline
  final String medName;
  final String dosage;
  final String time;
  final bool isTaken;

  const TimeLine({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.medName,
    required this.dosage,
    required this.time,
    required this.isTaken,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        //decorate lines
        beforeLineStyle: LineStyle(
          color: isPast
              ? const Color.fromARGB(255, 6, 129, 151)
              : const Color.fromARGB(255, 183, 197, 200),
          thickness: 2.0,
        ),
        indicatorStyle: IndicatorStyle(
          color: isPast
              ? const Color.fromARGB(255, 6, 129, 151)
              : const Color.fromARGB(255, 183, 197, 200),
          width: 20,
        ),
        afterLineStyle: LineStyle(
          color: isPast
              ? const Color.fromARGB(255, 6, 129, 151)
              : const Color.fromARGB(255, 183, 197, 200),
          thickness: 2.0,
        ),
        endChild: EventCard(
          isPast: isPast,
          medName: medName,
          dosage: dosage,
          time: time,
          isTaken: isTaken,
        ),
      ),
    );
  }
}
