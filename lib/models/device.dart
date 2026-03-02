/// Represents an Android device connected via ADB.
class Device {
  const Device({
    required this.id,
    required this.state,
    this.model,
  });

  final String id;
  final String state;
  final String? model;

  String get displayName => model ?? id;
  bool get isOnline => state == 'device';
}
