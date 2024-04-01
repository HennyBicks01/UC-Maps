import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:find_flush/png.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ImageTransformation {
  double scale;
  double rotation;
  Offset position;

  ImageTransformation({this.scale = 1.0, this.rotation = 0.0, this.position = Offset.zero});
}


class InteractiveImageOverlay extends StatefulWidget {
  final String buildingName;
  final Function(LatLng centroid, double rotation) onSave;
  final MapController mapController;

  const InteractiveImageOverlay({
    Key? key,
    required this.buildingName,
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
  int currentIndex = 0;
  List<String> imagePaths = [];
  List<double> imageOpacities = [];
  List<ImageTransformation> imageTransformations = [];
  int saveCount = 0;
  Map<String, dynamic> savedData = {
    "floors": []
  };


  @override
  void initState() {
    super.initState();
    imagePaths = getbuildingImagePathFilePaths(widget.buildingName); // Fetch image paths based on the building name
    imageOpacities = List.generate(imagePaths.length, (index) => index == 0 ? 1.0 : 0.0);
    imageTransformations = List.generate(imagePaths.length, (_) => ImageTransformation());
    if (imagePaths.isNotEmpty) {
      loadImageAndCenter(imagePaths[currentIndex]);
    }
    RawKeyboard.instance.addListener(_handleKey);
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKey);
    super.dispose();
  }

  void nextImage() {
    setState(() {
      imageTransformations[currentIndex] = ImageTransformation(
        scale: scale,
        rotation: rotation,
        position: position,
      );
      position = Offset.zero;
      rotation = 0.0;
      initialPosition = Offset.zero;
      scale = 1.0;
      imageOpacities[currentIndex] = 0.0; // Set current image's opacity to 10%
      currentIndex = (currentIndex + 1) % imagePaths.length; // Cycle through images
      imageOpacities[currentIndex] = 1.0; // Ensure next image is fully visible
      if (imagePaths.isNotEmpty) {
        loadImageAndCenter(imagePaths[currentIndex]); // Load the next image
      }
    });
  }

  void saveImage() {
    setState(() {
      saveCount++;
      imageTransformations[currentIndex] = ImageTransformation(
        scale: scale,
        rotation: rotation,
        position: position,
      );
      position = Offset.zero;
      rotation = 0.0;
      initialPosition = Offset.zero;
      scale = 1.0;
      imageOpacities[currentIndex] = 0.2; // Set current image's opacity to 20%
      currentIndex = (currentIndex + 1) % imagePaths.length; // Cycle through images
      imageOpacities[currentIndex] = 1.0; // Ensure next image is fully visible
      if (saveCount == imagePaths.length) {
        showFloorSelectionPrompt();
        saveCount = 0; // Reset save count if needed
      }
      if (imagePaths.isNotEmpty) {
        loadImageAndCenter(imagePaths[currentIndex]); // Load the next image
      }
    });
  }

  void _downloadFile(String content, String fileName) {
    final blob = Blob([content]);
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    Url.revokeObjectUrl(url);
  }

  void saveImageData(String imagePath, List<LatLng> corners) {
    // Use RegExp to extract the base name of the image file without extension
    final RegExp regex = RegExp(r'/([^/]+)\.png$', caseSensitive: false);
    final match = regex.firstMatch(imagePath);
    String imageName = "";
    if (match != null && match.groupCount >= 1) {
      imageName = match.group(1) ?? ""; // Extract the file name without extension
    }
    List<List<double>> simpleCorners = corners.map((c) => [c.latitude, c.longitude]).toList();
    savedData[imageName] = simpleCorners;
    print(simpleCorners);
  }

  void finalizeAndDownloadJson() {
    String jsonStr = jsonEncode(savedData);
    _downloadFile(jsonStr, "TEACHERS.json"); // Assuming TEACHERS as folder name example
  }

  void showFloorSelectionPrompt() {
    // Track selected indexes with a Map for easier state management
    Map<int, bool> selectedIndexes = {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850], // Dark gray background
          title: const Text('Select Floors', style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                height: 500,
                child: GridView.builder(
                  itemCount: imagePaths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1, // Ensures the children are square-shaped
                  ),
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndexes[index] ?? false;

                    return GridTile(
                      footer: GridTileBar(
                        title: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            // This won't be directly called since we use InkWell
                          },
                          activeColor: Colors.blue,
                        ),
                        backgroundColor: Colors.black45,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            // Toggle selection state on tap
                            selectedIndexes[index] = !isSelected;
                          });
                        },
                        child: Container(
                          color: Colors.black12, // Background color to see the tap effect
                          child: Image.asset(
                            imagePaths[index],
                            fit: BoxFit.fitWidth,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.white)),
              onPressed: () {
                List<String> selectedFloors = selectedIndexes.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => extractBuildingName(imagePaths[entry.key]))
                    .toList();
                savedData['floors'] = selectedFloors;
                finalizeAndDownloadJson();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String extractBuildingName(String imagePath) {
    final RegExp regex = RegExp(r'Blueprints/(?:[^/]+/)?(?:[^/]+/)?([^/]+)\.png$');
    final match = regex.firstMatch(imagePath);
    return match?.group(1) ?? "";
  }

