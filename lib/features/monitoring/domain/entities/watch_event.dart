class WatchEvent {
  const WatchEvent({
    required this.id,
    required this.status,
    required this.message,
    this.occurredAt,
    this.probability,
  });

  final String id;
  final String status;
  final String message;
  final DateTime? occurredAt;
  final double? probability;
}
