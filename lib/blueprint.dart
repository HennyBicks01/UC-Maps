import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'json.dart';
import 'png.dart';
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
  ValueNotifier<List<String>> unaccountedRoomCodes = ValueNotifier<List<String>>([]);
  List<Map<String, dynamic>> roomData = [];

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
    // Use function from json.dart
    return getbuildingJsonPathFilePaths(widget.buildingName);
  }

  List<String> getImageFilePaths() {
    // Use function from png.dart
    return getbuildingImagePathFilePaths(widget.buildingName);
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

  Future<List<Map<String, dynamic>>> loadRoomData(String jsonPath) async {
    // Replace 'BlueprintMaps' with 'RoomData' in the jsonPath
    String adjustedJsonPath = jsonPath.replaceAll('BlueprintMaps', 'RoomData');

    final jsonString = await rootBundle.loadString(adjustedJsonPath);
    final List<dynamic> jsonData = json.decode(jsonString);

    return List<Map<String, dynamic>>.from(jsonData);
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

  Set<String> extractRoomCodesFromPolygons(List<PolygonRoomData> polygons) {
    Set<String> polygonRoomCodes = {};
    for (PolygonRoomData polygon in polygons) {
      String? roomCode = polygon.roomInfo['Room Code'];
      if (roomCode != null) {
        polygonRoomCodes.add(roomCode);
        //print(roomCode);
      } else {
        //print("Missing 'Room Code' for a polygon"); // For debugging
      }
    }
    return polygonRoomCodes;
  }

  findUnaccountedRoomCodes(List<Map<String, dynamic>> roomData, List<PolygonRoomData> polygons) {
    Set<String> polygonRoomCodes = extractRoomCodesFromPolygons(polygons);


    for (var room in roomData) {
      if (!polygonRoomCodes.contains(room['Room Code'])) {
        // Concatenate Room Code and Description, and add to the list
        String roomCode = room['Room Code'] as String; // Assuming 'Description' is the key for room description
        unaccountedRoomCodes.value.add(roomCode);
      }
    }

    Set<String> newset = unaccountedRoomCodes.value.toSet();
    Set<String> unaccountedRoomCodesSet = newset.difference(polygonRoomCodes);


    unaccountedRoomCodes.value = unaccountedRoomCodesSet.toList();
  }



  void addRoomInfo(int polygonIndex, Map<String, dynamic> roomInfo) {
    if (polygonIndex >= 0 && polygonIndex < polygons.length) {
      polygons[polygonIndex].roomInfo = roomInfo; // Replace or modify room info as needed
      setState(() {}); // Trigger a rebuild to reflect changes
    }
  }

  void deleteRoomInfo(int polygonIndex) {
    if (polygonIndex >= 0 && polygonIndex < polygons.length) {
      polygons[polygonIndex].roomInfo.clear(); // Clear room info
      setState(() {}); // Trigger a rebuild to reflect changes
    }
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

  void addAlias(PolygonRoomData polygonData, String alias) {
    List<String> aliases = polygonData.roomInfo['Aliases'] as List<String>? ?? [];
    aliases.add(alias);
    polygonData.roomInfo['Aliases'] = aliases; // Correctly reassign the list
    if(unaccountedRoomCodes.value.contains(alias)){
      unaccountedRoomCodes.value.remove(alias);
    }
    setState(() {}); // Update the state if necessary
  }

 void _showRoomDataOrInputDialog(BuildContext context, int polygonIndex, List<PolygonRoomData> currentPolygons, String imagePath) {
    if (polygonIndex < 0 || polygonIndex >= currentPolygons.length) {
      return; // Early return if index is invalid
    }

    Map<String, dynamic> roomInfo = currentPolygons[polygonIndex].roomInfo;
    bool hasRoomData = roomInfo.isNotEmpty;
    String roomCode = roomInfo['Room Code'] ?? ''; // Default to an empty string if no room code is available
    List<String> aliases = List<String>.from(roomInfo['Aliases'] ?? []);
    TextEditingController inputController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


    // Handle submitting new room information
    void handleSubmitRoomInfo() {
      if (inputController.text.isNotEmpty && !hasRoomData) {
        addRoomInfo(polygonIndex, {"Room Code": inputController.text});
        Navigator.of(context).pop();
      }
    }

    // Function to handle adding alias without closing the dialog
    void handleAddAlias() {
      if (inputController.text.isNotEmpty && hasRoomData) {
        addAlias(currentPolygons[polygonIndex], inputController.text);
        Navigator.of(context).pop(); // This closes the dialog

        // Reopen the dialog with updated information
        Future.delayed(Duration.zero, () {
          _showRoomDataOrInputDialog(context, polygonIndex, currentPolygons, imagePath);
        });
      }
    }

    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        // No need for a custom transition in pageBuilder for this use case.
        return SizedBox.shrink(); // Placeholder, actual dialog content is handled in transitionBuilder
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 50),
      transitionBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        final curvedValue = Curves.easeInOut.transform(animation.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0, curvedValue * 200, 0),
          child: Opacity(
            opacity: animation.value,
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: AlertDialog(
                    title: Text(hasRoomData ? "Room: $roomCode" : "New Room"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: inputController,
                              decoration: InputDecoration(hintText: hasRoomData ? "Add Alias" : "Room Code"),
                              autofocus: true,
                              onFieldSubmitted: (_) => hasRoomData ? handleAddAlias() : handleSubmitRoomInfo(),
                            ),
                          ),
                          if (hasRoomData)
                            Text('Aliases: ${aliases.join(', ')}', style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      if (hasRoomData) TextButton(
                        onPressed: () {
                          deleteRoomInfo(polygonIndex);
                          Navigator.of(context).pop();
                        },
                        child: const Text("Delete Room Data"),
                      ),
                      if (!hasRoomData) TextButton(
                        onPressed: () {
                          handleSubmitRoomInfo();
                        },
                        child: const Text("Submit Room Info"),
                      ),
                      if (hasRoomData) TextButton(
                        onPressed: () => handleAddAlias(),
                        child: const Text("Add Alias"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Clear the clicked polygons after the dialog is closed
      setState(() {
        clickedPolygons.value = {};
        findUnaccountedRoomCodes(roomData, polygons);
      });
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

  Future<void> _downloadFile(List<PolygonRoomData> jsonData, String fileName) async {
    final String jsonString = jsonEncode(jsonData);
    final String uri = Uri.encodeComponent(jsonString);
    AnchorElement(href: 'data:application/json;charset=utf-8,$uri')
      ..setAttribute("download", fileName)
      ..click();
  }

  void _navigateAndDisplayImage(BuildContext context, String imagePath) async {
    // Dynamically load the JSON for the selected blueprint
    String fileNameWithoutExtension = imagePath.split('/').last.split('.').first;

    String jsonPath = imagePath.replaceAll('Blueprints', 'RoomData').replaceAll('.png', '.json');
    List<Map<String, dynamic>> roomData = await loadRoomData(jsonPath);
    findUnaccountedRoomCodes(roomData, polygons);

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
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () => _downloadFile(polygons, fileNameWithoutExtension ),
              ),
            ],
          ),
          body: Row( // Use Row to layout the InteractiveViewer and the new Card side by side
            children: [
              Expanded( // InteractiveViewer wrapped in Expanded to take up most of the Row
                flex: 5, // Adjust the flex ratio to give more space to the InteractiveViewer
                child: InteractiveViewer(
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
                              _showRoomDataOrInputDialog(context, polygonIndex, polygons, imagePath); // Use polygons here
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
              Container(
                width: 200,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ValueListenableBuilder<List<String>>(
                      valueListenable: unaccountedRoomCodes,
                      builder: (context, value, child) {
                        return ListView(
                          children: value.map((code) => Text(code)).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
        paint.color =  polygonRoomData[i].roomInfo.isNotEmpty ? Colors.grey.withOpacity(0.5) : Colors.transparent;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractivePolygonPainter oldDelegate) {
    return oldDelegate.scaleFactor != scaleFactor || oldDelegate.clickedPolygons != clickedPolygons;
  }
}
