import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  String? closestBuilding;
  LatLng? closestBuildingLatLng;
  LatLng? closestLatLng;
  final MapController mapController = MapController();
  bool isLogging = false;
  List<LatLng> loggingPoints = [];
  String? buildingName;

  void launchUrl(Uri url) async {
    final String urlString = url.toString();
    if (await canLaunch(urlString)) {
      await launch(urlString);
    } else {
      throw 'Could not launch $urlString';
    }
  }

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<void> startLogging() async {
    String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text("Enter Building Name"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Building Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
    setState(() {
      isLogging = true;
      buildingName = name;
    });
  }

  void showLoggingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: loggingPoints.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(
                          "Point ${index + 1}: (${loggingPoints[index].latitude}, ${loggingPoints[index].longitude})"),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void stopLogging() async {
    if (buildingName != null) {
      String data = "Building: $buildingName\n";
      for (LatLng point in loggingPoints) {
        data += "${point.latitude},${point.longitude}\n";
      }

      // Convert the data string to Uint8List
      final bytes = Uint8List.fromList(utf8.encode(data));

      // Create a blob from the Uint8List
      final blob = html.Blob([bytes]);

      // Generate a URL for the blob
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create a link (a) element, and set its href to the blob URL
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..download = '$buildingName.txt';

      // Add the anchor to the DOM
      html.document.body!.append(anchor);

      // Simulate a click on the link to initiate the download
      anchor.click();

      // Remove the anchor from the DOM
      anchor.remove();

      // Clean up: revoke the object URL after use to free resources
      html.Url.revokeObjectUrl(url);

      setState(() {
        isLogging = false;
        loggingPoints.clear();
      });
    }
  }

  double zoom = 17.0;  // Initial zoom level

  void zoomIn() {
    setState(() {
      zoom += 1;
      mapController.move(mapController.center, zoom);
    });
  }

  void zoomOut() {
    setState(() {
      zoom -= 1;
      mapController.move(mapController.center, zoom);
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
              initialCenter: const LatLng(39.1317, -84.5167),
              initialZoom: zoom,
                onTap: (tapDetails, LatLng latlng) {
                  if (isLogging) {
                    setState(() {
                      loggingPoints.add(latlng);
                    });
                  }
                  print("const Latlng:(${latlng.latitude}, ${latlng.longitude})");
                }

            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: loggingPoints,
                    color: Colors.red.withOpacity(0.3),
                    borderColor: Colors.red,
                    isFilled: true,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: zoomIn,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,  // Background color
                    onPrimary: Colors.white,  // Text color
                  ),
                  child: const Text("+"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: zoomOut,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,  // Background color
                    onPrimary: Colors.white,  // Text color
                  ),
                  child: const Text("-"),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 50,  // Adjust as needed
            right: 30,   // Adjust as needed
            top: 50,     // Adjust as needed
            width: MediaQuery.of(context).size.width * 0.25, // 25% of screen width
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10.0,
                    spreadRadius: 1.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (buildingName != null) Text(
                    "Building: $buildingName",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, backgroundColor: Colors.red, // Text color
                        ),
                        onPressed: isLogging ? null : startLogging,
                        child: const Text("Start Logging"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black, backgroundColor: Colors.red, // Text color
                        ),
                        onPressed: isLogging ? stopLogging : null,
                        child: const Text("Stop Logging"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: loggingPoints.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(
                              "Point ${index + 1}: (${loggingPoints[index].latitude}, ${loggingPoints[index].longitude})"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}







