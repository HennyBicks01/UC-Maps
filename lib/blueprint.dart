
import 'package:flutter/material.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getImageFilePaths() {
    switch(buildingName) {
      case '2540CLIF':
        return [
          'Blueprints/2540CLIF/2540CLIF-01.png',
          'Blueprints/2540CLIF/2540CLIF-02.png',
          'Blueprints/2540CLIF/2540CLIF-03.png',
          'Blueprints/2540CLIF/2540CLIF-04.png',
        ];
      case '60WCHARL':
        return [
          'Blueprints/60WCHARL/60WCHARL-01.png',
          'Blueprints/60WCHARL/60WCHARL-02.png',
          'Blueprints/60WCHARL/60WCHARL-B.png',
        ];
      case 'ARMORY':
        return [
          'Blueprints/ARMORY/ARMORY-01.png',
          'Blueprints/ARMORY/ARMORY-02.png',
        ];
      case 'ARTSCI':
        return [
          'Blueprints/ARTSCI/ARTSCI-00.png',
          'Blueprints/ARTSCI/ARTSCI-01.png',
          'Blueprints/ARTSCI/ARTSCI-02.png',
          'Blueprints/ARTSCI/ARTSCI-03.png',
        ];
      case 'BLEGEN':
        return [
          'Blueprints/BLEGEN/BLEGEN-02.png',
          'Blueprints/BLEGEN/BLEGEN-03.png',
          'Blueprints/BLEGEN/BLEGEN-04.png',
          'Blueprints/BLEGEN/BLEGEN-06.png',
          'Blueprints/BLEGEN/BLEGEN-08.png',
        ];
      case 'BRAUNSTN':
        return [
          'Blueprints/BRAUNSTN/BRAUNSTN-01.png',
          'Blueprints/BRAUNSTN/BRAUNSTN-02.png',
          'Blueprints/BRAUNSTN/BRAUNSTN-03.png',
          'Blueprints/BRAUNSTN/BRAUNSTN-04.png',
        ];
      case 'CALHONGR':
        return [
          'Blueprints/CALHONGR/CALHONGR-P1.png',
          'Blueprints/CALHONGR/CALHONGR-P2.png',
          'Blueprints/CALHONGR/CALHONGR-P4.png',
        ];
      case 'CCM':
        return [
        ];
      case 'CLIFTCT':
        return [
          'Blueprints/CLIFTCT/CLIFTCT-01.png',
          'Blueprints/CLIFTCT/CLIFTCT-02.png',
          'Blueprints/CLIFTCT/CLIFTCT-03.png',
          'Blueprints/CLIFTCT/CLIFTCT-04.png',
          'Blueprints/CLIFTCT/CLIFTCT-05.png',
        ];
      case 'COLLAW':
        return [
          'Blueprints/COLLAW/COLLAW-01.png',
          'Blueprints/COLLAW/COLLAW-02.png',
          'Blueprints/COLLAW/COLLAW-03.png',
          'Blueprints/COLLAW/COLLAW-04.png',
          'Blueprints/COLLAW/COLLAW-05.png',
          'Blueprints/COLLAW/COLLAW-06.png',
          'Blueprints/COLLAW/COLLAW-B.png',
        ];
      case 'COMMONSN-S':
        return [
        ];
      case 'CROSLEY':
        return [
          'Blueprints/CROSLEY/CROSLEY-01.png',
          'Blueprints/CROSLEY/CROSLEY-02.png',
          'Blueprints/CROSLEY/CROSLEY-03.png',
          'Blueprints/CROSLEY/CROSLEY-04.png',
          'Blueprints/CROSLEY/CROSLEY-05.png',
          'Blueprints/CROSLEY/CROSLEY-06.png',
          'Blueprints/CROSLEY/CROSLEY-07.png',
          'Blueprints/CROSLEY/CROSLEY-08.png',
          'Blueprints/CROSLEY/CROSLEY-09.png',
          'Blueprints/CROSLEY/CROSLEY-10.png',
          'Blueprints/CROSLEY/CROSLEY-11.png',
          'Blueprints/CROSLEY/CROSLEY-12.png',
          'Blueprints/CROSLEY/CROSLEY-13.png',
          'Blueprints/CROSLEY/CROSLEY-14.png',
          'Blueprints/CROSLEY/CROSLEY-15.png',
          'Blueprints/CROSLEY/CROSLEY-16.png',
        ];
      case 'DAAP':
        return [
          'Blueprints/DAAP/DAAP-05.png',
          'Blueprints/DAAP/DAAP-06.png',
          'Blueprints/DAAP/DAAP-07.png',
          'Blueprints/DAAP/DAAP-08.png',
        ];
      case 'DIETERLE':
        return [
          'Blueprints/DIETERLE/DIETERLE-02.png',
          'Blueprints/DIETERLE/DIETERLE-03.png',
        ];
      case 'EDWARDS':
        return [
          'Blueprints/EDWARDS/EDWARDS-01.png',
          'Blueprints/EDWARDS/EDWARDS-02.png',
          'Blueprints/EDWARDS/EDWARDS-03.png',
          'Blueprints/EDWARDS/EDWARDS-04.png',
          'Blueprints/EDWARDS/EDWARDS-05.png',
          'Blueprints/EDWARDS/EDWARDS-06.png',
          'Blueprints/EDWARDS/EDWARDS-07.png',
        ];
      case 'FRENCH-W_':
        return [
          'Blueprints/FRENCH-W_/FRENCH-W-01.png',
          'Blueprints/FRENCH-W_/FRENCH-W-02.png',
          'Blueprints/FRENCH-W_/FRENCH-W-03.png',
          'Blueprints/FRENCH-W_/FRENCH-W-04.png',
          'Blueprints/FRENCH-W_/FRENCH-W-05.png',
          'Blueprints/FRENCH-W_/FRENCH-W-06.png',
        ];
      case 'GEOPHYS':
        return [
          'Blueprints/GEOPHYS/GEOPHYS-01.png',
          'Blueprints/GEOPHYS/GEOPHYS-02.png',
          'Blueprints/GEOPHYS/GEOPHYS-03.png',
          'Blueprints/GEOPHYS/GEOPHYS-04.png',
          'Blueprints/GEOPHYS/GEOPHYS-05.png',
          'Blueprints/GEOPHYS/GEOPHYS-06.png',
        ];
      case 'LANGSAM':
        return [
          'Blueprints/LANGSAM/LANGSAM-04.png',
          'Blueprints/LANGSAM/LANGSAM-05.png',
          'Blueprints/LANGSAM/LANGSAM-06.png',
        ];
      case 'LINDHALL':
        return [
          'Blueprints/LINDHALL/LINDHALL-00.png',
          'Blueprints/LINDHALL/LINDHALL-01.png',
          'Blueprints/LINDHALL/LINDHALL-02.png',
          'Blueprints/LINDHALL/LINDHALL-03.png',
          'Blueprints/LINDHALL/LINDHALL-04.png',
        ];
      case 'LNDNRCTR':
        return [
          'Blueprints/LNDNRCTR/LNDNRCTR-01.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-02.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-03.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-04.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-05.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-06.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-07.png',
          'Blueprints/LNDNRCTR/LNDNRCTR-08.png',
        ];
      case 'MANTEI':
        return [
          'Blueprints/MANTEI/MANTEI-03.png',
          'Blueprints/MANTEI/MANTEI-04.png',
          'Blueprints/MANTEI/MANTEI-05.png',
          'Blueprints/MANTEI/MANTEI-06.png',
          'Blueprints/MANTEI/MANTEI-07.png',
          'Blueprints/MANTEI/MANTEI-08.png',
        ];
      case 'MARKETPT':
        return [
          'Blueprints/MARKETPT/MARKETPT-01.png',
        ];
      case 'MSPENCER':
        return [
          'Blueprints/MSPENCER/MSPENCER-G.png',
        ];
      case 'NIPPERT':
        return [
          'Blueprints/NIPPERT/NIPPERT-01.png',
          'Blueprints/NIPPERT/NIPPERT-02.png',
          'Blueprints/NIPPERT/NIPPERT-03.png',
          'Blueprints/NIPPERT/NIPPERT-03M.png',
          'Blueprints/NIPPERT/NIPPERT-04.png',
          'Blueprints/NIPPERT/NIPPERT-05.png',
        ];
      case 'RECCENTR':
        return [
          'Blueprints/RECCENTR/RECCENTR-00.png',
          'Blueprints/RECCENTR/RECCENTR-00M.png',
          'Blueprints/RECCENTR/RECCENTR-01.png',
          'Blueprints/RECCENTR/RECCENTR-02.png',
          'Blueprints/RECCENTR/RECCENTR-03.png',
        ];
      case 'RHODES':
        return [
          'Blueprints/RHODES/RHODES-03.png',
          'Blueprints/RHODES/RHODES-04.png',
          'Blueprints/RHODES/RHODES-05.png',
          'Blueprints/RHODES/RHODES-06.png',
          'Blueprints/RHODES/RHODES-07.png',
          'Blueprints/RHODES/RHODES-08.png',
          'Blueprints/RHODES/RHODES-09.png',
        ];
      case 'RIEVSCHL':
        return [
          'Blueprints/RIEVSCHL/RIEVSCHL-04.png',
          'Blueprints/RIEVSCHL/RIEVSCHL-05.png',
          'Blueprints/RIEVSCHL/RIEVSCHL-06.png',
          'Blueprints/RIEVSCHL/RIEVSCHL-07.png',
          'Blueprints/RIEVSCHL/RIEVSCHL-08.png',
        ];
      case 'SHOE':
        return [
          'Blueprints/SHOE/SHOE-04.png',
          'Blueprints/SHOE/SHOE-04M.png',
          'Blueprints/SHOE/SHOE-05.png',
        ];
      case 'STEGER':
        return [
          'Blueprints/STEGER/STEGER-04.png',
          'Blueprints/STEGER/STEGER-05.png',
          'Blueprints/STEGER/STEGER-06.png',
          'Blueprints/STEGER/STEGER-07.png',
          'Blueprints/STEGER/STEGER-08.png',
        ];
      case 'SWIFT':
        return [
        ];
      case 'Swift Hall':
        return [
          'Blueprints/Swift Hall/SWIFT-05.png',
          'Blueprints/Swift Hall/SWIFT-06.png',
          'Blueprints/Swift Hall/SWIFT-07.png',
          'Blueprints/Swift Hall/SWIFT-08.png',
        ];
      case 'TEACHERS':
        return [
          'Blueprints/TEACHERS/TEACHERS-01.png',
          'Blueprints/TEACHERS/TEACHERS-02.png',
          'Blueprints/TEACHERS/TEACHERS-03.png',
          'Blueprints/TEACHERS/TEACHERS-04.png',
          'Blueprints/TEACHERS/TEACHERS-05.png',
          'Blueprints/TEACHERS/TEACHERS-06.png',
        ];
      case 'TUC':
        return [
          'Blueprints/TUC/TUC-01.png',
          'Blueprints/TUC/TUC-02.png',
          'Blueprints/TUC/TUC-03.png',
          'Blueprints/TUC/TUC-04.png',
        ];
      case 'UNIVPAV':
        return [
          'Blueprints/UNIVPAV/UNIVPAV-01.png',
          'Blueprints/UNIVPAV/UNIVPAV-02.png',
          'Blueprints/UNIVPAV/UNIVPAV-03.png',
          'Blueprints/UNIVPAV/UNIVPAV-04.png',
          'Blueprints/UNIVPAV/UNIVPAV-05.png',
          'Blueprints/UNIVPAV/UNIVPAV-06.png',
        ];
      case 'VANWORMR':
        return [
          'Blueprints/VANWORMR/VANWORMR-01.png',
          'Blueprints/VANWORMR/VANWORMR-02.png',
          'Blueprints/VANWORMR/VANWORMR-03.png',
        ];
      case 'VVB':
        return [
          'Blueprints/VVB/VVB-02.png',
        ];
      case 'ZIMMER':
        return [
          'Blueprints/ZIMMER/ZIMMER-04.png',
        ];

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
