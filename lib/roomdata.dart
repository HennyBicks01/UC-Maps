class PolygonRoomData {
  final List<List<int>> polygon;
  Map<String, String> roomInfo; // Now mutable, so it can be updated

  PolygonRoomData({required this.polygon, required this.roomInfo});

  factory PolygonRoomData.fromJson(Map<String, dynamic> json) {
    return PolygonRoomData(
      polygon: List<List<int>>.from(json['polygon'].map((e) => List<int>.from(e))),
      roomInfo: Map<String, String>.from(json['roomInfo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polygon': polygon,
      'roomInfo': roomInfo,
    };
  }
}
