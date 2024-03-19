import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

class BlueprintState extends State<Blueprint> with WidgetsBindingObserver {
  ValueNotifier<Set<int>> clickedPolygons = ValueNotifier({});
  List<PolygonRoomData> polygons = [];
  double scaleFactor = 1.0;
  OverlayEntry? _overlayEntry;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSearchFocusNodeListener(); // Initialize the focus node listener

    // Add post frame callback tasks
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await updateScaleFactor();
      // Load initial JSON data or handle as necessary
    });

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) return;
    String searchQuery = _searchController.text.toLowerCase();

    // Filter polygons whose room code or description contains the search query
    Set<int> filteredPolygons = {};
    if (searchQuery.isNotEmpty) {
      for (int i = 0; i < polygons.length; i++) {
        String roomCode = polygons[i].roomInfo['Room Code']?.toLowerCase() ?? '';
        String description = polygons[i].roomInfo['Description']?.toLowerCase() ?? '';

        if (roomCode.contains(searchQuery) || description.contains(searchQuery)) {
          filteredPolygons.add(i);
        }
      }
    }

    setState(() {
      clickedPolygons.value = filteredPolygons;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged); // Remove listener on dispose
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _handleScreenSizeChange();
  }

  Future<void> _handleScreenSizeChange() async {
    if (getImageFilePaths().isNotEmpty) {
      String imagePath = getImageFilePaths().first;
      double newScaleFactor = await calculateScaleFactor(context, imagePath);
      setState(() {
        scaleFactor = newScaleFactor;
      });
    }
  }

  List<String> getJsonFilePaths() {
    Map<String, List<String>> buildingJsons = {
      'Teachers College': [
        'assets/BlueprintMaps/TEACHERS/TEACHERS-01.json',
        'assets/BlueprintMaps/TEACHERS/TEACHERS-02.json',
        'assets/BlueprintMaps/TEACHERS/TEACHERS-03.json',
        'assets/BlueprintMaps/TEACHERS/TEACHERS-04.json',
        'assets/BlueprintMaps/TEACHERS/TEACHERS-05.json',
        'assets/BlueprintMaps/TEACHERS/TEACHERS-06.json',
      ],
      // Add more buildings here
    };
    return buildingJsons[widget.buildingName] ?? [];
  }

  List<String> getImageFilePaths() {
    Map<String, List<String>> buildingImages = {
      'Teachers College': [
        'assets/Blueprints/TEACHERS/TEACHERS-01.png',
        'assets/Blueprints/TEACHERS/TEACHERS-02.png',
        'assets/Blueprints/TEACHERS/TEACHERS-03.png',
        'assets/Blueprints/TEACHERS/TEACHERS-04.png',
        'assets/Blueprints/TEACHERS/TEACHERS-05.png',
        'assets/Blueprints/TEACHERS/TEACHERS-06.png',
      ],
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

  void _showRoomDataOrInputDialog(BuildContext context, int polygonIndex, List<PolygonRoomData> currentPolygons) {
    if (polygonIndex < 0 || polygonIndex >= currentPolygons.length) {
      return; // Early return if index is invalid
    }

    // Replace the set's contents with the new polygon index
    Set<int> newClickedPolygons = {polygonIndex};
    clickedPolygons.value = newClickedPolygons;

    Map<String, String> roomInfo = currentPolygons[polygonIndex].roomInfo;
    String roomCode = roomInfo['Room Code'] ?? '';
    String departmentName = roomInfo['Department Name'] ?? 'Department not announced'; // Adjust the key as necessary
    String description = roomInfo['Description'] ?? ''; // Adjust the key as necessary

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Room: $roomCode", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                const Divider(),
                Text(departmentName, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.red.withOpacity(0.6))),
                Text(description, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
        );
      },
      isScrollControlled: true, // This allows the modal to only be as tall as its content
    ).then((_) {
      // Optionally clear the selection when the modal is closed
      clickedPolygons.value = {};
    });
  }

  void _setupSearchFocusNodeListener() {
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _showOverlay();
      } else {
        // Wait for 500ms before removing the overlay.
        Future.delayed(const Duration(milliseconds: 700), () {
          // Check if the focus has not moved back to the search bar or the overlay
          if (!_searchFocusNode.hasFocus) {
            _overlayEntry?.remove();
            _overlayEntry = null;
          }
        });
      }
    });
  }


  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {

    const double appBarHeight = 56.0; // Standard AppBar height. Adjust as necessary.
    const double topOffset = appBarHeight; // Position the overlay just below the AppBar.
    const double leftOffset = 80.0; // Start 80px in from the left edge of the screen.

    return OverlayEntry(
      builder: (context) => Positioned(
        left: leftOffset,
        top: topOffset,
        child: Material(
          color: Colors.white.withOpacity(0.6), // Set to light gray
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildSearchTermChip('Restroom'),
                  _buildSearchTermChip('Classroom'),
                  _buildSearchTermChip('Office'),
                  _buildSearchTermChip('Storage'),
                  _buildSearchTermChip('Electrical'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTermChip(String term) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(term),
        labelStyle: const TextStyle(color: Colors.black),
        backgroundColor: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: Colors.grey)),
        onPressed: () => _searchTermSelected(term),
      ),
    );
  }


  void _searchTermSelected(String term) {
    // You might need to adjust the logic based on your actual data structure.
    Set<int> matchingPolygons = {};
    for (int i = 0; i < polygons.length; i++) {
      if (polygons[i].roomInfo['Description']?.contains(term) ?? false) {
        matchingPolygons.add(i);
      }
    }
    setState(() {
      clickedPolygons.value = matchingPolygons;
    });
    _searchController.text = "";
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _navigateAndDisplayImage(BuildContext context, String imagePath) async {
    // Dynamically load the JSON for the selected blueprint
    String fileNameWithoutExtension = imagePath.split('/').last.split('.').first;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF424549),
            iconTheme: const IconThemeData(color: Colors.white),
            title: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: fileNameWithoutExtension,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            actions: const <Widget>[],
          ),
          body: InteractiveViewer(
            child: Builder(
              builder: (BuildContext innerContext) {
                return GestureDetector(
                  onTapUp: (TapUpDetails details) {
                    RenderBox box = innerContext.findRenderObject() as RenderBox;
                    final Offset localPosition = box.globalToLocal(details.globalPosition);
                    int polygonIndex = -1; // Initialize with an invalid index

                    for (int i = 0; i < polygons.length; i++) {
                      if (isPointInPolygon(localPosition, polygons[i].polygon.map((e) => Offset(e[0].toDouble() * scaleFactor, e[1].toDouble() * scaleFactor)).toList())) {
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
                      Future.delayed(const Duration(milliseconds: 200), () {
                        _showRoomDataOrInputDialog(context, polygonIndex, polygons); // Use polygons here
                      });
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
                              polygons.map((e) => e.polygon.map((p) => Offset(p[0] * scaleFactor, p[1] * scaleFactor)).toList()).toList(),
                              value,
                              polygons,
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


  // Example of dynamically loading JSON data based on the selected image/path
  void loadPolygonDataForSelectedImage(String imagePath) {
    String jsonPath = imagePath
        .replaceFirst('Blueprints', 'BlueprintMaps')
        .replaceFirst(RegExp(r'\.png$'), '.json');

    loadPolygonData(jsonPath, scaleFactor, scaleFactor);
  }
  // double cardHeight = MediaQuery.of(context).size.height / 5;


  @override
  Widget build(BuildContext context) {
    List<String> imageFiles = getImageFilePaths();
    Color discordGray = const Color(0xFF424549);// Discord gray color

    return Scaffold(
      appBar: AppBar(
        backgroundColor: discordGray,
        title: Text(widget.buildingName,  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF303336), // Make background darker
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: imageFiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: (300 / 200),
          ),
          itemBuilder: (context, index) {
            String imagePath = imageFiles[index];
            String fileName = imagePath.split('/').last;
            String floorNumber = fileName.length > 6 ? fileName.substring(fileName.length - 6, fileName.length - 4) : "N/A";

            return InkWell(
              onTap: () {
                // Clear the selected polygons by setting clickedPolygons to an empty set
                setState(() {
                  clickedPolygons.value = {};
                });
                // Navigate to the viewer
                navigateToViewer(context, imagePath);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0), // Curved corners
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2), // Tint color
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          "Floor - $floorNumber",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontSize: 25,
                            shadows: <Shadow>[
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  void navigateToViewer(BuildContext context, String imagePath) async {
    double newScaleFactor = await calculateScaleFactor(context, imagePath);
    setState(() {
      scaleFactor = newScaleFactor;
    });
    loadPolygonDataForSelectedImage(imagePath); // Adjusted to dynamically load JSON data
    _navigateAndDisplayImage(context, imagePath);
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

    for (int i = 0; i < polygons.length; i++) {
      final path = Path()..addPolygon(polygons[i], true);
      if (clickedPolygons.contains(i)) {
        paint.color = Colors.red.withOpacity(0.5);
      } else {
        paint.color = /* polygonRoomData[i].roomInfo.isNotEmpty ? Colors.grey.withOpacity(0.5) :*/ Colors.transparent;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractivePolygonPainter oldDelegate) {
    return oldDelegate.scaleFactor != scaleFactor || oldDelegate.clickedPolygons != clickedPolygons;
  }
}
