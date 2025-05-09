//Selector/display page for the
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/stopwatch.dart';
import 'widgets/timer.dart';

//simple timer adapting the stop_watch_timer package and the example code there
class TimerPage extends StatefulWidget {
  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  String mode = 'timer';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 12,
          ), // Adjust this number as needed
          child: CupertinoSegmentedControl<String>(
            children: {
              'timer': Padding(
                padding: const EdgeInsets.all(8),
                child: Text('timer'),
              ),
              'stopwatch': Padding(
                padding: const EdgeInsets.all(8),
                child: Text('stopwatch'),
              ),
            },
            groupValue: mode,
            onValueChanged: (String selectedMode) {
              setState(() => mode = selectedMode);
            },
          ),
        ),
        SizedBox(height: 20),
        if (mode == 'timer') TimerWidget(),
        if (mode == 'stopwatch') StopwatchWidget(),
      ],
    );
  }
}
