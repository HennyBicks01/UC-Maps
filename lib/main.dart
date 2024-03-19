import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'polygon.dart'; // Ensure this is implemented
import 'blueprint.dart'; // Ensure this is implemented

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flush Finder',
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

  @override
  void initState() {
    super.initState();
    _determinePosition();
    searchController.addListener(_filterBuildings);
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
      Color fillColor = isFiltered ? polygonData.polygon.color : Colors.grey.withOpacity(0.5);
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
              padding: EdgeInsets.all(5),
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
    mapController.move(centroid, zoom);
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && zoom != position.zoom) {
                  print("Zoom level changed to: ${position.zoom}");
                  setState(() {
                    zoom = position.zoom!;
                    markers = createMarkersForPolygons(filteredPolygons, zoom);
                    // Debugging: Print out number of visible markers
                    print("Number of visible markers: ${markers.length}");
                  });
                }
              },
              initialCenter: const LatLng(39.1317, -84.5167), // Example coordinates
              initialZoom: zoom,
                onTap: (tapPosition, point) {
                  for (var polyData in getPolygons()) {
                    if (isPointInPolygon(point, polyData.polygon.points)) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Blueprint(buildingName: polyData.name),
                      ));
                      break;
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate : 'http://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains : const ['a','b','c','d','e'],// Enable retina mode based on device density
                userAgentPackageName: 'com.example.app',
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
                polygons: createPolygonsForMap(),
              ),
              MarkerLayer(
                // getPolygons()
                markers: createMarkersForPolygons(filteredPolygons, zoom),
              ),
            ],
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
            right: 60,
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