  void _handleKey(RawKeyEvent event) {
    setState(() {
      isCtrlPressed = event.isControlPressed;
    });
  }

  Future<void> loadImageAndCenter(String imagePath) async {
    final ImageProvider imageProvider = AssetImage(imagePath);
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
    final Size screenSize = MediaQuery.of(context).size;

    // Determine the scale factor for both width and height
    final double scaleFactorWidth = screenSize.width / imageSize.width;
    final double scaleFactorHeight = screenSize.height / imageSize.height;
    // Use the smaller scale factor to ensure the image fits within the screen
    final double scaleFactor = min(scaleFactorWidth, scaleFactorHeight);

    // Calculate the scaled image dimensions
    final double displayedImageWidth = imageSize.width * scaleFactor;
    final double displayedImageHeight = imageSize.height * scaleFactor;

    // Calculate the initial offsets to center the image
    final double initialOffsetX = (screenSize.width - displayedImageWidth) / 2;
    final double initialOffsetY = (screenSize.height - displayedImageHeight) / 2;

    setState(() {
      // Apply both offsets to center the image on the screen
      position = Offset(initialOffsetX, initialOffsetY);
      initialPosition = Offset(initialOffsetX, initialOffsetY);
    });
  }


  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      double newScale = scale + (event.scrollDelta.dy * -0.00005);
      newScale = newScale.clamp(.01, 5.0); // Allows more zoom out
      double scaleChange = newScale - scale;
      Size screenSize = MediaQuery.of(context).size;
      Offset screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
      double adjustmentFactor = 1.0; // Adjust this factor based on your needs
      Offset scaleAdjustment = Offset(
        (screenCenter.dx * scaleChange) * adjustmentFactor,
        (screenCenter.dy * scaleChange) * adjustmentFactor,
      );

