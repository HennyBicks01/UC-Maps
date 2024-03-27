class PolygonRoomData {
  final List<List<int>> polygon;
  Map<String, dynamic> roomInfo;  // Changed to Map<String, dynamic>

  PolygonRoomData({required this.polygon, required this.roomInfo});

  factory PolygonRoomData.fromJson(Map<String, dynamic> json) {
    // Assuming json['roomInfo'] can correctly be interpreted as Map<String, dynamic>
    // This will work as long as the json map only contains basic JSON types (numbers, strings, booleans, null, lists, and maps).
    var roomInfoDynamic = Map<String, dynamic>.from(json['roomInfo'] as Map);

    return PolygonRoomData(
      polygon: List<List<int>>.from(json['polygon'].map((e) => List<int>.from(e as List))),
      roomInfo: roomInfoDynamic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'polygon': polygon,
      'roomInfo': roomInfo,
    };
  }
}

