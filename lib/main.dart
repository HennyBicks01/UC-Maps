import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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



  String getBlueprintPath(String buildingName) {
    return 'assets/Blueprints/TEACHERS/TEACHERS-06.png';
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
                    // Instead of adding a marker, trigger the overlay with the image manipulation widget
                     /*showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return InteractiveImageOverlay(
                          mapController: mapController,
                          imagePath: getBlueprintPath(polyData.name),
                          onSave: (centroid, rotation) {
                            // Logic to save the adjustments
                            // This function is called with the final centroid and rotation
                          },
                        );
                      },
                    );*/
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

class InteractiveImageOverlay extends StatefulWidget {
  final String imagePath;
  final Function(LatLng centroid, double rotation) onSave;
  final MapController mapController;

  const InteractiveImageOverlay({
    Key? key,
    required this.imagePath,
    required this.onSave,
    required this.mapController,
  }) : super(key: key);

  @override
  _InteractiveImageOverlayState createState() => _InteractiveImageOverlayState();
}

class _InteractiveImageOverlayState extends State<InteractiveImageOverlay> {
  double scale = 1.0;
  double rotation = 0.0;
  Offset position = Offset.zero;
  Offset initialPosition = Offset.zero;
  bool isCtrlPressed = false;

  @override
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_handleKey);
    loadImageAndCenter();
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    setState(() {
      isCtrlPressed = event.isControlPressed;
    });
  }

  Future<void> loadImageAndCenter() async {
    final ImageProvider imageProvider = AssetImage(widget.imagePath);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final Completer<Size> completer = Completer<Size>();
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final Size imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
      completer.complete(imageSize);

      // Once we have the image size, remove the listener
      stream.removeListener(listener!);
    });
    stream.addListener(listener);

    final Size imageSize = await completer.future;
    final Size screenSize = MediaQuery.of(context).size;

    // Calculate the scale factor based on the height
    final double scaleFactor = screenSize.height / imageSize.height;

    // Calculate the displayed image width
    final double displayedImageWidth = imageSize.width * scaleFactor;

    // Calculate the initial horizontal offset to center the image
    final double initialOffsetX = (screenSize.width - displayedImageWidth) / 2;

    // Set the initial position state to center the image
    setState(() {
      position = Offset(initialOffsetX, 0); // Vertical offset is 0
      initialPosition = Offset(initialOffsetX, 0);
    });
  }

  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      double newScale = scale + (event.scrollDelta.dy * -0.00005);
      newScale = newScale.clamp(.01, 5.0); // Allows more zoom out

      // Calculate the change in scale
      double scaleChange = newScale - scale;

      // Assuming the image is initially centered, calculate the center of the screen
      Size screenSize = MediaQuery.of(context).size;
      Offset screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);

      // Adjust the position based on the scale change to keep the image centered
      // This adjustment is a basic approximation and might need fine-tuning
      double adjustmentFactor = 1.0; // Adjust this factor based on your needs
      Offset scaleAdjustment = Offset(
        (screenCenter.dx * scaleChange) * adjustmentFactor,
        (screenCenter.dy * scaleChange) * adjustmentFactor,
      );

      setState(() {
        scale = newScale;
        // Adjust the position to attempt to keep the image centered
        position += scaleAdjustment;
        initialPosition += scaleAdjustment;
      });
    }
  }



  void _onPanUpdate(DragUpdateDetails details) {
    if (isCtrlPressed) {
      setState(() {
        rotation +=
            details.delta.dx * 0.002; // Adjust rotation sensitivity as needed
      });
    } else {
      setState(() {
        position += details.delta;
      });
    }
  }

  Future<List<LatLng>> calculateGeographicalCorners(
      MapController mapController, Size imageSize, Offset imagePosition, double scale, double rotationDegrees) async {

    // Convert the center position to geographical coordinates
    LatLng centerGeo = mapController.camera.center;
    double zoom = mapController.camera.zoom;

    // Calculate the pixel coordinates of the center of the map
    var centerPoint = mapController.camera.project(centerGeo, zoom);

    // Calculate the center of the image in pixel coordinates
    var imageCenter = Point(
      centerPoint.x + imagePosition.dx,
      centerPoint.y + imagePosition.dy,
    );

    // Initial corner points before rotation
    var topLeft = Point(imageCenter.x - (imageSize.width * scale) / 2, imageCenter.y - (imageSize.height * scale) / 2);
    var topRight = Point(topLeft.x + imageSize.width * scale, topLeft.y);
    var bottomLeft = Point(topLeft.x + imageSize.width * scale, topLeft.y + imageSize.height * scale);
    var bottomRight = Point(topLeft.x, topLeft.y + imageSize.height * scale);

    // Convert rotation from degrees to radians
    double rotationRadians = rotationDegrees;

    // Rotate each corner point around the center of the image
    List<Point> rotatedCorners = [topLeft, topRight, bottomLeft, bottomRight].map((point) {
      return rotatePoint(point, imageCenter, rotationRadians);
    }).toList();

    // Convert rotated corner points back to geographical coordinates
    List<LatLng> geoCorners = rotatedCorners.map((point) {
      return mapController.camera.unproject(Point(point.x, point.y), zoom);
    }).toList();

    return geoCorners;
  }

  // Function to rotate a point around a pivot
  Point rotatePoint(Point point, Point pivot, double angle) {
    double cosTheta = cos(angle);
    double sinTheta = sin(angle);

    var translatedX = point.x - pivot.x;
    var translatedY = point.y - pivot.y;

    var rotatedX = translatedX * cosTheta - translatedY * sinTheta;
    var rotatedY = translatedX * sinTheta + translatedY * cosTheta;

    return Point(rotatedX + pivot.x, rotatedY + pivot.y);
  }

  @override
  Widget build(BuildContext context) {
    // Getting the screen size for initial positioning
    final Size screenSize = MediaQuery.of(context).size;

    // Initial translation to center the image based on current scale and screen size
    final double initialTranslateX = (screenSize.width * (1 - scale)) / 2;
    final double initialTranslateY = (screenSize.height * (1 - scale)) / 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        onPointerSignal: _handleScroll,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          child: Stack(
            children: [
              Transform(
                alignment: Alignment.center, // Ensure the rotation pivot is the center
                transform: Matrix4.identity()
                  ..translate(initialTranslateX + position.dx, initialTranslateY + position.dy) // Apply translation
                  ..scale(scale) // Then apply scale
                  ..rotateZ(rotation), // Finally apply rotation
                child: Image.asset(widget.imagePath, fit: BoxFit.fitHeight),
              ),

              Positioned(
                right: 20,
                bottom: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    // Create an ImageProvider from the asset.
                    final ImageProvider imageProvider = AssetImage(widget.imagePath);

                    // Get the image stream from the provider.
                    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);

                    // Listen to the stream of image data.
                    final Completer<Size> completer = Completer<Size>();
                    ImageStreamListener? listener;
                    listener = ImageStreamListener((ImageInfo info, bool _) {
                      // When the image is loaded, get its size.
                      final Size imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());

                      // Complete the completer with the image size.
                      completer.complete(imageSize);

                      // Remove the listener once we got the dimensions.
                      stream.removeListener(listener!);
                    });

                    // Add the listener to the stream.
                    stream.addListener(listener);

                    // Wait for the image size.
                    final Size imageSize = await completer.future;

                    // Determine the displayed image size based on the screen's height
                    final Size screenSize = MediaQuery.of(context).size;
                    final double displayedImageHeight = screenSize.height * scale; // Assuming the image is scaled based on the screen height
                    final double universalScaleFactor = displayedImageHeight / imageSize.height;


                    Offset adjustedpos = position - initialPosition;
                    print(position);
                    print(initialPosition);
                    print(adjustedpos);

                    List<LatLng> corners = await calculateGeographicalCorners(
                      widget.mapController,
                      imageSize, // Original image size
                      adjustedpos,
                      universalScaleFactor, // Use the universal scale factor that adjusts for displayed image size
                      rotation,
                    );

                    print("Corners: [" + corners.map((corner) => "LatLng(${corner.latitude}, ${corner.longitude})").join(', ') + "]");

                    // Calculate centroid of corners for onSave.
                    LatLng centroid = LatLng(
                      (corners[0].latitude + corners[2].latitude) / 2,
                      (corners[0].longitude + corners[2].longitude) / 2,
                    );

                    // Call the onSave callback with calculated values.
                    widget.onSave(centroid, rotation);
                  },
                  child: Icon(Icons.check),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}