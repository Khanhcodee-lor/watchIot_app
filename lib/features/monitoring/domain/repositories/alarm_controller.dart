abstract interface class AlarmController {
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}
