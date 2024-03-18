import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'polygon.dart';
import 'blueprint.dart';

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
  double zoom = 17.0; // Initial zoom level
  TextEditingController searchController = TextEditingController();
  List<PolygonData> filteredPolygons = getPolygons(); // Initially display all buildings


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
    // ... Geolocation code (same as before)
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


  List<Marker> createMarkersForPolygons(List<PolygonData> polygons) {
    return polygons.map((polygonData) {
      LatLng centroid = calculateCentroid(polygonData.polygon.points);
      return Marker(
        width: 100.0,
        height: 35.0,
        point: centroid,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            polygonData.name,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ),
      );
    }).toList();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
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
                markers: createMarkersForPolygons(filteredPolygons),
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
        ],
      ),
    );
  }
}
