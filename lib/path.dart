import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullScreenImagePage({Key? key, required this.imagePath}) : super(key: key);

  Future<List<Widget>> _loadInteractiveAreas(String jsonPath) async {
    final String jsonString = await rootBundle.loadString(jsonPath);
    final List<dynamic> jsonData = json.decode(jsonString);
    List<Widget> widgets = [];

    for (var area in jsonData) {
      widgets.add(
        Positioned(
          left: area['x'].toDouble(),
          top: area['y'].toDouble(),
          child: GestureDetector(
            onTap: () {
              // Handle the tap, maybe show a dialog or navigate
              print('Tapped ${area['type']}');
            },
            child: Container(
              width: area['width'].toDouble(),
              height: area['height'].toDouble(),
              decoration: BoxDecoration(
                color: Colors.redAccent, // Make this transparent or adjust based on 'type'
                border: Border.all(color: Colors.red), // Optional, for visual debugging
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // Convert imagePath to jsonPath by replacing folder and extension
    final String jsonPath = imagePath
        .replaceFirst('Blueprints', 'BlueprintMaps')
        .replaceFirst(RegExp(r'\.png$'), '.json');

    return Scaffold(
      appBar: AppBar(
        title: Text('Floor Plan'),
      ),
      body: FutureBuilder<List<Widget>>(
        future: _loadInteractiveAreas(jsonPath),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                ...snapshot.data!,
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading interactive areas'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
