import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:html' as html;
import 'roomdata.dart';

// Constants for base paths
const String basePathImages = 'assets/Blueprints/';
const String basePathMaps = 'assets/BlueprintMaps/';

class Blueprint extends StatefulWidget {
  final String buildingName;

  const Blueprint({Key? key, required this.buildingName}) : super(key: key);

  @override
  BlueprintState createState() => BlueprintState();
}

class BlueprintState extends State<Blueprint> with WidgetsBindingObserver{
  ValueNotifier<Set<int>> clickedPolygons = ValueNotifier({});
  List<PolygonRoomData> polygons = [];
  int? selectedPolygonIndex;
  double scaleFactor = 1.0;




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add the observer
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await updateScaleFactor(); // Your existing logic
      loadPolygonData('assets/BlueprintMaps/TEACHERS/TEACHERS-03.json', 1.0, 1.0);
      // Assuming you have a method to load initial data or perform initial setup
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // This method is called when the window size changes
    print('Window size changed');
    // Optionally, update your scaleFactor or perform other adjustments here
    _handleScreenSizeChange();
  }

  Future<void> _handleScreenSizeChange() async {
    // Assuming you're recalculating based on the first image in your list
    if (getImageFilePaths().isNotEmpty) {
      String imagePath = getImageFilePaths().first;
      double newScaleFactor = await calculateScaleFactor(context, imagePath);

      setState(() {
        scaleFactor = newScaleFactor; // Update your state's scale factor
      });

      print('Window size changed. New scale factor: $newScaleFactor');
    } else {
      print('No images available for scale factor calculation.');
    }
  }


  List<String> getImageFilePaths() {
    Map<String, List<String>> buildingImages = {
      'Teachers College': ['assets/Blueprints/TEACHERS/TEACHERS-01.png', 'assets/Blueprints/TEACHERS/TEACHERS-02.png'
      , 'assets/Blueprints/TEACHERS/TEACHERS-03.png', 'assets/Blueprints/TEACHERS/TEACHERS-04.png'
      , 'assets/Blueprints/TEACHERS/TEACHERS-05.png', 'assets/Blueprints/TEACHERS/TEACHERS-06.png'],
      // Add more buildings here
    };
    return buildingImages[widget.buildingName] ?? [];
  }

  Future<double> calculateScaleFactor(BuildContext context, String imagePath) async {
    ImageProvider imageProvider = AssetImage(imagePath);
    Completer<Size> completer = Completer<Size>();

    imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
        completer.complete(Size(image.image.width.toDouble(), image.image.height.toDouble()));
      }),
    );

    Size imageSize = await completer.future;
    Size screenSize = MediaQuery.of(context).size;

    // Use either height or width depending on your layout needs
    print('image: $imageSize screen: ${screenSize.height}');
    double scaleFactor = (screenSize.height - 55)/ imageSize.height ;
    return scaleFactor;
  }



  Future<void> loadPolygonData(String jsonPath, double scaleFactorWidth, double scaleFactorHeight) async {
    final jsonString = await rootBundle.loadString(jsonPath);
    final jsonData = json.decode(jsonString) as List;
    List<PolygonRoomData> loadedPolygons = [];

    for (var item in jsonData) {
      PolygonRoomData polygonData = PolygonRoomData.fromJson(item as Map<String, dynamic>);
      loadedPolygons.add(polygonData);
    }

    setState(() {
      polygons = loadedPolygons;
    });
  }

  Future<void> updateScaleFactor() async {
    // Assuming you're working with the first image as an example
    if (getImageFilePaths().isNotEmpty) {
      String imagePath = getImageFilePaths().first;
      double newScaleFactor = await calculateScaleFactor(context, imagePath);
      setState(() {
        scaleFactor = newScaleFactor;
      });
    }
  }

  Future<List<Map<String, String>>> loadRoomData(String jsonPath) async {
    final jsonString = await rootBundle.loadString(jsonPath);
    final jsonData = json.decode(jsonString) as List;
    return jsonData.map<Map<String, String>>((data) => Map<String, String>.from(data)).toList();
  }

  void triggerDownload(String jsonString, String filename) {
    // Encode your JSON string
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }


  void _showRoomDataOrInputDialog(BuildContext context, int polygonIndex, List<PolygonRoomData> currentPolygons) {
    // Ensure the index is valid to prevent "Index out of range" errors.
    if (polygonIndex < 0 || polygonIndex >= currentPolygons.length) {
      print("Invalid polygon index: $polygonIndex");
      return; // Early return if index is invalid
    }

    Map<String, String> roomInfo = currentPolygons[polygonIndex].roomInfo;
    bool hasRoomInfo = roomInfo.isNotEmpty;

    if (hasRoomInfo) {
      // Display existing room information
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Room Information"),
            content: SingleChildScrollView(
              child: ListBody(
                children: roomInfo.entries.map((entry) => Text("${entry.key}: ${entry.value}")).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Delete Room Data'),
                onPressed: () {
                  // Clear room info for the selected polygon
                  setState(() {
                    currentPolygons[polygonIndex].roomInfo.clear();
                  });
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Prompt for new room information
      TextEditingController roomNumberController = TextEditingController();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Assign Room Number"),
            content: TextField(
              controller: roomNumberController,
              decoration: const InputDecoration(hintText: "Enter Room Number"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Submit"),
                onPressed: () {
                  // Update room info for the selected polygon
                  setState(() {
                    currentPolygons[polygonIndex].roomInfo = {"Room Code": roomNumberController.text};
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }



  void _navigateAndDisplayImage(BuildContext context, String imagePath, String jsonPath) async {
    // Dynamically load the JSON for the selected blueprint
    final jsonString = await rootBundle.loadString(jsonPath);
    final jsonData = json.decode(jsonString) as List;
    List<PolygonRoomData> loadedPolygons = jsonData.map<PolygonRoomData>((item) => PolygonRoomData.fromJson(item as Map<String, dynamic>)).toList();
    print('$scaleFactor');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(imagePath.split('/').last), // Displaying the name of the blueprint as the title
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  // Use the dynamically loaded polygon data for the download
                  final modifiedJsonString = json.encode(loadedPolygons.map((e) => e.toJson()).toList());
                  // Dynamically set the filename based on the blueprint's name
                  String filename = imagePath.split('/').last.replaceFirst('.png', '.json');
                  triggerDownload(modifiedJsonString, filename);
                },
                tooltip: 'Download Modified Data',
              ),
            ],
          ),
          body: InteractiveViewer(
            child: Builder(
              builder: (BuildContext innerContext) {
                return GestureDetector(
                  onTapUp: (TapUpDetails details) {
                    RenderBox box = innerContext.findRenderObject() as RenderBox;
                    final Offset localPosition = box.globalToLocal(details.globalPosition);
                    int polygonIndex = -1; // Initialize with an invalid index

                    for (int i = 0; i < loadedPolygons.length; i++) {
                      if (isPointInPolygon(localPosition, loadedPolygons[i].polygon.map((e) => Offset(e[0].toDouble() * scaleFactor, e[1].toDouble() * scaleFactor)).toList())) {
                        polygonIndex = i; // Found a valid index
                        break;
                      }
                    }

                    if (polygonIndex != -1) {
                      Set<int> newSet = Set.from(clickedPolygons.value);
                      if (newSet.contains(polygonIndex)) {
                        newSet.remove(polygonIndex);
                      } else {
                        newSet.add(polygonIndex);
                      }
                      clickedPolygons.value = newSet; // This automatically notifies listeners

                      // Optionally, add a delay before showing dialog to allow the user to see the update
                      Future.delayed(Duration(milliseconds: 200), () {
                        _showRoomDataOrInputDialog(context, polygonIndex, loadedPolygons); // Ensure this method can handle dynamic polygons data
                      });
                    } else {
                      print("No valid polygon found at tap location. Clicked position: $localPosition");
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(imagePath, fit: BoxFit.fitHeight, alignment: Alignment.topLeft),
                      ),
                      ValueListenableBuilder<Set<int>>(
                        valueListenable: clickedPolygons,
                        builder: (context, value, child) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: InteractivePolygonPainter(
                              loadedPolygons.map((e) => e.polygon.map((p) => Offset(p[0] * scaleFactor, p[1] * scaleFactor)).toList()).toList(),
                              value,
                              loadedPolygons,
                              scaleFactor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    List<String> imageFiles = getImageFilePaths();
    double cardHeight = MediaQuery.of(context).size.height / 5;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingName),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: imageFiles.length,
        itemBuilder: (context, index) {
          String imagePath = imageFiles[index];
          String jsonPath = imagePath
              .replaceFirst('Blueprints', 'BlueprintMaps')
              .replaceFirst(RegExp(r'\.png$'), '.json');

          return InkWell(
            onTap: () => navigateToViewer(context, imagePath, jsonPath),
            child: Card(
              child: SizedBox(
                height: cardHeight,
                child: Image.asset(imageFiles[index], fit: BoxFit.fitWidth),
              ),
            ),
          );
        },
      ),
    );
  }


// This function wraps the navigation logic, including async scale factor calculation
  void navigateToViewer(BuildContext context, String imagePath, String jsonPath) async {
    double newScaleFactor = await calculateScaleFactor(context, imagePath);
    setState(() {
      scaleFactor = newScaleFactor;
    });
    _navigateAndDisplayImage(context, imagePath, jsonPath);
  }



  bool isPointInPolygon(Offset point, List<Offset> polygon) {
    bool isInside = false;
    int n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }
}

class InteractivePolygonPainter extends CustomPainter {
  final List<List<Offset>> polygons;
  final Set<int> clickedPolygons;
  final List<PolygonRoomData> polygonRoomData; // Added to hold room data
  final double scaleFactor;

  InteractivePolygonPainter(this.polygons, this.clickedPolygons, this.polygonRoomData, this.scaleFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill;

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < polygons.length; i++) {
      final path = Path()..addPolygon(polygons[i], true);
      if (clickedPolygons.contains(i)) {
        paint.color = Colors.red.withOpacity(0.5);
      } else {
        paint.color = polygonRoomData[i].roomInfo.isNotEmpty ? Colors.grey.withOpacity(0.5) : Colors.transparent;
      }
      canvas.drawPath(path, paint);

      if (polygonRoomData[i].roomInfo.isNotEmpty) {
        // Calculate centroid
        final Offset centroid = _calculateCentroid(polygons[i]);
        // Draw room code text
        final String roomCode = polygonRoomData[i].roomInfo['Room Code'] ?? '';
        textPainter.text = TextSpan(text: roomCode, style: const TextStyle(color: Colors.black, fontSize: 12));
        textPainter.layout();
        textPainter.paint(canvas, centroid - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }
  }

  // Method to calculate the centroid of a polygon
  Offset _calculateCentroid(List<Offset> points) {
    double x = 0.0, y = 0.0;
    for (var point in points) {
      x += point.dx;
      y += point.dy;
    }
    return Offset(x / points.length, y / points.length);
  }

  @override
  bool shouldRepaint(covariant InteractivePolygonPainter oldDelegate) {
    return oldDelegate.scaleFactor != scaleFactor || oldDelegate.clickedPolygons != clickedPolygons;
  }
}
