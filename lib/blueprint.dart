
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getSvgFilePaths() {
    switch(buildingName) {
      case '60 West Charleton':
        return [
          'Blueprints/60 West Charleton/60WCHARL-01.svg',
          'Blueprints/60 West Charleton/60WCHARL-02.svg',
          'Blueprints/60 West Charleton/60WCHARL-B.svg',
        ];
      case 'ARMORY':
        return [
          'Blueprints/ARMORY/ARMORY-01.svg',
          'Blueprints/ARMORY/ARMORY-02.svg',
        ];
      case 'ARONOFF':
        return [
          'Blueprints/ARONOFF/ARONOFF-03.svg',
          'Blueprints/ARONOFF/ARONOFF-04.svg',
          'Blueprints/ARONOFF/ARONOFF-05.svg',
          'Blueprints/ARONOFF/ARONOFF-06.svg',
        ];
      case 'Blegen Library':
        return [
          'Blueprints/Blegen Library/BLEGEN-02.svg',
          'Blueprints/Blegen Library/BLEGEN-03.svg',
          'Blueprints/Blegen Library/BLEGEN-04.svg',
          'Blueprints/Blegen Library/BLEGEN-06.svg',
          'Blueprints/Blegen Library/BLEGEN-08.svg',
        ];
      case 'Braunstein Hall':
        return [
          'Blueprints/Braunstein Hall/BRAUNSTN-01.svg',
          'Blueprints/Braunstein Hall/BRAUNSTN-02.svg',
          'Blueprints/Braunstein Hall/BRAUNSTN-03.svg',
          'Blueprints/Braunstein Hall/BRAUNSTN-04.svg',
        ];
      case 'CALHONGR':
        return [
          'Blueprints/CALHONGR/CALHONGR-P1.svg',
          'Blueprints/CALHONGR/CALHONGR-P2.svg',
          'Blueprints/CALHONGR/CALHONGR-P4.svg',
        ];
      case 'CCM':
        return [
        ];
      case 'CLIFTCT':
        return [
          'Blueprints/CLIFTCT/CLIFTCT-01.svg',
          'Blueprints/CLIFTCT/CLIFTCT-02.svg',
          'Blueprints/CLIFTCT/CLIFTCT-03.svg',
          'Blueprints/CLIFTCT/CLIFTCT-04.svg',
          'Blueprints/CLIFTCT/CLIFTCT-05.svg',
        ];
      case 'College of Law':
        return [
          'Blueprints/College of Law/COLLAW-01.svg',
          'Blueprints/College of Law/COLLAW-02.svg',
          'Blueprints/College of Law/COLLAW-03.svg',
          'Blueprints/College of Law/COLLAW-04.svg',
          'Blueprints/College of Law/COLLAW-05.svg',
          'Blueprints/College of Law/COLLAW-06.svg',
          'Blueprints/College of Law/COLLAW-B.svg',
        ];
      case 'COMMONSN-S':
        return [
        ];
      case 'Crosley Tower':
        return [
          'Blueprints/Crosley Tower/CROSLEY-01.svg',
          'Blueprints/Crosley Tower/CROSLEY-02.svg',
          'Blueprints/Crosley Tower/CROSLEY-03.svg',
          'Blueprints/Crosley Tower/CROSLEY-04.svg',
          'Blueprints/Crosley Tower/CROSLEY-05.svg',
          'Blueprints/Crosley Tower/CROSLEY-06.svg',
          'Blueprints/Crosley Tower/CROSLEY-07.svg',
          'Blueprints/Crosley Tower/CROSLEY-08.svg',
          'Blueprints/Crosley Tower/CROSLEY-09.svg',
          'Blueprints/Crosley Tower/CROSLEY-10.svg',
          'Blueprints/Crosley Tower/CROSLEY-11.svg',
          'Blueprints/Crosley Tower/CROSLEY-12.svg',
          'Blueprints/Crosley Tower/CROSLEY-13.svg',
          'Blueprints/Crosley Tower/CROSLEY-14.svg',
          'Blueprints/Crosley Tower/CROSLEY-15.svg',
          'Blueprints/Crosley Tower/CROSLEY-16.svg',
        ];
      case 'DAAP':
        return [
          'Blueprints/DAAP/DAAP-05.svg',
          'Blueprints/DAAP/DAAP-06.svg',
          'Blueprints/DAAP/DAAP-07.svg',
          'Blueprints/DAAP/DAAP-08.svg',
        ];
      case 'DIETERLE':
        return [
          'Blueprints/DIETERLE/DIETERLE-02.svg',
          'Blueprints/DIETERLE/DIETERLE-03.svg',
        ];
      case 'Edwards Center':
        return [
          'Blueprints/Edwards Center/EDWARDS-01.svg',
          'Blueprints/Edwards Center/EDWARDS-02.svg',
          'Blueprints/Edwards Center/EDWARDS-03.svg',
          'Blueprints/Edwards Center/EDWARDS-04.svg',
          'Blueprints/Edwards Center/EDWARDS-05.svg',
          'Blueprints/Edwards Center/EDWARDS-06.svg',
          'Blueprints/Edwards Center/EDWARDS-07.svg',
        ];
      case 'FRENCH-W_':
        return [
          'Blueprints/FRENCH-W_/FRENCH-W-01.svg',
          'Blueprints/FRENCH-W_/FRENCH-W-02.svg',
          'Blueprints/FRENCH-W_/FRENCH-W-03.svg',
          'Blueprints/FRENCH-W_/FRENCH-W-04.svg',
          'Blueprints/FRENCH-W_/FRENCH-W-05.svg',
          'Blueprints/FRENCH-W_/FRENCH-W-06.svg',
        ];
      case 'Geology Physics Building':
        return [
          'Blueprints/Geology Physics Building/GEOPHYS-01.svg',
          'Blueprints/Geology Physics Building/GEOPHYS-02.svg',
          'Blueprints/Geology Physics Building/GEOPHYS-03.svg',
          'Blueprints/Geology Physics Building/GEOPHYS-04.svg',
          'Blueprints/Geology Physics Building/GEOPHYS-05.svg',
          'Blueprints/Geology Physics Building/GEOPHYS-06.svg',
        ];
      case 'LANGSAM':
        return [
          'Blueprints/LANGSAM/LANGSAM-04.svg',
          'Blueprints/LANGSAM/LANGSAM-05.svg',
          'Blueprints/LANGSAM/LANGSAM-06.svg',
        ];
      case 'Lindner Hall':
        return [
          'Blueprints/Lindner Hall/LINDHALL-00.svg',
          'Blueprints/Lindner Hall/LINDHALL-01.svg',
          'Blueprints/Lindner Hall/LINDHALL-02.svg',
          'Blueprints/Lindner Hall/LINDHALL-03.svg',
          'Blueprints/Lindner Hall/LINDHALL-04.svg',
        ];
      case 'LNDNRCTR':
        return [
          'Blueprints/LNDNRCTR/LNDNRCTR-01.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-02.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-03.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-04.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-05.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-06.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-07.svg',
          'Blueprints/LNDNRCTR/LNDNRCTR-08.svg',
        ];
      case 'Mantei Center':
        return [
          'Blueprints/Mantei Center/MANTEI-03.svg',
          'Blueprints/Mantei Center/MANTEI-04.svg',
          'Blueprints/Mantei Center/MANTEI-05.svg',
          'Blueprints/Mantei Center/MANTEI-06.svg',
          'Blueprints/Mantei Center/MANTEI-07.svg',
          'Blueprints/Mantei Center/MANTEI-08.svg',
        ];
      case 'Marketpointe':
        return [
          'Blueprints/Marketpointe/MARKETPT-01.svg',
        ];
      case 'McMicken Hall':
        return [
          'Blueprints/McMicken Hall/ARTSCI-00.svg',
          'Blueprints/McMicken Hall/ARTSCI-01.svg',
          'Blueprints/McMicken Hall/ARTSCI-02.svg',
          'Blueprints/McMicken Hall/ARTSCI-03.svg',
        ];
      case 'MSPENCER':
        return [
          'Blueprints/MSPENCER/MSPENCER-G.svg',
        ];
      case 'NIPPERT':
        return [
          'Blueprints/NIPPERT/NIPPERT-01.svg',
          'Blueprints/NIPPERT/NIPPERT-02.svg',
          'Blueprints/NIPPERT/NIPPERT-03.svg',
          'Blueprints/NIPPERT/NIPPERT-03M.svg',
          'Blueprints/NIPPERT/NIPPERT-04.svg',
          'Blueprints/NIPPERT/NIPPERT-05.svg',
        ];
      case 'RECCENTR':
        return [
          'Blueprints/RECCENTR/RECCENTR-00.svg',
          'Blueprints/RECCENTR/RECCENTR-00M.svg',
          'Blueprints/RECCENTR/RECCENTR-01.svg',
          'Blueprints/RECCENTR/RECCENTR-02.svg',
          'Blueprints/RECCENTR/RECCENTR-03.svg',
        ];
      case 'RHODES':
        return [
          'Blueprints/RHODES/RHODES-03.svg',
          'Blueprints/RHODES/RHODES-04.svg',
          'Blueprints/RHODES/RHODES-05.svg',
          'Blueprints/RHODES/RHODES-06.svg',
          'Blueprints/RHODES/RHODES-07.svg',
          'Blueprints/RHODES/RHODES-08.svg',
          'Blueprints/RHODES/RHODES-09.svg',
        ];
      case 'Rieveschl Hall':
        return [
          'Blueprints/Rieveschl Hall/RIEVSCHL-04.svg',
          'Blueprints/Rieveschl Hall/RIEVSCHL-05.svg',
          'Blueprints/Rieveschl Hall/RIEVSCHL-06.svg',
          'Blueprints/Rieveschl Hall/RIEVSCHL-07.svg',
          'Blueprints/Rieveschl Hall/RIEVSCHL-08.svg',
        ];
      case 'SHOE':
        return [
          'Blueprints/SHOE/SHOE-04.svg',
          'Blueprints/SHOE/SHOE-04M.svg',
          'Blueprints/SHOE/SHOE-05.svg',
        ];
      case 'STEGER':
        return [
          'Blueprints/STEGER/STEGER-04.svg',
          'Blueprints/STEGER/STEGER-05.svg',
          'Blueprints/STEGER/STEGER-06.svg',
          'Blueprints/STEGER/STEGER-07.svg',
          'Blueprints/STEGER/STEGER-08.svg',
        ];
      case 'Swift Hall':
        return [
          'Blueprints/Swift Hall/SWIFT-05.svg',
          'Blueprints/Swift Hall/SWIFT-06.svg',
          'Blueprints/Swift Hall/SWIFT-07.svg',
          'Blueprints/Swift Hall/SWIFT-08.svg',
        ];
      case 'Taft Hall':
        return [
          'Blueprints/Taft Hall/2540CLIF-01.svg',
          'Blueprints/Taft Hall/2540CLIF-02.svg',
          'Blueprints/Taft Hall/2540CLIF-03.svg',
          'Blueprints/Taft Hall/2540CLIF-04.svg',
        ];
      case 'TEACHERS':
        return [
          'Blueprints/TEACHERS/TEACHERS-01.svg',
          'Blueprints/TEACHERS/TEACHERS-02.svg',
          'Blueprints/TEACHERS/TEACHERS-03.svg',
          'Blueprints/TEACHERS/TEACHERS-04.svg',
          'Blueprints/TEACHERS/TEACHERS-05.svg',
          'Blueprints/TEACHERS/TEACHERS-06.svg',
        ];
      case 'TUC':
        return [
          'Blueprints/TUC/TUC-01.svg',
          'Blueprints/TUC/TUC-02.svg',
          'Blueprints/TUC/TUC-03.svg',
          'Blueprints/TUC/TUC-04.svg',
        ];
      case 'UNIVPAV':
        return [
          'Blueprints/UNIVPAV/UNIVPAV-01.svg',
          'Blueprints/UNIVPAV/UNIVPAV-02.svg',
          'Blueprints/UNIVPAV/UNIVPAV-03.svg',
          'Blueprints/UNIVPAV/UNIVPAV-04.svg',
          'Blueprints/UNIVPAV/UNIVPAV-05.svg',
          'Blueprints/UNIVPAV/UNIVPAV-06.svg',
        ];
      case 'Van Wormer Hall':
        return [
          'Blueprints/Van Wormer Hall/VANWORMR-01.svg',
          'Blueprints/Van Wormer Hall/VANWORMR-02.svg',
          'Blueprints/Van Wormer Hall/VANWORMR-03.svg',
        ];
      case 'VVB':
        return [
          'Blueprints/VVB/VVB-02.svg',
        ];
      case 'WOLFSON':
        return [
          'Blueprints/WOLFSON/WOLFSON-03.svg',
          'Blueprints/WOLFSON/WOLFSON-04.svg',
          'Blueprints/WOLFSON/WOLFSON-05.svg',
          'Blueprints/WOLFSON/WOLFSON-06.svg',
        ];
      case 'ZIMMER':
        return [
          'Blueprints/ZIMMER/ZIMMER-04.svg',
        ];

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
