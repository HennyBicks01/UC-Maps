import 'dart:async';
import 'dart:convert';
//import 'dart:html';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:UCMaps/part2new.dart';
import 'package:UCMaps/png.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_polywidget/flutter_map_polywidget.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'building.dart';
import 'geo.dart';
import 'part1.dart';
import 'config.dart'; // Adjust the import path according to where you placed your config file


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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final MapController mapController = MapController();
  double zoom = 17.0;
  TextEditingController searchController = TextEditingController();
  List<PolygonData> filteredPolygons = getPolygons();
  List<Marker> markers = []; // Added for user location marker
  String? selectedBuildingName;
  List<String>? selectedBuildingJsonPaths;
  List<String>? selectedBuildingImagePaths;
  String? selectedImagePath;
  late Size selectedImageSize;
  List<LatLng> cornerPositions = [];
  int currentIndex = 0;
  List<String> imagePaths = [];
  List<String> jsonPaths = [];
  List<PolyWidget> polyWidgets = [];
  ImageProvider imageProvider = const AssetImage('');
  Map<String, ImageData> imageCorners = {};
  String imageName = "";
  double boxSize = 0.0;
  bool isGeoDataWidgetVisible = false;
  OverlayEntry? _roomInfoOverlay;
  AnimationController? _animationController;
  Animation<Offset>? _slideAnimation;
  List<Polyline> polylines = [];
  bool navigationSuccess = false; // Indicates whether navigation was successful
  LatLng startPosition = const LatLng(0, 0);
  bool showDirections = false;
  List<Map<String, dynamic>> directionsList = [];
  int currentStepIndex = 0;
  String currentInstruction = "";
  double ETA = 0;
  StreamSubscription<Position>? positionStreamSubscription;
  List<String> selectedRooms = [];
  Dio dio = Dio();
  List<PolygonData> coloredPolygons = [];
  bool showFilterChips = false;

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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Define the slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from below the screen
      end: Offset.zero, // End at its final position
    ).animate(_animationController!);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Handle completion, if needed
      } else if (status == AnimationStatus.dismissed) {
        // Handle dismissal, if needed
        _roomInfoOverlay?.remove();
        _roomInfoOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _roomInfoOverlay?.remove();
    _animationController?.dispose();
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
          child: const Icon(Icons.location_pin, color: Colors.white, size: 40), // Directly use the Widget
        ),

      );
    });

  }

  void _filterBuildings() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {

        if(selectedBuildingName != null){
          selectAndLoadBuilding(selectedBuildingName!);
        } else{
          filteredPolygons = getPolygons();
        }
      });
    } else {
      setState(() {
        if (selectedBuildingName != null) {

        } else {
          // No building is selected; filter among all buildings
          filteredPolygons = getPolygons().where((polygonData) =>
              polygonData.name.toLowerCase().contains(query)).toList();
        }
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

    for (var polygonData in coloredPolygons) {
      // Check if the polygon's name is present in the list of filtered polygon names
      bool isFiltered = coloredPolygons.any((p) => p.name == polygonData.name || p.description == polygonData.description);

      // Determine the color based on whether the polygon is filtered
      Color fillColor = isFiltered ? polygonData.polygon.color : Colors.grey.withOpacity(1);
      Color borderColor = isFiltered ? polygonData.polygon.borderColor : Colors.grey.withOpacity(.1);

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

  List<PolyWidget> loadImageFromJson(List<LatLng> points, String imagePath) {
    List<PolyWidget> widgets = [];

        // Use imageData.imagePath for each PolyWidget
        widgets.add(PolyWidget.threePoints(
          pointA: points[0],
          pointB: points[1],
          approxPointC: points[2],
          noRotation: true,
          child: Opacity(
            opacity: .5,
            child: Image.asset(imagePath), // Use the specific image path
          ),
        ));
    return widgets;
  }

  Future<List<PolygonData>> loadRoomDataFromJson(List<String> assetPaths, int index) async {
    List<PolygonData> rooms = [];
    if (assetPaths.isEmpty) {
      return rooms;
    }
    // Load and decode the JSON data
    final String jsonStr = await rootBundle.loadString(assetPaths.first);
    final List<dynamic> jsonData = json.decode(jsonStr);

    for (int i = 0; i < jsonData.length; i++) {
      final item = jsonData[i];
      List<LatLng> points = (item['polygon'] as List).map<LatLng>((point) {
        double lat = point[0];
        double lng = point[1];
        return LatLng(lat, lng);
      }).toList();

      // Extract roomInfo and use its properties
      var roomInfo = item['roomInfo'];
      String name = "${roomInfo['Room Code']}"; // Combine floor and room codes for a unique name, adjust as needed
      String description = roomInfo['Description'];
      String departmentName = roomInfo['Department Name'];
      List<String> aliases = []; // Assuming no aliases provided in the given structure; adjust if available


      if(i == 0) {
        polyWidgets =  loadImageFromJson(points, imagePaths[index]);
        print("loading image: ${imagePaths[index]}");
      }
      else if (i != jsonData.length ) {
        PolygonData polygonData = PolygonData(
          name: "", // Placeholder for name, adjust as per your data
          description: "Room: $name $description",
          departmentName: "Department: $departmentName",
          aliases: aliases,
          polygon: Polygon(
            points: points,
            color: const Color.fromRGBO(224, 1, 34, .6),
            borderColor: const Color.fromRGBO(184, 1, 28, .6),
            borderStrokeWidth: 4.0,
            isFilled: true,
          ),
        );
        rooms.add(polygonData);
        // If it's the last polygon, send its points to loadImageFromJson
      }

    }

    return rooms;
  }

  void handleFilteredPolygonTap(PolygonData polyData) {
    showRoomInfoPopup(polyData);
    setState(() {
      filterPolygonsAndUpdateUI(polyData.description);
      selectedRooms.clear();
    });
  }

  void showRoomInfoPopup(PolygonData polyData) {
    if (_roomInfoOverlay != null) {
      // Temporarily adjust the duration for the reverse animation to be twice as quick
      _animationController?.duration = Duration(milliseconds: (_animationController!.duration!.inMilliseconds / 2).round());
      _animationController?.reverse().then((value) {
        _roomInfoOverlay?.remove();
        _roomInfoOverlay = null;

        // Reset the duration after the reverse animation completes
        _animationController?.duration = Duration(milliseconds: (_animationController!.duration!.inMilliseconds * 2).round());

        // Show the new popup
        _showNewPopup(polyData);
      });
    } else {
      // If no overlay exists, show the new popup immediately
      _showNewPopup(polyData);
    }
  }

  Future<LatLng> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  void drawRouteOnMap(List<LatLng> routePoints) {
    final routePolyline = Polyline(
      points: routePoints,
      color: Colors.red,
      strokeWidth: 4.0,
    );

    setState(() {
      polylines.add(routePolyline);
    });
  }

  void checkProximityToNextStep(Position currentPosition) {
    if (currentStepIndex < directionsList.length) {
      LatLng stepEndPosition = directionsList[currentStepIndex]['LatLng'];

      double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        stepEndPosition.latitude,
        stepEndPosition.longitude,
      );

      // If within a certain distance threshold, consider the step completed
      if (distance < 30) { // 30 meters, adjust as needed
        currentStepIndex++;
        displayNextDirection();
      }
    }
  }

  void displayNextDirection() {
    if (currentStepIndex < directionsList.length) {
      String nextDirection = directionsList[currentStepIndex]['instruction'];
      // Display nextDirection in your app's UI
      // This could involve setting a state variable and using setState to trigger a rebuild
      setState(() {
        currentInstruction = nextDirection; // Assuming you have a state variable to hold the current instruction
      });
    } else {
      // Reached the destination
      // Handle navigation completion (e.g., stop location updates, notify the user)
    }
  }

  void startPositionUpdates() {
    positionStreamSubscription = Geolocator.getPositionStream().listen(
          (Position position) {
        updateCameraPosition(position);
        checkProximityToNextStep(position);
      },
    );
  }

  void stopPositionUpdates() {
    positionStreamSubscription?.cancel();
    positionStreamSubscription = null; // Clear the subscription
  }

  void updateCameraPosition(Position position) {
    mapController.move(LatLng(position.latitude, position.longitude), mapController.camera.zoom);
  }

  Future<void> fetchDirections(LatLng start, LatLng destination) async {
    const String requestUrl =
        'https://api.openrouteservice.org/v2/directions/foot-hiking';

    directionsList = []; // Initialize an empty list for the directions
    try {
      final response = await post(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': Config.apiKey,
        },
        body: jsonEncode({
          'coordinates': [
            [start.longitude, start.latitude],
            [destination.longitude, destination.latitude]
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['routes'] != null && responseData['routes'].isNotEmpty) {
          final String encodedPolyline = responseData['routes'][0]['geometry']; // Get the encoded polyline string

          // Decode the polyline
          final polylinePoints = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);
          List<LatLng> routePoints = decodedPoints.map((point) => LatLng(point.latitude, point.longitude)).toList();

          // Extracting total duration and converting it to a more readable format
          double ETAsecs = responseData['routes'][0]['summary']['duration'];
          ETA = double.parse((ETAsecs / 60).toStringAsFixed(1));

          // Assuming steps are in the segments[0].steps array
          if (responseData['routes'][0]['segments'] != null && responseData['routes'][0]['segments'].isNotEmpty) {
            List<dynamic> steps = responseData['routes'][0]['segments'][0]['steps'];
            for (var step in steps) {
              // Extract the instruction
              String instruction = step['instruction'];

              // Get the end waypoint index for this step
              int endWayPointIndex = step['way_points'][1];

              // Use the endWayPointIndex to find the corresponding LatLng in the decoded polyline
              if (endWayPointIndex < routePoints.length) {
                LatLng stepEndLatLng = routePoints[endWayPointIndex];

                // Add both the instruction and the LatLng to the directionsList
                directionsList.add({
                  "instruction": instruction,
                  "LatLng": stepEndLatLng
                });
              }
            }

            // Now directionsList contains instructions paired with their ending LatLng
            print("Directions with LatLng: $directionsList");

            // Display the route on the map
            drawRouteOnMap(routePoints);
          }

          // Now you have a list of directions in directionsList
          // You might want to do something with it, like displaying it in the UI
          print("Directions: $directionsList");

          // Here you would typically pass routePoints to a method to display them on the map
          drawRouteOnMap(routePoints);
        } else {
          print("No routes found in response.");
        }
      } else {
        print("Failed to load directions: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception caught: $e");
    }
  }

  void _showNewPopup2(PolygonData polyData) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents the dialog from closing when tapping outside
      builder: (BuildContext context) {
        return Material(
          type: MaterialType.transparency, // Ensures the dialog background is transparent
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: min(MediaQuery.of(context).size.width * 0.8, 450),
              margin: EdgeInsets.only(bottom: 0, right: MediaQuery.of(context).size.width * 0.05),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF424549),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 140.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start (left side) of the column
                      children: [
                        Text("$selectedBuildingName", style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.red, decoration: TextDecoration.none)),
                        Text(polyData.description, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey , decoration: TextDecoration.none)),
                        Text(polyData.departmentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, color: Colors.grey , decoration: TextDecoration.none)),
                        const SizedBox(height: 10), // Spacing between text and buttons
                        // Dynamic direction content updated based on currentStepIndex
                        if (currentStepIndex < directionsList.length)
                          Text(
                            " ${directionsList[currentStepIndex]['instruction']}",
                            style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
                            textAlign: TextAlign.start,
                          )
                        else const
                        Text(
                          "You have arrived at your destination.",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.none),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 10), // Adds spacing between the ETA text and the button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text("Stop Navigation", style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            // Add logic to stop navigation here
                            setState(() {
                              navigationSuccess = false; // Assumes navigationSuccess controls the navigation state
                              showDirections = false; // Hide directions
                              // Optionally, reset other states related to navigation as needed
                            });
                            Navigator.pop(context); // Close the dialog
                            _showNewPopup(polyData); // Reopens the modal which will now include directions due to showDirections being true
                            stopPositionUpdates(); // Stop receiving position updates
                            centerAndZoomInOnPolygon((getPolygons().where((element) => element.name == selectedBuildingName)).first.polygon.boundingBox);
                            polylines = [];
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue, // Text and icon color
                            elevation: 5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

                          ),
                        ),
                      ],
                    ),
                  ),
                  // All your existing content here, exactly as in your previous overlay
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  void _showNewPopup(PolygonData polyData) {
    if (polyData.description.isEmpty) {
      clearBuildingSelection();
      return; // Exit the method without showing the popup
    }
    _animationController?.reset();
    _animationController?.forward();
    _roomInfoOverlay = OverlayEntry(
      builder: (context) {
        return SlideTransition(
          position: _slideAnimation!,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: min(MediaQuery.of(context).size.width * 0.8, 450),
              margin: EdgeInsets.only(bottom: 0, right: MediaQuery.of(context).size.width * 0.05),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF424549),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("$selectedBuildingName", style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.red, decoration: TextDecoration.none)),
                  Text(polyData.description, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey , decoration: TextDecoration.none)),
                  Text(polyData.departmentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, color: Colors.grey , decoration: TextDecoration.none)),
                  const SizedBox(height: 10), // Spacing between text and buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start, // To evenly space out the buttons
                    children: <Widget>[
                      if (!navigationSuccess) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.navigation, color: Colors.white),
                          label: const Text("Navigate", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            polylines = [];
                            startPosition = /*const LatLng(39.13334, -84.517); */ await getCurrentLocation();
                            LatLng destinationPosition = calculateCentroid((getPolygons().where((element) => element.name == selectedBuildingName)).first.polygon.points);

                            await fetchDirections(startPosition, destinationPosition);
                            // After fetching directions, if you wish to toggle the success state:
                            updateNavigationSuccess(true, polyData);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Background color
                            elevation: 5, // For shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Adds spacing between the ETA text and the button
                        /*ElevatedButton.icon(
                          icon: const Icon(Icons.map, color: Colors.white),
                          label: const Text("Between", style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            // Your navigation between logic here
                            print("Navigate Between clicked");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Background color
                            elevation: 5, // For shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),*/
                      ] else if (navigationSuccess && !showDirections) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 140.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Center column content horizontally
                            children: [
                              Text(
                                " ETA: ${ETA} mins", // Assuming `ETA` is correctly calculated and stored beforehand
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic,fontSize: 20, decoration: TextDecoration.none),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(height: 10), // Adds spacing between the ETA text and the button
                              ElevatedButton.icon(
                                icon: const Icon(Icons.directions_walk, color: Colors.white),
                                label: const Text("Begin Navigation", style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  setState(() {
                                    showDirections = true; // Indicates that directions should now be shown
                                  });

                                  closeCurrentModal(); // Closes the current modal
                                  _showNewPopup2(polyData); // Reopens the modal which will now include directions due to showDirections being true
                                  startPositionUpdates(); // Start updating the position as the user moves
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, // Background color for the button
                                  elevation: 5, // Shadow depth for the button
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners for the button
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]



                    ],
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_roomInfoOverlay!);
  }

  void closeCurrentModal() {
    _roomInfoOverlay?.remove();
    setState(() {
      _roomInfoOverlay = null; // Ensure we clear the reference to the removed overlay
    });
  }

  void updateNavigationSuccess(bool success, PolygonData polyData) {
    _roomInfoOverlay?.remove(); // Remove the existing overlay
    mapController.fitCamera(CameraFit.coordinates(coordinates: polylines[0].points, maxZoom: 21, minZoom: 12, padding: const EdgeInsets.fromLTRB(30,100,80,50)));
    setState(() {
      navigationSuccess = success; // Update the state that the overlay content depends on
    });
    _showNewPopup(polyData); // Recreate and insert the overlay with the updated content
  }

  void clearBuildingSelection() {
    setState(() {
      selectedBuildingName = null; // Clear the selected building name
      selectedBuildingJsonPaths = null; // Clear associated JSON paths
      selectedBuildingImagePaths = null; // Clear associated image paths
      selectedImagePath = null;
      filteredPolygons = getPolygons();
      polyWidgets = [];// Clear filtered polygons or reset to default
      polylines = [];
      navigationSuccess = false;
    });
  }

  void selectBuilding(String buildingName) {
    setState(() {
      selectedBuildingName = buildingName;
    });
  }

  void animateMapToBound(MapController mapController, LatLngBounds bounds, {int duration = 500}) {
    double targetZoom = mapController.camera.zoom; // Adjust padding as needed
    targetZoom = targetZoom.clamp(0.0, 18.0); // Adjust based on your map's min/max zoom levels

    final startZoom = mapController.camera.zoom;
    final zoomDiff = targetZoom - startZoom;
    final startCenter = mapController.camera.center;
    final targetCenter = bounds.center;

    int steps = (duration / 50).round(); // Number of steps based on duration and timer interval
    double stepZoomDelta = zoomDiff / steps;
    double stepLatDelta = (targetCenter.latitude - startCenter.latitude) / steps;
    double stepLngDelta = (targetCenter.longitude - startCenter.longitude) / steps;

    int currentStep = 0;

    Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      currentStep++;
      if (currentStep >= steps) {
        timer.cancel();
        mapController.move(targetCenter, targetZoom);
      } else {
        double nextZoom = startZoom + (stepZoomDelta * currentStep);
        double nextLat = startCenter.latitude + (stepLatDelta * currentStep);
        double nextLng = startCenter.longitude + (stepLngDelta * currentStep);
        mapController.move(LatLng(nextLat, nextLng), nextZoom);
      }
    });
  }

  void centerAndZoomInOnPolygon(LatLngBounds polygonPoints) {
    mapController.fitCamera(CameraFit.bounds(bounds: polygonPoints, maxZoom: 21, minZoom: 12, padding: const EdgeInsets.fromLTRB(20,100,20,50)));
    print(mapController.camera.zoom);
    print(mapController.camera.center);
  }

  void selectAndLoadBuilding(String buildingName) {
    // Load JSON path files for the building
    jsonPaths = getbuildingGeoPathFilePaths(buildingName);
    imagePaths = getbuildingImagePathFilePaths(buildingName);
    centerAndZoomInOnPolygon((getPolygons().where((element) => element.name == buildingName)).first.polygon.boundingBox);
    setState(() {
      selectedBuildingName = buildingName;
      selectedBuildingJsonPaths = jsonPaths;
      selectedBuildingImagePaths = imagePaths;
    });

    // Automatically load the first floor's data if jsonPaths are not empty
    if (jsonPaths.isNotEmpty) {
      loadRoomDataFromJson([jsonPaths.first], 0).then((loadedRooms) {
        setState(() {
          // Combine loaded rooms with other polygons, excluding the selected building itself
          filteredPolygons = loadedRooms + getPolygons().where((polygonData) => polygonData.name != buildingName).toList();
        });
      });
    }
  }

  void dismissRoomInfoPopup() {
    _animationController?.reverse().then((_) {
      _roomInfoOverlay?.remove();
      _roomInfoOverlay = null;
    });
  }

  List<String> extractFloorNumbers(List<String> filePaths) {
    final floorIdentifiers = filePaths.map((path) {
      // This regex captures alphanumeric identifiers after the last '-' and before '.json'
      final match = RegExp(r'-([A-Za-z0-9]+)\.json$').firstMatch(path);
      // If a match is found, return the floor identifier; otherwise, use a placeholder
      return match != null ? match.group(1)! : '';
    }).toList();
    return floorIdentifiers;
  }

  void filterPolygonsAndUpdateUI(String query) {
    List<PolygonData> buildings = getPolygons();
    List<PolygonData> updatedPolygons = [];

    // Assuming `name` is a unique identifier for polygons.
    Set<String> buildingNames = buildings.map((e) => e.name).toSet();

    for (var polygonData in filteredPolygons) {
      // Check if the polygon is not part of the main building list by name
      if (!buildingNames.contains(polygonData.name)) {
        bool matchesSearch = polygonData.description.toLowerCase().contains(query.toLowerCase()) ||
            polygonData.name.toLowerCase().contains(query.toLowerCase());

        Color fillColor = matchesSearch ? const Color.fromRGBO(224, 1, 34, .6) : Colors.grey.withOpacity(0.1);
        Color borderColor = matchesSearch ? const Color.fromRGBO(184, 1, 28, .6) : Colors.grey.withOpacity(0.1);

        Polygon updatedPolygon = Polygon(
          points: polygonData.polygon.points,
          color: fillColor,
          borderColor: borderColor,
          borderStrokeWidth: polygonData.polygon.borderStrokeWidth,
          isFilled: true,
        );

        PolygonData updatedPolygonData = PolygonData(
          name: polygonData.name,
          description: polygonData.description,
          departmentName: polygonData.departmentName,
          aliases: polygonData.aliases,
          polygon: updatedPolygon,
        );

        updatedPolygons.add(updatedPolygonData);
      } else {
        // If the polygon is part of the main buildings, add it without modification
        updatedPolygons.add(polygonData);
      }
    }
    setState(() {
      filteredPolygons = updatedPolygons;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              //scrollWheelVelocity: .00025,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && zoom != position.zoom) {
                  print("Zoom level changed to: ${position.zoom}");
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
              maxZoom: 21,
              minZoom: 14,

              onTap: (tapPosition, point) async {
                bool foundInFilteredPolygons = false;

                // First, handle clicks within the currently selected building's rooms
                if (selectedBuildingName != null) {
                  List<dynamic> polygonsContainingPoint = [];

                  // Find all polygons containing the point
                  for (var polyData in filteredPolygons) {
                    if (isPointInPolygon(point, polyData.polygon.points)) {
                      polygonsContainingPoint.add(polyData);
                      foundInFilteredPolygons = true;
                    }
                  }

                  // Determine the smallest polygon by area
                  dynamic smallestPolygon;
                  double smallestArea = double.infinity;
                  for (var polyData in polygonsContainingPoint) {
                    double area = calculatePolygonArea(polyData.polygon.points);
                    if (area < smallestArea) {
                      smallestArea = area;
                      smallestPolygon = polyData;
                    }
                  }

                  // Trigger action for the smallest polygon
                  if (smallestPolygon != null) {
                    handleFilteredPolygonTap(smallestPolygon);
                    return; // Early return to ensure no further actions are taken
                  } else {
                    dismissRoomInfoPopup(); // No polygon contains the point, dismiss the popup
                  }
                }
                  for (var polyData in getPolygons()) {
                    if (isPointInPolygon(point, polyData.polygon.points)) {
                      // Check if the building is different from the currently selected one
                      if (selectedBuildingName != polyData.name) {
                        String buildingName = polyData.name;
                        var operationMode = 3; // Assuming operation mode decides the logic flow
                        selectedBuildingName = buildingName; // Update the selected building
                        print(buildingName);
                        if (operationMode == 1) {
                          // PART 1 ***************************************
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => Blueprint(buildingName: buildingName),
                          ));
                        } else if (operationMode == 2) {
                          // PART 2 *************************************
                          setState(() {
                            selectedBuildingName = buildingName;
                            isGeoDataWidgetVisible = !isGeoDataWidgetVisible;
                          });
                        } else if (operationMode == 3) {
                          // This operation mode is for loading and showing the building's details
                          selectAndLoadBuilding(buildingName);
                        }
                        // After updating for a new building, exit the loop
                        break;
                      }
                      // If the selected building is the same as before, do nothing
                      break;
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
              Opacity(
                opacity: 0.15,
                child: Container(
                  color: const Color.fromRGBO(230, 241, 255, 1), // Blue overlay
                  width: double.infinity,  // Ensure it covers the entire screen width
                  height: double.infinity, // Ensure it covers the entire screen height
                ),
              ),
              PolygonLayer(polygons: createPolygonsForMap() + filteredPolygons.map((roomData) => roomData.polygon).toList()),
              PolyWidgetLayer(polyWidgets: polyWidgets,),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: [ ...createMarkersForPolygons(filteredPolygons, zoom),]),
              MarkerLayer(markers: markers),
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
              top: MediaQuery.of(context).padding.top + 80,
              right: 0, // Adjusted to attach directly to the right wall
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, // Aligns the buttons to the right
                children: extractFloorNumbers(selectedBuildingJsonPaths!)
                    .asMap() // This converts the list to a map for index, value iteration
                    .map((index, floorIdentifier) => MapEntry(
                  index,
                  Container(
                    margin: const EdgeInsets.only(bottom: 3), // Reduced bottom margin for closer stacking
                    child: ElevatedButton(
                      onPressed: () async {
                        // Assuming you're now passing the index directly
                        List<PolygonData> loadedRooms = await loadRoomDataFromJson([selectedBuildingJsonPaths![index]], index);
                        setState(() {
                          filteredPolygons = loadedRooms + getPolygons().where((polygonData) => polygonData.name != selectedBuildingName).toList(); // Now the first floor is automatically loaded
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                      child: Text(floorIdentifier, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ))
                    .values
                    .toList(),
              ),
            ),


          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.filter_list, color: Colors.grey[400]),
              onPressed: () {
                setState(() {
                  // Toggle the visibility of the chips
                  showFilterChips = !showFilterChips;
                });
              },
            ),
          ),



          Stack(
              children: [
                // Positioned widget for the search bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 60,
                  right: 60, // Adjusted to give more space
                  child: Material(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF424549),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.fromLTRB(15, 10, 0, 10),
                                  ),
                                  style: TextStyle(color: Colors.grey[400]),
                                  onChanged: (value) {
                                    filterPolygonsAndUpdateUI(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Conditional rendering based on showFilterChips state
                        ],
                      ),
                    ),
                  ),
                ),

                // Positioned widget for the filter chips, shown/hidden dynamically
                if (showFilterChips || selectedBuildingName != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 65, // Positioning right below the search bar
                    left: 60,
                    right: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Aligns children to the start of the column
                      children: [
                        // Display filter chips if the flag is true
                        if (showFilterChips)
                          Wrap(
                            spacing: 8.0, // Horizontal space between chips
                            runSpacing: 4.0, // Vertical space between chips
                            children: [
                              InputChip(
                                label: Text('Bathroom', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                onPressed: () {
                                  filterPolygonsAndUpdateUI('Restroom');
                                },
                                backgroundColor: Colors.white70, // Customize as needed
                                deleteIcon: Icon(Icons.close, size: 18, color: Colors.white54),
                                shape: StadiumBorder(side: BorderSide.none),
                              ),
                              // Repeat for other filter chips as needed
                              InputChip(
                                label: Text('Office', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                onPressed: () {
                                  filterPolygonsAndUpdateUI('Office');
                                },
                                backgroundColor: Colors.white70,
                                deleteIcon: Icon(Icons.close, size: 18, color: Colors.white54),
                                shape: StadiumBorder(side: BorderSide.none),
                              ),
                              // Add more chips/buttons as needed
                              InputChip(
                                label: Text('Classroom', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                onPressed: () {
                                  filterPolygonsAndUpdateUI('Class');
                                },
                                backgroundColor: Colors.white70,
                                deleteIcon: Icon(Icons.close, size: 18, color: Colors.white54),
                                shape: StadiumBorder(side: BorderSide.none),
                              ),
                            ],
                          ),


                        // Optional spacing between filter chips and the building chip
                        if (showFilterChips && selectedBuildingName != null) SizedBox(height: 8),

                        // Building chip, displayed if a building is selected
                        if (selectedBuildingName != null)
                          Chip(
                            label: Text(selectedBuildingName!, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            onDeleted: () {
                              setState(() {
                                closeCurrentModal();
                                searchController.clear();
                                selectedBuildingName = null;
                                clearBuildingSelection();
                              });
                            },
                            backgroundColor: Colors.red,
                            deleteIcon: Icon(Icons.close, size: 18, color: Colors.white54),
                            shape: StadiumBorder(side: BorderSide.none),
                          ),
                      ],
                    ),
                  ),
              ],
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


