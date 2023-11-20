import os

def list_svg_files_in_directory(directory):
    """List all SVG files in a given directory."""
    return [file for file in os.listdir(directory) if file.endswith('.svg')]

def generate_blueprint_dart_code(buildings_directory):
    """Generate the Dart code for the Blueprint widget."""
    dart_code = """
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getSvgFilePaths() {
    switch(buildingName) {
"""

    for building in os.listdir(buildings_directory):
        building_path = os.path.join(buildings_directory, building)
        if os.path.isdir(building_path):
            svg_files = list_svg_files_in_directory(building_path)
            dart_code += f"      case '{building}':\n        return [\n"
            for svg in svg_files:
                dart_code += f"          'Blueprints/{building}/{svg}',\n"
            dart_code += "        ];\n"

    dart_code += """
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> svgFiles = getSvgFilePaths();

    return Scaffold(
      appBar: AppBar(title: Text(buildingName)),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: svgFiles.length,
        itemBuilder: (context, index) {
          return Card(
            child: Center(
              child: SvgPicture.asset(svgFiles[index], // Use SvgPicture widget
                semanticsLabel: 'SVG Image'), 
            ),
          );
        },
      ),
    );
  }
}
"""
    return dart_code

def main():
    buildings_directory = 'Blueprints'  # Replace with your buildings directory path
    dart_code = generate_blueprint_dart_code(buildings_directory)

    with open('lib/blueprint.dart', 'w') as file:
        file.write(dart_code)
    print("Blueprint Dart file generated successfully.")

if __name__ == "__main__":
    main()
