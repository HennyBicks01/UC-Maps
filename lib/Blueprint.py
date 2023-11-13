import os

def list_png_files_in_directory(directory):
    """List all PNG files in a given directory."""
    return [file for file in os.listdir(directory) if file.endswith('.png')]

def generate_blueprint_dart_code(buildings_directory):
    """Generate the Dart code for the Blueprint widget."""
    dart_code = """
import 'package:flutter/material.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getImageFilePaths() {
    switch(buildingName) {
"""

    for building in os.listdir(buildings_directory):
        building_path = os.path.join(buildings_directory, building)
        if os.path.isdir(building_path):
            png_files = list_png_files_in_directory(building_path)
            dart_code += f"      case '{building}':\n        return [\n"
            for png in png_files:
                dart_code += f"          'Blueprints/{building}/{png}',\n"
            dart_code += "        ];\n"

    dart_code += """
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageFiles = getImageFilePaths();

    return Scaffold(
      appBar: AppBar(title: Text(buildingName)),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: imageFiles.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImage(context, imageFiles[index]),
            child: Card(
              child: Center(
                child: Image.asset(imageFiles[index]), // Display the PNG image
              ),
            ),
          );
        },
      ),
    );
  }

  void _openImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageFullScreenPage(imagePath: imagePath),
      ),
    );
  }
}

class ImageFullScreenPage extends StatelessWidget {
  final String imagePath;

  ImageFullScreenPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full-Screen Image View'),
      ),
      body: Center(
        child: Image.asset(imagePath), // Display the PNG image in full screen
      ),
    );
  }
}
"""
    return dart_code

def main():
    # Replace 'Blueprints' with the path to your buildings directory
    buildings_directory = 'Blueprints'
    dart_code = generate_blueprint_dart_code(buildings_directory)

    # Writing to blueprint.dart file in lib directory
    with open('lib/blueprint.dart', 'w') as file:
        file.write(dart_code)
    print("Blueprint Dart file generated successfully.")

if __name__ == "__main__":
    main()
