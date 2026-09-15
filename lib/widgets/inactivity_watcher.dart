import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningBefore;
  final VoidCallback onTimeout;
  final VoidCallback? onWarning;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    this.warningBefore = const Duration(seconds: 30),
    required this.onTimeout,
    this.onWarning,
    required this.child,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _timer?.cancel();
    _warningTimer?.cancel();

    final warnAt = widget.timeout - widget.warningBefore;
    if (warnAt > Duration.zero && widget.onWarning != null) {
      _warningTimer = Timer(warnAt, () => widget.onWarning?.call());
    }
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
