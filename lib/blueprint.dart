
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getSvgFilePaths() {
    switch(buildingName) {
      case '2540CLIF':
        return [
          'Blueprints/2540CLIF/2540CLIF-01.svg',
          'Blueprints/2540CLIF/2540CLIF-02.svg',
          'Blueprints/2540CLIF/2540CLIF-03.svg',
          'Blueprints/2540CLIF/2540CLIF-04.svg',
        ];
      case '60WCHARL':
        return [
          'Blueprints/60WCHARL/60WCHARL-01.svg',
          'Blueprints/60WCHARL/60WCHARL-02.svg',
          'Blueprints/60WCHARL/60WCHARL-B.svg',
        ];
      case 'ARMORY':
        return [
          'Blueprints/ARMORY/ARMORY-01.svg',
          'Blueprints/ARMORY/ARMORY-02.svg',
        ];
      case 'ARTSCI':
        return [
          'Blueprints/ARTSCI/ARTSCI-00.svg',
          'Blueprints/ARTSCI/ARTSCI-01.svg',
          'Blueprints/ARTSCI/ARTSCI-02.svg',
          'Blueprints/ARTSCI/ARTSCI-03.svg',
        ];
      case 'BLEGEN':
        return [
          'Blueprints/BLEGEN/BLEGEN-02.svg',
          'Blueprints/BLEGEN/BLEGEN-03.svg',
          'Blueprints/BLEGEN/BLEGEN-04.svg',
          'Blueprints/BLEGEN/BLEGEN-06.svg',
          'Blueprints/BLEGEN/BLEGEN-08.svg',
        ];
      case 'BRAUNSTN':
        return [
          'Blueprints/BRAUNSTN/BRAUNSTN-01.svg',
          'Blueprints/BRAUNSTN/BRAUNSTN-02.svg',
          'Blueprints/BRAUNSTN/BRAUNSTN-03.svg',
          'Blueprints/BRAUNSTN/BRAUNSTN-04.svg',
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
      case 'COLLAW':
        return [
          'Blueprints/COLLAW/COLLAW-01.svg',
          'Blueprints/COLLAW/COLLAW-02.svg',
          'Blueprints/COLLAW/COLLAW-03.svg',
          'Blueprints/COLLAW/COLLAW-04.svg',
          'Blueprints/COLLAW/COLLAW-05.svg',
          'Blueprints/COLLAW/COLLAW-06.svg',
          'Blueprints/COLLAW/COLLAW-B.svg',
        ];
      case 'COMMONSN-S':
        return [
        ];
      case 'CROSLEY':
        return [
          'Blueprints/CROSLEY/CROSLEY-01.svg',
          'Blueprints/CROSLEY/CROSLEY-02.svg',
          'Blueprints/CROSLEY/CROSLEY-03.svg',
          'Blueprints/CROSLEY/CROSLEY-04.svg',
          'Blueprints/CROSLEY/CROSLEY-05.svg',
          'Blueprints/CROSLEY/CROSLEY-06.svg',
          'Blueprints/CROSLEY/CROSLEY-07.svg',
          'Blueprints/CROSLEY/CROSLEY-08.svg',
          'Blueprints/CROSLEY/CROSLEY-09.svg',
          'Blueprints/CROSLEY/CROSLEY-10.svg',
          'Blueprints/CROSLEY/CROSLEY-11.svg',
          'Blueprints/CROSLEY/CROSLEY-12.svg',
          'Blueprints/CROSLEY/CROSLEY-13.svg',
          'Blueprints/CROSLEY/CROSLEY-14.svg',
          'Blueprints/CROSLEY/CROSLEY-15.svg',
          'Blueprints/CROSLEY/CROSLEY-16.svg',
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
      case 'EDWARDS':
        return [
          'Blueprints/EDWARDS/EDWARDS-01.svg',
          'Blueprints/EDWARDS/EDWARDS-02.svg',
          'Blueprints/EDWARDS/EDWARDS-03.svg',
          'Blueprints/EDWARDS/EDWARDS-04.svg',
          'Blueprints/EDWARDS/EDWARDS-05.svg',
          'Blueprints/EDWARDS/EDWARDS-06.svg',
          'Blueprints/EDWARDS/EDWARDS-07.svg',
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
      case 'GEOPHYS':
        return [
          'Blueprints/GEOPHYS/GEOPHYS-01.svg',
          'Blueprints/GEOPHYS/GEOPHYS-02.svg',
          'Blueprints/GEOPHYS/GEOPHYS-03.svg',
          'Blueprints/GEOPHYS/GEOPHYS-04.svg',
          'Blueprints/GEOPHYS/GEOPHYS-05.svg',
          'Blueprints/GEOPHYS/GEOPHYS-06.svg',
        ];
      case 'LANGSAM':
        return [
          'Blueprints/LANGSAM/LANGSAM-04.svg',
          'Blueprints/LANGSAM/LANGSAM-05.svg',
          'Blueprints/LANGSAM/LANGSAM-06.svg',
        ];
      case 'LINDHALL':
        return [
          'Blueprints/LINDHALL/LINDHALL-00.svg',
          'Blueprints/LINDHALL/LINDHALL-01.svg',
          'Blueprints/LINDHALL/LINDHALL-02.svg',
          'Blueprints/LINDHALL/LINDHALL-03.svg',
          'Blueprints/LINDHALL/LINDHALL-04.svg',
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
      case 'MANTEI':
        return [
          'Blueprints/MANTEI/MANTEI-03.svg',
          'Blueprints/MANTEI/MANTEI-04.svg',
          'Blueprints/MANTEI/MANTEI-05.svg',
          'Blueprints/MANTEI/MANTEI-06.svg',
          'Blueprints/MANTEI/MANTEI-07.svg',
          'Blueprints/MANTEI/MANTEI-08.svg',
        ];
      case 'MARKETPT':
        return [
          'Blueprints/MARKETPT/MARKETPT-01.svg',
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
      case 'RIEVSCHL':
        return [
          'Blueprints/RIEVSCHL/RIEVSCHL-04.svg',
          'Blueprints/RIEVSCHL/RIEVSCHL-05.svg',
          'Blueprints/RIEVSCHL/RIEVSCHL-06.svg',
          'Blueprints/RIEVSCHL/RIEVSCHL-07.svg',
          'Blueprints/RIEVSCHL/RIEVSCHL-08.svg',
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
      case 'VANWORMR':
        return [
          'Blueprints/VANWORMR/VANWORMR-01.svg',
          'Blueprints/VANWORMR/VANWORMR-02.svg',
          'Blueprints/VANWORMR/VANWORMR-03.svg',
        ];
      case 'VVB':
        return [
          'Blueprints/VVB/VVB-02.svg',
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
