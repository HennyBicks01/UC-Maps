import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:dio/dio.dart';
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

  Future<List<PolygonData>> loadRoomDataFromJson(List<String> assetPaths) async {
    if (assetPaths.isEmpty) {
      return []; // Return an empty list if no paths are provided
    }

    // For now, use only the first path in the list
    final String jsonStr = await rootBundle.loadString(assetPaths.first);
    final List<dynamic> jsonData = json.decode(jsonStr);

    List<PolygonData> rooms = jsonData.map<PolygonData>((item) {
      List<LatLng> points = (item['polygon'] as List).map<LatLng>((point) {
        // Ensure latitude and longitude are treated as doubles
        double lat = (point[0] is int) ? (point[0] as int).toDouble() : point[0];
        double lng = (point[1] is int) ? (point[1] as int).toDouble() : point[1];
        return LatLng(lat, lng);
      }).toList();

      // The rest of your RoomData construction logic
      return PolygonData(
        name: "", //item['roomInfo']['Description'].toString(),
        polygon: Polygon(
          points: points,
          color: const Color.fromRGBO(224, 1, 34, .4), // Example colors, adjust as needed
          borderColor: const Color.fromRGBO(184, 1, 28, .4), // Example colors, adjust as needed
          borderStrokeWidth: 2.0,
          isFilled: true,
        ),
      );
    }).toList();
    return rooms;
  }

  // Approximate distance between two points in meters
  double distance(LatLng start, LatLng end) {
    var earthRadius = 6371000; // meters
    var dLat = (end.latitude - start.latitude) * pi / 180.0;
    var dLon = (end.longitude - start.longitude) * pi / 180.0;

    var a = sin(dLat/2) * sin(dLat/2) +
        cos(start.latitude * pi / 180.0) * cos(end.latitude * pi / 180.0) *
            sin(dLon/2) * sin(dLon/2);
    var c = 2 * atan2(sqrt(a), sqrt(1-a));
    var d = earthRadius * c;

    return d; // Distance in meters
  }

  String extractFolderName(String path) {
    var parts = path.split('/'); // Split the path into parts
    // Assuming the second last part is the folder name
    return parts.length > 1 ? parts[parts.length - 2] : "";
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

  void saveAndDownloadCorners() {
    if (imagePaths.isNotEmpty) {
      String folderName = extractFolderName(imagePaths[currentIndex]);
      Map<String, dynamic> jsonStructure = {
      };

      imageCorners.forEach((key, value) {
        // Now includes corners, image path, and camera rotation
        jsonStructure["images"][key] = {
          "corners": value.corners.map((e) => [e.latitude, e.longitude]).toList(),
        };
      });

      String jsonString = jsonEncode(jsonStructure);
      triggerDownload(jsonString, "$folderName.json");
    }
  }



  void triggerDownload(String data, String fileName) {
    final text = data;
    final bytes = utf8.encode(text);
    final blob = Blob([bytes], 'application/json');
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    Url.revokeObjectUrl(url);
  }


  Future<void> _selectImageForOverlay(String imagePath) async {
    imageProvider = AssetImage(imagePath);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final Completer<Size> completer = Completer<Size>();
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      final Size imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
      completer.complete(imageSize);
      stream.removeListener(listener!);
    });
    stream.addListener(listener);
    final Size imageSize = await completer.future;

    setState(() {
      selectedImagePath = imagePath;
      // Assuming you've defined `selectedImageSize` in your state to store the image size
      selectedImageSize = imageSize;
    });

    // Optionally, call a function to update overlay or print coordinates here
    getCornerMarkerPositions(); // This function now needs to be adapted to accept `imageSize` as a parameter
  }

  void getCornerMarkerPositions() {
    final rotationDegrees = mapController.camera.rotation;
    final LatLng centerGeo = mapController.camera.center; // Geographic center
    final zoom = mapController.camera.zoom;

    // Convert LatLng to screen coordinates at the given zoom level
    Point centerScreen = mapController.camera.project(centerGeo, zoom);

    double overlaySizeInPixels =  boxSize;
    double aspectRatio = selectedImageSize.width / selectedImageSize.height;
    double overlayWidthPixels, overlayHeightPixels;

    if (aspectRatio >= 1) {
      overlayWidthPixels = overlaySizeInPixels;
      overlayHeightPixels = overlaySizeInPixels / aspectRatio;
    } else {
      overlayHeightPixels = overlaySizeInPixels;
      overlayWidthPixels = overlaySizeInPixels * aspectRatio;
    }

    // Calculate corner points in screen space
    Point topLeftScreen = Point(centerScreen.x - overlayWidthPixels / 2, centerScreen.y - overlayHeightPixels / 2);
    Point topRightScreen = Point(centerScreen.x + overlayWidthPixels / 2, centerScreen.y - overlayHeightPixels / 2);
    Point bottomLeftScreen = Point(centerScreen.x - overlayWidthPixels / 2, centerScreen.y + overlayHeightPixels / 2);
    Point bottomRightScreen = Point(centerScreen.x + overlayWidthPixels / 2, centerScreen.y + overlayHeightPixels / 2);

    List<Point> unrotatedCornersScreen = [topLeftScreen, topRightScreen, bottomRightScreen, bottomLeftScreen];

    // Rotate screen points around the center by rotationDegrees
    currentScreenCorners = unrotatedCornersScreen.map((cornerScreen) =>
        rotatePoint2D(centerScreen, cornerScreen, 360-rotationDegrees)).toList();

    // Convert back to geographic coordinates
    currentImageCorners = currentScreenCorners.map((cornerScreen) =>
        mapController.camera.unproject(cornerScreen, zoom)).toList(); // Assuming unproject does the inverse of project

    // Use rotatedCornersGeo for further processing or output
    //var Latlnprint = currentImageCorners.map((latLng) => 'LatLng(${latLng.latitude}, ${latLng.longitude})').join(', ');
    //print('[$Latlnprint],');
  }

  void getPolygonPositions(String jsonindex, List<LatLng>corners) async {
    final rotationDegrees = mapController.camera.rotation;
    final LatLng centerGeo = mapController.camera.center; // Geographic center
    final zoom = mapController.camera.zoom;

    Point centerScreen = mapController.camera.project(centerGeo, zoom);

    double overlaySizeInPixels = boxSize;
    double aspectRatio = selectedImageSize.width / selectedImageSize.height;
    double overlayWidthPixels, overlayHeightPixels;

    if (aspectRatio >= 1) {
      overlayWidthPixels = overlaySizeInPixels;
      overlayHeightPixels = overlaySizeInPixels / aspectRatio;
    } else {
      overlayHeightPixels = overlaySizeInPixels;
      overlayWidthPixels = overlaySizeInPixels * aspectRatio;
    }

    // Load JSON data for the current building and floor
    String jsonContent = await rootBundle.loadString(jsonindex); // Assuming jsonPaths is already defined and accessible
    List<dynamic> polygonsData = json.decode(jsonContent);

    List<Map<String, dynamic>> newPolygonsData = polygonsData.map<Map<String, dynamic>>((polygonData) {
      List<List<double>> newPolygon = polygonData['polygon'].map<List<double>>((point) {
        Point pixelPoint = Point(point[0].toDouble(), point[1].toDouble());

        // Convert pixel coordinates to screen space
        Point<double> pointInScreenSpace = Point(
            centerScreen.x - (overlayWidthPixels / 2) + (pixelPoint.x * (overlayWidthPixels / selectedImageSize.width)),
            centerScreen.y - (overlayHeightPixels / 2) + (pixelPoint.y * (overlayHeightPixels / selectedImageSize.height))
        );

        // Optionally rotate the point
        Point<double> rotatedPointInScreenSpace = rotatePoint2D(centerScreen, pointInScreenSpace, 360 - rotationDegrees);

        // Convert back to geographic coordinates
        LatLng geoPoint = mapController.camera.unproject(rotatedPointInScreenSpace, zoom);
        return [geoPoint.latitude, geoPoint.longitude];
      }).toList();

      return {
        "polygon": newPolygon,
        "roomInfo": polygonData['roomInfo'],
      };
    }).toList();

    List<List<double>> cornerPositions = corners.map((LatLng corner) {
      return [corner.latitude, corner.longitude];
    }).toList();

    // Additional polygon with corners
    Map<String, dynamic> cornersEntry = {
      "polygon": cornerPositions,
      "roomInfo": {
        "Floor Code": "00", // Assuming this is a special case, so setting a default value
        "Room Code": "PICTURE",
        "Description": "Corners Reference",
        "Department Name": "Special" // Placeholder, adjust as needed
      }
    };

    // Append this corners entry to your list of polygon data
    newPolygonsData.add(cornersEntry);

    // Encode the new polygons data into a JSON string
    String newJsonContent = jsonEncode(newPolygonsData);

    // Determine the filename based on the current JSON path
    String fileName = jsonindex.split('/').last; // Extracts the last part of the path, assuming it's the filename
    if (!fileName.endsWith('.json')) {
      fileName += '.json'; // Ensure the file has a .json extension
    }
    // Download the new JSON with the derived filename
    downloadJson(newJsonContent, fileName);
  }

  void downloadJson(String data, String fileName) {
    // Encode the data
    final bytes = utf8.encode(data);
    final blob = Blob([bytes], 'application/json');
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    Url.revokeObjectUrl(url);
  }

  // Rotates a Point around another Point (the pivot) by a specified number of degrees.
  Point<double> rotatePoint2D(Point<num> pivot, Point<num> point, double rotationDegrees) {
    double rotationRadians = rotationDegrees * pi / 180;
    double cosTheta = cos(rotationRadians);
    double sinTheta = sin(rotationRadians);

    // Translate point back to origin (pivot becomes the origin):
    num x = point.x - pivot.x;
    num y = point.y - pivot.y;

    // Rotate point
    double newX = x * cosTheta - y * sinTheta;
    double newY = x * sinTheta + y * cosTheta;

    // Translate point back:
    double finalX = newX + pivot.x;
    double finalY = newY + pivot.y;

    return Point<double>(finalX, finalY);
  }

  // This function creates PolyWidgets for all processed images
  List<PolyWidget> createPolyWidgetsForProcessedImages() {
    List<PolyWidget> widgets = [];
    imageCorners.forEach((imageName, imageData) {
      if (imageData.corners.length >= 3) {
        // Use imageData.imagePath for each PolyWidget
        widgets.add(PolyWidget.threePoints(
          pointA: imageData.corners[0],
          pointB: imageData.corners[1],
          approxPointC: imageData.corners[2],
          noRotation: true,
          child: Opacity(
            opacity: 0.2,
            child: Image.asset(imageData.imagePath), // Use the specific image path
          ),
        ));
      }
    });
    return widgets;
  }

  void setImageAsProcessed() {
    setState(() {
      if (imagePaths.isNotEmpty) {
        processedImagesIndices.add(currentIndex);
        String imagePath = imagePaths[currentIndex];
        String imageName = imagePath.split('/').last.split('.')[0];
        currentCameraRotation = mapController.camera.rotation;
        currentCentroid = mapController.camera.center;
        // Update to store both corners and imagePath
        imageCorners[imageName] = ImageData(
          List<LatLng>.from(currentImageCorners),
          imagePath,
          currentCameraRotation,
          currentCentroid,// This needs to be defined or obtained elsewhere
        );

        polyWidgets = createPolyWidgetsForProcessedImages();
        skipFloor();
      }
    });
    // Check if all images have been processed
    if (processedImagesIndices.length >= imagePaths.length) {
      // All images processed, perform an action
      // For example, show a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return const AlertDialog(
            title: Text("Processing Complete"),
            content: Text("All images have been processed."),
            actions: <Widget>[
              Text("Please Refresh!")
            ],
          );
        },
      );
    }
  }


  void skipFloor() {
    setState(() {
      int nextIndex = currentIndex + 1;
      while (processedImagesIndices.contains(nextIndex) && nextIndex < imagePaths.length) {
        nextIndex++;
      }currentIndex = nextIndex < imagePaths.length ? nextIndex : 0;
      //print('Skipping to floor: ${currentIndex + 1}, image path: ${imagePaths[currentIndex]}');
      // Prepare for processing the next image
      _selectImageForOverlay(imagePaths[currentIndex]);
    });
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
                    var operationMode = 2;
                    if (operationMode == 1) {
                      // PART 1 ***************************************
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Blueprint(buildingName: buildingName),
                      ));
                    } else if (operationMode == 2) {
                      // PART 2 *************************************
                      imagePaths = getbuildingImagePathFilePaths(buildingName);
                      jsonPaths = getbuildingJsonPathFilePaths(buildingName);
                      selectedBuildingName = buildingName;
                      if (imagePaths.isNotEmpty) {
                        _selectImageForOverlay(imagePaths[currentIndex]);
                      }
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
          TranslucentPointer(
            translucent: true,
            child: Stack(
              children: [
                if (selectedImagePath != null)
                  Center(
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        selectedImagePath!,
                        width: boxSize, // Adjust as needed
                        height: boxSize, // Adjust as needed
                      ),
                    ),
                  ),
              ],
            ),
          ),

              Stack(children:[
                // Positioned widget to place the FloatingActionButton in the bottom right corner
                if (selectedImagePath != null)
                  Positioned(
                    right: 16.0, // Adjust the padding as needed
                    bottom: 16.0, // Adjust the padding as needed
                    child: FloatingActionButton(
                      onPressed: () => {
                        getCornerMarkerPositions(),
                        getPolygonPositions(jsonPaths[currentIndex], currentImageCorners),
                        setImageAsProcessed(),
                      },
                      backgroundColor: Colors.green[700],
                      child: const Icon(Icons.check),
                    ),
                  ),
                if (selectedImagePath != null)
                  Positioned(
                    right: 16.0,
                    bottom: 80.0, // Adjust the position so it doesn't overlap with the other button
                    child: FloatingActionButton(
                      onPressed: () => skipFloor(),
                      backgroundColor: Colors.blue[700],
                      child: const Icon(Icons.skip_next), // Different color for distinction
                    ),
                  ),
              ]),

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

class MapOverlayWidget extends StatelessWidget {
  final MapController mapController;
  final List<LatLng> points; // Points you want to draw or show on the map
  final Widget Function(LatLng point) itemBuilder; // Builder for items you want to show

  const MapOverlayWidget({
    Key? key,
    required this.mapController,
    required this.points,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: points.map((point) {
              var pos = mapController.camera.project(point);
              var scaledPos = Point(pos.x * mapController.camera.zoom, pos.y * mapController.camera.zoom);
              var bounds = mapController.camera.getPixelWorldBounds(mapController.camera.zoom);
              if (bounds == null) {
                return Container(); // Or some fallback widget
              }
              var topLeft = bounds.topLeft;
              var finalPos = Point(scaledPos.x - topLeft.x, scaledPos.y - topLeft.y);
              return Positioned(
                left: finalPos.x.toDouble(),
                top: finalPos.y.toDouble(),
                child: itemBuilder(point),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ImageData {
  List<LatLng> corners;
  String imagePath;
  double cameraRotation; // Assuming rotation is a double
  LatLng centroid;
  ImageData(this.corners, this.imagePath, this.cameraRotation, this.centroid);
}