      setState(() {
        scale = newScale;
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
        //print(rotation);
      });
    } else {
      setState(() {
        position += details.delta;
        //print(position);
      });
    }
  }

  Future<List<LatLng>> calculateGeographicalCorners(
      MapController mapController, Size imageSize, Offset imagePosition, double scale, double rotationDegrees) async {

    LatLng centerGeo = mapController.camera.center;
    double zoom = mapController.camera.zoom;
    var centerPoint = mapController.camera.project(centerGeo, zoom);
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
            child: Image.asset(imagePaths[currentIndex], fit: BoxFit.fitHeight),
          ),

          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () async {
                // Create an ImageProvider from the asset.
                final ImageProvider imageProvider = AssetImage(imagePaths[currentIndex]);

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

                print("[" + corners.map((corner) => "LatLng(${corner.latitude}, ${corner.longitude})").join(', ') + "],");

                // Calculate centroid of corners for onSave.
                LatLng centroid = LatLng(
                  (corners[0].latitude + corners[2].latitude) / 2,
                  (corners[0].longitude + corners[2].longitude) / 2,
                );

                // Call the onSave callback with calculated values.
                widget.onSave(centroid, rotation);
                saveImage();
              },
              child: Icon(Icons.check),
            ),
              ),
          Positioned(
            right: 20,
            bottom: 120,
            child: FloatingActionButton(
              onPressed: () async {
                nextImage();
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

  /*@override
  Widget build(BuildContext context) {
    // Getting the screen size for initial positioning
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        onPointerSignal: _handleScroll,
        child: GestureDetector(
          onPanUpdate: _onPanUpdate,
          child: Stack(
            children: imagePaths.asMap().entries.map((entry) {
              int idx = entry.key;
              String path = entry.value;

              // Determine if the current transformations or the stored transformations should be applied
              var currentTransformations = idx == currentIndex ? ImageTransformation(scale: scale, rotation: rotation, position: position) : imageTransformations[idx];

              final double initialTranslateX = (screenSize.width * (1 - currentTransformations.scale)) / 2;
              final double initialTranslateY = (screenSize.height * (1 - currentTransformations.scale)) / 2;

              return Opacity(
                opacity: imageOpacities[idx], // Apply the corresponding opacity
                child: Transform(
                  alignment: Alignment.center, // Ensure the rotation pivot is the center
                  transform: Matrix4.identity()
                    ..translate(initialTranslateX + currentTransformations.position.dx, initialTranslateY + currentTransformations.position.dy) // Apply translation
                    ..scale(currentTransformations.scale) // Then apply scale
                    ..rotateZ(currentTransformations.rotation), // Finally apply rotation
                  child: Image.asset(path, fit: BoxFit.fill),
                ),

              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              // Create an ImageProvider from the asset.
              final ImageProvider imageProvider = AssetImage(imagePaths[currentIndex]);

              // Get the image stream from the provider.
              final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);

              // Listen to the stream of image data.
              final Completer<Size> completer = Completer<Size>();
              ImageStreamListener? listener;
              listener = ImageStreamListener((ImageInfo info, bool _) {
                final Size imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
                completer.complete(imageSize);
                stream.removeListener(listener!);
              });

              stream.addListener(listener);
              final Size imageSize = await completer.future;

              // Determine the displayed image size based on the screen's height
              final Size screenSize = MediaQuery.of(context).size;
              final double displayedImageHeight = screenSize.height * scale; // Assuming the image is scaled based on the screen height
              final double universalScaleFactor = displayedImageHeight / imageSize.height;

              Offset adjustedpos = position - initialPosition;
              print(adjustedpos);

              // Assuming 'imageTransformations' is a List<ImageTransformation> accessible in your class
              ImageTransformation currentTransformation = ImageTransformation(scale: scale, rotation: rotation, position: position);

              // Update the transformation state for the current image
              imageTransformations[currentIndex] = currentTransformation;

              List<LatLng> corners = await calculateGeographicalCorners(
                widget.mapController,
                imageSize, // Original image size
                adjustedpos,
                universalScaleFactor, // Use the universal scale factor that adjusts for displayed image size
                rotation,
              );

              saveImageData(imagePaths[currentIndex], corners);
              print("[" + corners.map((corner) => "LatLng(${corner.latitude}, ${corner.longitude})").join(', ') + "],");

              LatLng centroid = LatLng(
                (corners[0].latitude + corners[2].latitude) / 2,
                (corners[0].longitude + corners[2].longitude) / 2,
              );

              widget.onSave(centroid, rotation);
              saveImage();
            },
            child: const Icon(Icons.check),
          ),
          FloatingActionButton(
            onPressed: () {
              nextImage(); // Directly move to the next image without additional processing
            },
            child: const Icon(Icons.navigate_next),
          ),
        ],
      ),
    );
  }*/
}