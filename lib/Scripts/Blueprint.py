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
                dart_code += f"          'assets/Blueprints/{building}/{svg}',\n"
            dart_code += "        ];\n"

    dart_code += """
      default:
        return [];
    }
  }

@override
Widget build(BuildContext context) {
  List<String> svgFiles = getSvgFilePaths();
  double cardHeight = MediaQuery.of(context).size.height / 5;

  return Scaffold(
    appBar: AppBar(title: Text(buildingName)),
    body: ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: svgFiles.length,
      itemBuilder: (context, index) {
        String floorNumber = 'Unknown';
        if (svgFiles[index].contains('-')) {
          List<String> parts = svgFiles[index].split('-');
          if (parts.length > 1) {
            floorNumber = parts[1].split('.')[0];  // Assuming the format is 'TUC-01.svg'
          }
        }

        return Card(
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              children: [
                ClipRect(  // Clip the SVG to fit the card
                  child: Align(
                    alignment: Alignment.center,
                    heightFactor: 0.5,  // Adjust this factor to control vertical cropping
                    child: SvgPicture.asset(svgFiles[index],
                      semanticsLabel: 'A floor plan',
                      fit: BoxFit.fitWidth),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Text(
                    '$floorNumber',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
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
    buildings_directory = 'assets/Blueprints'  # Replace with your buildings directory path
    dart_code = generate_blueprint_dart_code(buildings_directory)

    with open('lib/blueprint.dart', 'w') as file:
        file.write(dart_code)
    print("Blueprint Dart file generated successfully.")

if __name__ == "__main__":
    main()
