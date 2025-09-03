import 'dart:async';
import 'package:flutter/material.dart';

class GrowthTimerWidget extends StatefulWidget {
  final DateTime plantedAt;
  final int growTimeInSeconds;
  final VoidCallback onHarvest;

  const GrowthTimerWidget({
    required this.plantedAt,
    required this.growTimeInSeconds,
    required this.onHarvest,
    super.key,
  });

  @override
  _GrowthTimerWidgetState createState() => _GrowthTimerWidgetState();
}

class _GrowthTimerWidgetState extends State<GrowthTimerWidget> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isReadyToHarvest = false;

  @override
  void initState() {
    super.initState();
    _calculateInitialState();
  }

  @override
  void didUpdateWidget(GrowthTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se plantedAt o growTimeInSeconds cambiano, riavvia il timer
    if (oldWidget.plantedAt != widget.plantedAt ||
        oldWidget.growTimeInSeconds != widget.growTimeInSeconds) {
      _timer?.cancel();
      _calculateInitialState();
    }
  }

  void _calculateInitialState() {
    final endTime = widget.plantedAt.add(Duration(seconds: widget.growTimeInSeconds));
    final now = DateTime.now();

    setState(() {
      _remainingTime = endTime.difference(now);
      _isReadyToHarvest = _remainingTime <= Duration.zero;

      if (_isReadyToHarvest) {
        _remainingTime = Duration.zero;
        widget.onHarvest(); // Notifica immediatamente se già pronta
      } else {
        _startTimer();
      }
    });
  }

  void _startTimer() {
    final endTime = widget.plantedAt.add(Duration(seconds: widget.growTimeInSeconds));

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final remaining = endTime.difference(now);

      setState(() {
        _remainingTime = remaining;

        if (remaining <= Duration.zero) {
          _remainingTime = Duration.zero;
          _isReadyToHarvest = true;
          timer.cancel();
          widget.onHarvest(); // Notifica il componente padre
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return _isReadyToHarvest
        ? ElevatedButton(
      onPressed: widget.onHarvest,
      child: Text("Raccogli!"),
    )
        : Text(
      'Tempo rimanente: ${_formatDuration(_remainingTime)}',
      style: TextStyle(fontSize: 16),
    );
  }
}