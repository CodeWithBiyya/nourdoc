import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _seconds = 0;
  int _minutes = 0;
  int _hours = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_seconds >= 60) {
          _seconds = 0;
          _minutes++;
        }
        if (_minutes >= 60) {
          _minutes = 0;
          _hours++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String formatTime(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return  Text(
          '${formatTime(_hours)}:${formatTime(_minutes)}:${formatTime(_seconds)}',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        );

  }
}