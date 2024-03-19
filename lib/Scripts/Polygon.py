import os

def process_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    building_name = lines[0].strip().split(':')[1].strip()
    coordinates = [line.strip() for line in lines[1:]]

    # Set a specific shade of red
    red_shade = 'Color.fromRGBO(224, 1, 34, 1)'  # Your specific red color
    darker_red_shade = 'Color.fromRGBO(184, 1, 28, 1)'  # A darker shade for the outline

    polygon_data = ',\n'.join([f'        LatLng({coord})' for coord in coordinates])
    polygon_layer = f'''PolygonData(
      name: '{building_name}',
      polygon: Polygon(
          points: const [
{polygon_data}
          ],
          color: const {red_shade},
          borderColor: const {darker_red_shade},
          borderStrokeWidth: 2.0,
          isFilled: true,
      )
  )'''
    return polygon_layer
def main(directory):
    polygon_layers = []

    for file in os.listdir(directory):
        if file.endswith('.txt'):
            polygon_layer = process_file(os.path.join(directory, file))
            polygon_layers.append(polygon_layer)

    dart_content = ("import 'package:flutter/material.dart';\n"
                    "import 'package:flutter_map/flutter_map.dart';\n"
                    "import 'package:latlong2/latlong.dart';\n\n"
                    "class PolygonData {\n"
                    "  final String name;\n"
                    "  final Polygon polygon;\n\n"
                    "  PolygonData({required this.name, required this.polygon});\n"
                    "}\n\n"
                    "List<PolygonData> getPolygons() {\n  return [\n    "
                    + ',\n    '.join(polygon_layers) +
                    "\n  ];\n}")

    os.makedirs('lib', exist_ok=True)
    with open('lib/polygon.dart', 'w') as outfile:
        outfile.write(dart_content)

if __name__ == "__main__":
    main("assets/Geofencing")  # Replace "Geofencing" with your directory path
