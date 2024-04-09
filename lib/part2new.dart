import 'dart:async';
import 'dart:convert';
// import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_polywidget/flutter_map_polywidget.dart';
import 'package:latlong2/latlong.dart';

import 'json.dart';
import 'png.dart';

class GeoDataWidget extends StatefulWidget {
  final MapController mapController;
  final String buildingName;
  List<PolyWidget> polyWidgets; // Add this

  GeoDataWidget({
    Key? key,
    required this.mapController,
    required this.buildingName,
    required this.polyWidgets, // Add this
  }) : super(key: key);

  @override
  _GeoDataWidgetState createState() => _GeoDataWidgetState();
}



class _GeoDataWidgetState extends State<GeoDataWidget> {
  int currentIndex = 0;
  Set<int> processedImagesIndices = {};
  Map<String, ImageData> imageCorners = {}; // Assume ImageData is defined or imported
  // Assume PolyWidget is defined or imported
  late Size selectedImageSize;
  String? selectedImagePath;
  double currentCameraRotation = 0;
  double boxSize = 0; // Initialized dynamically
  List<String> imagePaths = [];
  List<String> jsonPaths = [];
  ImageProvider imageProvider = const AssetImage('');
  List<LatLng> currentImageCorners = [];
  late LatLng currentCentroid;
  List<Point> currentScreenCorners = [];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Size screenSize = MediaQuery.of(context).size;
      final double minDimension = min(screenSize.width, screenSize.height);
      setState(() {
        boxSize = minDimension * 0.95; // Set to 95% of the minimum dimension
      });

      // Load file paths
      getJsonFilePaths();
      getImageFilePaths();
      // Ensure there's an image path before attempting to select an image
      if (imagePaths.isNotEmpty) {
        selectedImagePath = imagePaths[currentIndex];
        // It's important to call _selectImageForOverlay after imagePaths is guaranteed to be loaded
        _selectImageForOverlay(imagePaths[currentIndex]);
      }

      // Debug prints to check paths (remove or comment out for production)
      print(imagePaths);
      print(jsonPaths);
    });
  }

  void getJsonFilePaths() {
    // Use function from json.dart
    jsonPaths = getbuildingJsonPathFilePaths(widget.buildingName);
  }

  void getImageFilePaths() {
    // Use function from png.dart
    imagePaths = getbuildingImagePathFilePaths(widget.buildingName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
                        width: boxSize, // Use widget.boxSize to access the boxSize passed to the StatefulWidget
                        height: boxSize,
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
        ],
      ),
    );
  }



  /* void triggerDownload(String data, String fileName) {
    final text = data;
    final bytes = utf8.encode(text);
    final blob = Blob([bytes], 'application/json');
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    Url.revokeObjectUrl(url);
  } */

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
      selectedImageSize = imageSize;
    });
  }

  void getCornerMarkerPositions() {
    final rotationDegrees = widget.mapController.camera.rotation;
    final LatLng centerGeo = widget.mapController.camera.center; // Geographic center
    final zoom = widget.mapController.camera.zoom;

    // Convert LatLng to screen coordinates at the given zoom level
    Point centerScreen = widget.mapController.camera.project(centerGeo, zoom);

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
        widget.mapController.camera.unproject(cornerScreen, zoom)).toList(); // Assuming unproject does the inverse of project

  }

  void getPolygonPositions(String jsonindex, List<LatLng>corners) async {
    final rotationDegrees = widget.mapController.camera.rotation;
    final LatLng centerGeo = widget.mapController.camera.center; // Geographic center
    final zoom = widget.mapController.camera.zoom;

    Point centerScreen = widget.mapController.camera.project(centerGeo, zoom);

    double overlaySizeInPixels = boxSize;
    double aspectRatio = selectedImageSize.height;
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
        LatLng geoPoint = widget.mapController.camera.unproject(rotatedPointInScreenSpace, zoom);
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
    // downloadJson(newJsonContent, fileName);
  }

  /* void downloadJson(String data, String fileName) {
    // Encode the data
    final bytes = utf8.encode(data);
    final blob = Blob([bytes], 'application/json');
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    Url.revokeObjectUrl(url);
  } */

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
        currentCameraRotation = widget.mapController.camera.rotation;
        currentCentroid = widget.mapController.camera.center;
        // Update to store both corners and imagePath
        imageCorners[imageName] = ImageData(
          List<LatLng>.from(currentImageCorners),
          imagePath,
          currentCameraRotation,
          currentCentroid,
        );

        widget.polyWidgets = createPolyWidgetsForProcessedImages();
        skipFloor();
      }
    });
    // Check if all images have been processed
    if (processedImagesIndices.length >= imagePaths.length) {
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
      print('Skipping to floor: ${currentIndex + 1}, image path: ${imagePaths[currentIndex]}');
      // Prepare for processing the next image
      _selectImageForOverlay(imagePaths[currentIndex]);
    });
  }
}

class ImageData {
  List<LatLng> corners;
  String imagePath;
  double cameraRotation; // Assuming rotation is a double
  LatLng centroid;
  ImageData(this.corners, this.imagePath, this.cameraRotation, this.centroid);
}
