import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:stop_watch_timer/stop_watch_timer.dart';

class TimerWidget extends StatefulWidget {
  const TimerWidget();

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  final _isHours = true;

  final _stopWatchTimer = StopWatchTimer(
    mode: StopWatchMode.countDown,
    presetMillisecond: StopWatchTimer.getMilliSecFromSecond(180), //default set to 3 minutes for standard western tea brewing!
    onChange: (value) => debugPrint('onChange $value'),
    onChangeRawSecond: (value) => debugPrint('onChangeRawSecond $value'),
    onChangeRawMinute: (value) => debugPrint('onChangeRawMinute $value'),
    onStopped: () {
      debugPrint('onStopped');
    },
    onEnded: () {
      debugPrint('onEnded');
    },
  );

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _stopWatchTimer.rawTime.listen(
      (value) =>
          debugPrint('rawTime $value ${StopWatchTimer.getDisplayTime(value)}'),
    );
    _stopWatchTimer.minuteTime.listen(
      (value) => debugPrint('minuteTime $value'),
    );
    _stopWatchTimer.secondTime.listen(
      (value) => debugPrint('secondTime $value'),
    );
    _stopWatchTimer.records.listen((value) => debugPrint('records $value'));
    _stopWatchTimer.fetchStopped.listen(
      (value) => debugPrint('stopped from stream'),
    );
    _stopWatchTimer.fetchEnded.listen(
      (value) => debugPrint('ended from stream'),
    );

  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _stopWatchTimer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<int>(
              stream: _stopWatchTimer.rawTime,
              initialData: _stopWatchTimer.rawTime.value,
              builder: (context, snapshot) {
                final value = snapshot.data ?? 0;
                final displayTime = StopWatchTimer.getDisplayTime(
                  value,
                  hours: _isHours,
                );
                return Text(
                  displayTime,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _stopWatchTimer.setPresetMinuteTime(-1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Minute'),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _stopWatchTimer.setPresetMinuteTime(1),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _stopWatchTimer.setPresetSecondTime(-1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Seconds'),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _stopWatchTimer.setPresetSecondTime(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// Start / Stop / Reset buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _stopWatchTimer.onStartTimer,
                  child: const Text('Start'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopWatchTimer.onStopTimer,
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopWatchTimer.onResetTimer,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
