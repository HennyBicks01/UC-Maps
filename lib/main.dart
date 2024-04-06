import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:find_flush/part2new.dart';
import 'package:find_flush/png.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_polywidget/flutter_map_polywidget.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'building.dart';
import 'geo.dart';
import 'json.dart';
import 'part1.dart';
import 'part2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UC Maps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Map Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MapController mapController = MapController();
  double zoom = 17.0;
  TextEditingController searchController = TextEditingController();
  List<PolygonData> filteredPolygons = getPolygons();
  List<Marker> markers = []; // Added for user location marker
  String? selectedBuildingName;
  List<String>? selectedBuildingJsonPaths;
  String? selectedImagePath;
  late Size selectedImageSize;
  List<LatLng> cornerPositions = [];
  int currentIndex = 0;
  List<String> imagePaths = [];
  List<String> jsonPaths = [];
  Set<int> processedImagesIndices = {};
  List<LatLng> currentImageCorners = [];
  List<Point> currentScreenCorners = [];
  List<PolyWidget> polyWidgets = [];
  ImageProvider imageProvider = const AssetImage('');
  Map<String, ImageData> imageCorners = {};
  String imageName = "";
  double currentCameraRotation = 0;
  late LatLng currentCentroid;
  double boxSize = 0.0;
  final dio = Dio();
  bool isGeoDataWidgetVisible = false;


  @override
  void initState() {
    super.initState();
    _determinePosition();
    searchController.addListener(_filterBuildings);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Size screenSize = MediaQuery.of(context).size;
      final double minDimension = min(screenSize.width, screenSize.height);
      setState(() {
        boxSize = minDimension * 0.95; // Set to 95% of the minimum dimension
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng userLocation = LatLng(position.latitude, position.longitude);
    setState(() {
      markers.add(
        Marker(
          width: 80.0,  // Specify the marker's width
          height: 80.0, // Specify the marker's height
          point: userLocation, // Specify the marker's geographic location
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40), // Directly use the Widget
        ),

      );
    });

  }

  void _filterBuildings() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredPolygons = getPolygons();
      });
    } else {
      setState(() {
        filteredPolygons = getPolygons().where((polygonData) =>
            polygonData.name.toLowerCase().contains(query)).toList();
      });
    }
  }

  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1; // Initialize j here
    bool isInside = false;
    for (i = 0; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  LatLng calculateCentroid(List<LatLng> points) {
    double latitudeSum = 0.0;
    double longitudeSum = 0.0;
    for (var point in points) {
      latitudeSum += point.latitude;
      longitudeSum += point.longitude;
    }
    return LatLng(latitudeSum / points.length, longitudeSum / points.length);
  }

  List<Polygon> createPolygonsForMap() {
    List<Polygon> updatedPolygons = [];

    for (var polygonData in getPolygons()) {
      // Check if the polygon's name is present in the list of filtered polygon names
      bool isFiltered = filteredPolygons.any((p) => p.name == polygonData.name);

      // Determine the color based on whether the polygon is filtered
      Color fillColor = isFiltered ? polygonData.polygon.color : Colors.grey.withOpacity(0.05);
      Color borderColor = isFiltered ? polygonData.polygon.borderColor : Colors.grey;

      // Create a new Polygon instance with the updated color
      Polygon updatedPolygon = Polygon(
        points: polygonData.polygon.points,
        color: fillColor,
        borderColor: borderColor,
        borderStrokeWidth: polygonData.polygon.borderStrokeWidth,
        isFilled: polygonData.polygon.isFilled,
      );

      updatedPolygons.add(updatedPolygon);
    }

    return updatedPolygons;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    var dLat = _degreesToRadians(point2.latitude - point1.latitude);
    var dLon = _degreesToRadians(point2.longitude - point1.longitude);
    var a = sin(dLat/2) * sin(dLat/2) +
        cos(_degreesToRadians(point1.latitude)) * cos(_degreesToRadians(point2.latitude)) *
            sin(dLon/2) * sin(dLon/2);
    var c = 2 * atan2(sqrt(a), sqrt(1-a));
    var distance = 6371000 * c; // Earth radius in meters
    return distance;
  }

  double _degreesToRadians(degrees) {
    return degrees * pi / 180;
  }

  double calculateMinDistanceBasedOnZoom(double zoom) {
    // Example logic: adjust these numbers based on your needs
    if (zoom >= 18) return 20;
    if (zoom >= 17.5) return 40;
    if (zoom >= 17) return 70;
    if (zoom >= 16.5) return 80;
    if (zoom >= 16) return 150;
    if (zoom >= 15.5) return 300;
    if (zoom >= 15) return 600;
    if (zoom >= 14.5) return 1200;
    return 100000; // Default distance for lower zoom levels
  }

  double calculatePolygonArea(List<LatLng> points) {
    double area = 0.0;
    if (points.length < 3) return 0.0; // Not a polygon

    int j = points.length - 1;
    for (int i = 0; i < points.length; i++) {
      area += (points[j].longitude + points[i].longitude) * (points[j].latitude - points[i].latitude);
      j = i;  // j is previous vertex to i
    }
    return area.abs() / 2;
  }


  List<Marker> createMarkersForPolygons(List<PolygonData> polygons, double zoom) {
    if(zoom <= 15){
      return [];
    }
    double minDistance = calculateMinDistanceBasedOnZoom(zoom);
    // Sort polygons by area, largest to smallest
    polygons.sort((a, b) => calculatePolygonArea(b.polygon.points).compareTo(calculatePolygonArea(a.polygon.points)));
    List<LatLng> visibleCentroids = [];
    List<Marker> markers = [];

    for (var polygonData in polygons) {
      LatLng centroid = calculateCentroid(polygonData.polygon.points);
      bool isVisible = visibleCentroids.every((pt) => calculateDistance(pt, centroid) >= minDistance);

      if (isVisible) {
        visibleCentroids.add(centroid);
        markers.add(
          Marker(
            point: centroid,
            width: 110, // Placeholder width, adjust as necessary
            child: Container(
              padding: const EdgeInsets.all(5),
              child: Text(
                polygonData.name,
                style: TextStyle(
                  color: Colors.grey[350], // White text color
                  //fontWeight: FontWeight.bold, // Makes the text bold
                  fontStyle: FontStyle.italic, // Makes the text italicized
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  void _selectPolygon(PolygonData polygonData) {
    // Example action: Navigate to a detail page for the polygon
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Blueprint(buildingName: polygonData.name),
    ));

    // Optionally, center the map on the polygon's centroid
    LatLng centroid = calculateCentroid(polygonData.polygon.points);
    mapController.move(centroid, 20);
  }

  Future<void> _centerMapOnUserIfClose() async {
    const initialCenter = LatLng(39.1317, -84.5167);
    const double distanceLimit = 1609.34; // 1 mile in meters

    Position position = await Geolocator.getCurrentPosition();
    double distance = Geolocator.distanceBetween(
      initialCenter.latitude,
      initialCenter.longitude,
      position.latitude,
      position.longitude,
    );

    if (distance <= distanceLimit) {
      // Assuming mapController.move is correctly implemented for moving the map
      mapController.move(LatLng(position.latitude, position.longitude), 19.0);
    } else {
      // Showing a snack bar if the user is not close enough
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You are not close enough to UC for directions.",
            style: TextStyle(color: Colors.white), // White text color
          ),
          backgroundColor: Colors.red, // Red background color
          behavior: SnackBarBehavior.fixed, // Makes the snack bar floating
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8), // Top left corner radius
              topRight: Radius.circular(8), // Top right corner radius
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Assuming this function gets the necessary data to create a PolyWidget for the image overlay
  Future<List<PolyWidget>> createPolyWidgetsFromImageData(List<String> assetPaths) async {
    List<PolyWidget> polyWidgets = [];

    if (assetPaths.isEmpty) {
      return polyWidgets; // Return an empty list if no paths are provided
    }

    // Load and decode the JSON data for the last assetPath, assuming it contains your image overlay data
    final String jsonStr = await rootBundle.loadString(assetPaths.last);
    final dynamic jsonData = json.decode(jsonStr);

    // Assuming jsonData contains the necessary points and imagePath for the image overlay
    List<LatLng> points = (jsonData['polygon'] as List).map<LatLng>((point) {
      double lat = (point[0] is int) ? (point[0] as int).toDouble() : point[0];
      double lng = (point[1] is int) ? (point[1] as int).toDouble() : point[1];
      return LatLng(lat, lng);
    }).toList();

    // Example of creating a PolyWidget, adjust according to your actual data structure
    PolyWidget polyWidget = PolyWidget.threePoints(
      pointA: points[0], // Adjust these points as per your structure
      pointB: points[1],
      approxPointC: points[2],
      noRotation: true,
      child: Opacity(
        opacity: 0.2,
        child: Image.asset('your_image_path_here'), // Replace with your actual image path
      ),
    );

    polyWidgets.add(polyWidget);

    return polyWidgets;
  }


  Future<List<PolygonData>> loadRoomDataFromJson(List<String> assetPaths) async {
    if (assetPaths.isEmpty) {
      return []; // Return an empty list if no paths are provided
    }
    // Load and decode the JSON data
    final String jsonStr = await rootBundle.loadString(assetPaths.first);
    final List<dynamic> jsonData = json.decode(jsonStr);

    List<PolygonData> rooms = []; // This will hold both PolygonData and the PolyWidget or its data

    for (int i = 0; i < jsonData.length; i++) {
      final item = jsonData[i];
      List<LatLng> points = (item['polygon'] as List).map<LatLng>((point) {
        double lat = (point[0] is int) ? (point[0] as int).toDouble() : point[0];
        double lng = (point[1] is int) ? (point[1] as int).toDouble() : point[1];
        return LatLng(lat, lng);
      }).toList();

      if (i < jsonData.length - 1) {
        // For all but the last polygon, create PolygonData objects
        rooms.add(PolygonData(
          name: "", // Assuming you have a mechanism to set names
          polygon: Polygon(
            points: points,
            color: const Color.fromRGBO(224, 1, 34, .4),
            borderColor: const Color.fromRGBO(184, 1, 28, .4),
            borderStrokeWidth: 2.0,
            isFilled: true,
          ),
        ));
      }
    }
    return rooms;
  }

  List<int> extractFloorNumbers(List<String> filePaths) {
    final floorNumbers = filePaths.map((path) {
      // This regex assumes the floor number always precedes '.json' and is preceded by a '-'
      final match = RegExp(r'-([0-9]+)\.json$').firstMatch(path);
      // If a match is found, parse the floor number; otherwise, return 0
      return match != null ? int.parse(match.group(1)!) : 0;
    }).toList();

    // Sort the floor numbers and return them
    floorNumbers.sort();
    return floorNumbers;
  }

  @override
  Widget build(BuildContext context) {
    List<int> floorNumbers = selectedBuildingJsonPaths != null ? extractFloorNumbers(selectedBuildingJsonPaths!) : [];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              scrollWheelVelocity: .00025,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && zoom != position.zoom) {
                  //print("Zoom level changed to: ${position.zoom}");
                  setState(() {
                    zoom = position.zoom!;
                    markers = createMarkersForPolygons(filteredPolygons, zoom);
                    // Debugging: Print out number of visible markers
                    //print("Number of visible markers: ${markers.length}");
                  });
                }
              },
              initialCenter: const LatLng(39.1317, -84.5167), // Example coordinates
              initialZoom: zoom,
              onTap: (tapPosition, point) async {
                for (var polyData in getPolygons()) {
                  if (isPointInPolygon(point, polyData.polygon.points)) {
                    String buildingName = polyData.name;
                    var operationMode = 3;
                    if (operationMode == 1) {
                      // PART 1 ***************************************
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Blueprint(
                            buildingName: buildingName
                        ),
                      ));
                    } else if (operationMode == 2) {
                      // PART 2 *************************************
                      setState(() {
                        selectedBuildingName = buildingName;
                        isGeoDataWidgetVisible = !isGeoDataWidgetVisible;
                      });
                    } else if (operationMode == 3) {
                      // PART 3 ************************************
                      List<String> jsonPaths = getbuildingGeoPathFilePaths(buildingName);
                      setState(() {
                        selectedBuildingName = buildingName;
                        selectedBuildingJsonPaths = jsonPaths;
                        loadRoomDataFromJson([jsonPaths.first]).then((loadedRooms) {
                          filteredPolygons = loadedRooms;
                        });
                      });
                    }
                    break; // Exit the loop once the correct polygon is found and handled
                  }
                }
              },
            ),
            children: [

              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd', 'e'],  // Enable retina mode based on device density
                userAgentPackageName: 'com.example.app',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              MarkerLayer(markers: markers),
              Opacity(
                opacity: 0.15,
                child: Container(
                  color: const Color.fromRGBO(230, 241, 255, 1), // Blue overlay
                  width: double.infinity,  // Ensure it covers the entire screen width
                  height: double.infinity, // Ensure it covers the entire screen height
                ),
              ),
              PolygonLayer(
                polygons: createPolygonsForMap() + filteredPolygons.map((roomData) => roomData.polygon).toList(),
              ),
              PolyWidgetLayer(
                polyWidgets: polyWidgets, // Dynamically create PolyWidgets for processed images
              ),
              MarkerLayer(
                 //getPolygons(),
                markers: [
                  ...createMarkersForPolygons(filteredPolygons, zoom),
                ]
              ),
            ],
          ),
          Stack(
            children: [
              if (isGeoDataWidgetVisible)
                  TranslucentPointer(
                    translucent: true,
                    child: GeoDataWidget(
                      mapController: mapController,
                      buildingName: selectedBuildingName!,
                      polyWidgets: polyWidgets,
                    ),
                  ),
              ],
          ),

          if (selectedBuildingJsonPaths != null) // Only render buttons if a building is selected
            Positioned(
              top: MediaQuery.of(context).padding.top + 80, // Start lower than the search bar
              right: 10,
              child: Column(
                children: floorNumbers.map((floor) => Container(
                  margin: const EdgeInsets.only(bottom: 15), // Space out the buttons
                  child: ElevatedButton(
                    onPressed: () async {
                      List<PolygonData> loadedRooms = await loadRoomDataFromJson([selectedBuildingJsonPaths![floor - 1]]);
                      setState(() {
                        filteredPolygons = loadedRooms;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                      backgroundColor: const Color(0xFF424549)// Text color
                    ),
                    child: Text('$floor'),
                  ),
                )).toList(),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFFa7a5aa)),
              onPressed: () {
                // Handle settings action
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 60,
            right: MediaQuery.of(context).size.width * .85,
            child: Material(
              borderRadius: BorderRadius.circular(30), // Set borderRadius here
              elevation: 2, // Optional: adds a slight shadow
              child: TextField(
                style: TextStyle(color: Colors.grey[400]),  // Light gray text color for input
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey[400]), // Light gray hint text
                  filled: true,
                  fillColor: const Color(0xFF424549),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
                onSubmitted: (value) {
                  // Check if there's exactly one polygon in the filtered list
                  if (filteredPolygons.length == 1) {
                    // Perform the action associated with selecting the polygon
                    // For example, navigating to a new page with the polygon's details
                    PolygonData selectedPolygon = filteredPolygons.first;
                    _selectPolygon(selectedPolygon);
                  }
                },
              ),
            ),
          ),


          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFFa7a5aa)),
              onPressed: () {
                // Handle menu action
              },
            ),
          ),

          Positioned(
            left: 20,
            bottom: 20,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.transparent, // Makes the splash effect invisible
              ),
              onPressed: _centerMapOnUserIfClose,
              child: const Text(
                '◎', // Your text-based icon
                style: TextStyle(
                  color: Colors.red, // Text color
                  fontSize: 30, // Icon size, adjust as needed
                  shadows: [
                    Shadow(
                      offset: Offset(3.0, 3.0), // Shadow position
                      blurRadius: 5.0, // Shadow blur radius
                      color: Color.fromARGB(255, 0, 0, 0), // Shadow color
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

}


