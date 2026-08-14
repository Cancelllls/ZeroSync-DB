import 'dart:math' as math;

/// Hybrid Logical Clock (HLC) for CRDT multi-device conflict resolution.
class Hlc implements Comparable<Hlc> {
  final int millis;
  final int counter;
  final String nodeId;

  const Hlc(this.millis, this.counter, this.nodeId);

  factory Hlc.now(String nodeId) {
    return Hlc(DateTime.now().millisecondsSinceEpoch, 0, nodeId);
  }

  factory Hlc.parse(String formatted) {
    final parts = formatted.split(':');
    if (parts.length != 3) {
      throw FormatException('Invalid HLC string format: $formatted');
    }
    return Hlc(int.parse(parts[0]), int.parse(parts[1]), parts[2]);
  }

  Hlc increment(int wallTimeMillis) {
    if (wallTimeMillis > millis) {
      return Hlc(wallTimeMillis, 0, nodeId);
    } else {
      return Hlc(millis, counter + 1, nodeId);
    }
  }

  Hlc receive(Hlc remote, int wallTimeMillis) {
    final maxMillis = math.max(math.max(millis, remote.millis), wallTimeMillis);
    if (maxMillis == millis && maxMillis == remote.millis) {
      return Hlc(maxMillis, math.max(counter, remote.counter) + 1, nodeId);
    } else if (maxMillis == millis) {
      return Hlc(maxMillis, counter + 1, nodeId);
    } else if (maxMillis == remote.millis) {
      return Hlc(maxMillis, remote.counter + 1, nodeId);
    } else {
      return Hlc(maxMillis, 0, nodeId);
    }
  }

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) return millis.compareTo(other.millis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return nodeId.compareTo(other.nodeId);
  }

  @override
  String toString() => '$millis:${counter.toString().padLeft(4, '0')}:$nodeId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hlc &&
          millis == other.millis &&
          counter == other.counter &&
          nodeId == other.nodeId;

  @override
  int get hashCode => millis.hashCode ^ counter.hashCode ^ nodeId.hashCode;
}
