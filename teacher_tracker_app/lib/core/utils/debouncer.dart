import 'dart:async';

/// Delays invoking an action until [duration] has passed without a new call.
/// Call `dispose()` when the owning widget is disposed to cancel any pending
/// call.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 350)});

  final Duration duration;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() => _timer?.cancel();
}
