import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getSvgFilePaths() {
    switch(buildingName) {
      case 'TUC':
        return [
          'assets/Blueprints/TUC/TUC-01.svg',
          'assets/Blueprints/TUC/TUC-02.svg',
          'assets/Blueprints/TUC/TUC-03.svg',
          'assets/Blueprints/TUC/TUC-04.svg',
        ];

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
        String svgPath = svgFiles[index];
        String appBarTitle = "$buildingName - Floor $floorNumber";

        return InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(appBarTitle)),
                  body: Center(
                    child: InteractiveViewer(
                      boundaryMargin: EdgeInsets.all(20),
                      minScale: 0.1,
                      maxScale: 4.0,
                      child: SvgPicture.asset(svgPath, semanticsLabel: 'A floor plan'),
                    ),
                  ),
                ),
              ));
            },
            child: Card(
            child: SizedBox(
              height: cardHeight,
              child: Stack(
                children: [
                  ClipRect(  // Clip the SVG to fit the card
                    child: Align(
                      alignment: Alignment.center,
                      heightFactor: 1,  // Adjust this factor to control vertical cropping
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
          )
        );
      },
    ),
  );
}
}
