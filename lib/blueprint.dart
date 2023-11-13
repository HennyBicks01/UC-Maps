import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class Blueprint extends StatelessWidget {
  final String buildingName;

  Blueprint({Key? key, required this.buildingName}) : super(key: key);

  List<String> getPdfFilePaths() {
    switch(buildingName) {
      case '2540CLIF':
        return [
          'Blueprints/2540CLIF/2540CLIF-01.pdf',
          'Blueprints/2540CLIF/2540CLIF-02.pdf',
          'Blueprints/2540CLIF/2540CLIF-03.pdf',
          'Blueprints/2540CLIF/2540CLIF-04.pdf',
        ];
      case '60WCHARL':
        return [
          'Blueprints/60WCHARL/60WCHARL-01.pdf',
          'Blueprints/60WCHARL/60WCHARL-02.pdf',
          'Blueprints/60WCHARL/60WCHARL-B.pdf',
        ];
      case 'ARMORY':
        return [
          'Blueprints/ARMORY/ARMORY-01.pdf',
          'Blueprints/ARMORY/ARMORY-02.pdf',
        ];
      case 'ARTSCI':
        return [
          'Blueprints/ARTSCI/ARTSCI-00.pdf',
          'Blueprints/ARTSCI/ARTSCI-01.pdf',
          'Blueprints/ARTSCI/ARTSCI-02.pdf',
          'Blueprints/ARTSCI/ARTSCI-03.pdf',
        ];
      case 'BLEGEN':
        return [
          'Blueprints/BLEGEN/BLEGEN-02.pdf',
          'Blueprints/BLEGEN/BLEGEN-03.pdf',
          'Blueprints/BLEGEN/BLEGEN-04.pdf',
          'Blueprints/BLEGEN/BLEGEN-06.pdf',
          'Blueprints/BLEGEN/BLEGEN-08.pdf',
        ];
      case 'BRAUNSTN':
        return [
          'Blueprints/BRAUNSTN/BRAUNSTN-01.pdf',
          'Blueprints/BRAUNSTN/BRAUNSTN-02.pdf',
          'Blueprints/BRAUNSTN/BRAUNSTN-03.pdf',
          'Blueprints/BRAUNSTN/BRAUNSTN-04.pdf',
        ];
      case 'CALHONGR':
        return [
          'Blueprints/CALHONGR/CALHONGR-P1.pdf',
          'Blueprints/CALHONGR/CALHONGR-P2.pdf',
          'Blueprints/CALHONGR/CALHONGR-P4.pdf',
        ];
      case 'CCM':
        return [
        ];
      case 'CLIFTCT':
        return [
          'Blueprints/CLIFTCT/CLIFTCT-01.pdf',
          'Blueprints/CLIFTCT/CLIFTCT-02.pdf',
          'Blueprints/CLIFTCT/CLIFTCT-03.pdf',
          'Blueprints/CLIFTCT/CLIFTCT-04.pdf',
          'Blueprints/CLIFTCT/CLIFTCT-05.pdf',
        ];
      case 'COLLAW':
        return [
          'Blueprints/COLLAW/COLLAW-01.pdf',
          'Blueprints/COLLAW/COLLAW-02.pdf',
          'Blueprints/COLLAW/COLLAW-03.pdf',
          'Blueprints/COLLAW/COLLAW-04.pdf',
          'Blueprints/COLLAW/COLLAW-05.pdf',
          'Blueprints/COLLAW/COLLAW-06.pdf',
          'Blueprints/COLLAW/COLLAW-B.pdf',
        ];
      case 'COMMONSN-S':
        return [
        ];
      case 'CROSLEY':
        return [
          'Blueprints/CROSLEY/CROSLEY-01.pdf',
          'Blueprints/CROSLEY/CROSLEY-02.pdf',
          'Blueprints/CROSLEY/CROSLEY-03.pdf',
          'Blueprints/CROSLEY/CROSLEY-04.pdf',
          'Blueprints/CROSLEY/CROSLEY-05.pdf',
          'Blueprints/CROSLEY/CROSLEY-06.pdf',
          'Blueprints/CROSLEY/CROSLEY-07.pdf',
          'Blueprints/CROSLEY/CROSLEY-08.pdf',
          'Blueprints/CROSLEY/CROSLEY-09.pdf',
          'Blueprints/CROSLEY/CROSLEY-10.pdf',
          'Blueprints/CROSLEY/CROSLEY-11.pdf',
          'Blueprints/CROSLEY/CROSLEY-12.pdf',
          'Blueprints/CROSLEY/CROSLEY-13.pdf',
          'Blueprints/CROSLEY/CROSLEY-14.pdf',
          'Blueprints/CROSLEY/CROSLEY-15.pdf',
          'Blueprints/CROSLEY/CROSLEY-16.pdf',
        ];
      case 'DAAP':
        return [
          'Blueprints/DAAP/DAAP-05.pdf',
          'Blueprints/DAAP/DAAP-06.pdf',
          'Blueprints/DAAP/DAAP-07.pdf',
          'Blueprints/DAAP/DAAP-08.pdf',
        ];
      case 'DIETERLE':
        return [
          'Blueprints/DIETERLE/DIETERLE-02.pdf',
          'Blueprints/DIETERLE/DIETERLE-03.pdf',
        ];
      case 'EDWARDS':
        return [
          'Blueprints/EDWARDS/EDWARDS-01.pdf',
          'Blueprints/EDWARDS/EDWARDS-02.pdf',
          'Blueprints/EDWARDS/EDWARDS-03.pdf',
          'Blueprints/EDWARDS/EDWARDS-04.pdf',
          'Blueprints/EDWARDS/EDWARDS-05.pdf',
          'Blueprints/EDWARDS/EDWARDS-06.pdf',
          'Blueprints/EDWARDS/EDWARDS-07.pdf',
        ];
      case 'FRENCH-W_':
        return [
          'Blueprints/FRENCH-W_/FRENCH-W-01.pdf',
          'Blueprints/FRENCH-W_/FRENCH-W-02.pdf',
          'Blueprints/FRENCH-W_/FRENCH-W-03.pdf',
          'Blueprints/FRENCH-W_/FRENCH-W-04.pdf',
          'Blueprints/FRENCH-W_/FRENCH-W-05.pdf',
          'Blueprints/FRENCH-W_/FRENCH-W-06.pdf',
        ];
      case 'GEOPHYS':
        return [
          'Blueprints/GEOPHYS/GEOPHYS-01.pdf',
          'Blueprints/GEOPHYS/GEOPHYS-02.pdf',
          'Blueprints/GEOPHYS/GEOPHYS-03.pdf',
          'Blueprints/GEOPHYS/GEOPHYS-04.pdf',
          'Blueprints/GEOPHYS/GEOPHYS-05.pdf',
          'Blueprints/GEOPHYS/GEOPHYS-06.pdf',
        ];
      case 'LANGSAM':
        return [
          'Blueprints/LANGSAM/LANGSAM-04.pdf',
          'Blueprints/LANGSAM/LANGSAM-05.pdf',
          'Blueprints/LANGSAM/LANGSAM-06.pdf',
        ];
      case 'LINDHALL':
        return [
          'Blueprints/LINDHALL/LINDHALL-00.pdf',
          'Blueprints/LINDHALL/LINDHALL-01.pdf',
          'Blueprints/LINDHALL/LINDHALL-02.pdf',
          'Blueprints/LINDHALL/LINDHALL-03.pdf',
          'Blueprints/LINDHALL/LINDHALL-04.pdf',
        ];
      case 'LNDNRCTR':
        return [
          'Blueprints/LNDNRCTR/LNDNRCTR-01.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-02.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-03.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-04.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-05.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-06.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-07.pdf',
          'Blueprints/LNDNRCTR/LNDNRCTR-08.pdf',
        ];
      case 'MANTEI':
        return [
          'Blueprints/MANTEI/MANTEI-03.pdf',
          'Blueprints/MANTEI/MANTEI-04.pdf',
          'Blueprints/MANTEI/MANTEI-05.pdf',
          'Blueprints/MANTEI/MANTEI-06.pdf',
          'Blueprints/MANTEI/MANTEI-07.pdf',
          'Blueprints/MANTEI/MANTEI-08.pdf',
        ];
      case 'MARKETPT':
        return [
          'Blueprints/MARKETPT/MARKETPT-01.pdf',
        ];
      case 'MSPENCER':
        return [
          'Blueprints/MSPENCER/MSPENCER-G.pdf',
        ];
      case 'NIPPERT':
        return [
          'Blueprints/NIPPERT/NIPPERT-01.pdf',
          'Blueprints/NIPPERT/NIPPERT-02.pdf',
          'Blueprints/NIPPERT/NIPPERT-03.pdf',
          'Blueprints/NIPPERT/NIPPERT-03M.pdf',
          'Blueprints/NIPPERT/NIPPERT-04.pdf',
          'Blueprints/NIPPERT/NIPPERT-05.pdf',
        ];
      case 'RECCENTR':
        return [
          'Blueprints/RECCENTR/RECCENTR-00.pdf',
          'Blueprints/RECCENTR/RECCENTR-00M.pdf',
          'Blueprints/RECCENTR/RECCENTR-01.pdf',
          'Blueprints/RECCENTR/RECCENTR-02.pdf',
          'Blueprints/RECCENTR/RECCENTR-03.pdf',
        ];
      case 'RHODES':
        return [
          'Blueprints/RHODES/RHODES-03.pdf',
          'Blueprints/RHODES/RHODES-04.pdf',
          'Blueprints/RHODES/RHODES-05.pdf',
          'Blueprints/RHODES/RHODES-06.pdf',
          'Blueprints/RHODES/RHODES-07.pdf',
          'Blueprints/RHODES/RHODES-08.pdf',
          'Blueprints/RHODES/RHODES-09.pdf',
        ];
      case 'RIEVSCHL':
        return [
          'Blueprints/RIEVSCHL/RIEVSCHL-04.pdf',
          'Blueprints/RIEVSCHL/RIEVSCHL-05.pdf',
          'Blueprints/RIEVSCHL/RIEVSCHL-06.pdf',
          'Blueprints/RIEVSCHL/RIEVSCHL-07.pdf',
          'Blueprints/RIEVSCHL/RIEVSCHL-08.pdf',
        ];
      case 'SHOE':
        return [
          'Blueprints/SHOE/SHOE-04.pdf',
          'Blueprints/SHOE/SHOE-04M.pdf',
          'Blueprints/SHOE/SHOE-05.pdf',
        ];
      case 'STEGER':
        return [
          'Blueprints/STEGER/STEGER-04.pdf',
          'Blueprints/STEGER/STEGER-05.pdf',
          'Blueprints/STEGER/STEGER-06.pdf',
          'Blueprints/STEGER/STEGER-07.pdf',
          'Blueprints/STEGER/STEGER-08.pdf',
        ];
      case 'Swift Hall':
        return [
          'Blueprints/Swift Hall/SWIFT-05.pdf',
          'Blueprints/Swift Hall/SWIFT-06.pdf',
          'Blueprints/Swift Hall/SWIFT-07.pdf',
          'Blueprints/Swift Hall/SWIFT-08.pdf',
        ];
      case 'TEACHERS':
        return [
          'Blueprints/TEACHERS/TEACHERS-01.pdf',
          'Blueprints/TEACHERS/TEACHERS-02.pdf',
          'Blueprints/TEACHERS/TEACHERS-03.pdf',
          'Blueprints/TEACHERS/TEACHERS-04.pdf',
          'Blueprints/TEACHERS/TEACHERS-05.pdf',
          'Blueprints/TEACHERS/TEACHERS-06.pdf',
        ];
      case 'TUC':
        return [
          'Blueprints/TUC/TUC-01.pdf',
          'Blueprints/TUC/TUC-02.pdf',
          'Blueprints/TUC/TUC-03.pdf',
          'Blueprints/TUC/TUC-04.pdf',
        ];
      case 'UNIVPAV':
        return [
          'Blueprints/UNIVPAV/UNIVPAV-01.pdf',
          'Blueprints/UNIVPAV/UNIVPAV-02.pdf',
          'Blueprints/UNIVPAV/UNIVPAV-03.pdf',
          'Blueprints/UNIVPAV/UNIVPAV-04.pdf',
          'Blueprints/UNIVPAV/UNIVPAV-05.pdf',
          'Blueprints/UNIVPAV/UNIVPAV-06.pdf',
        ];
      case 'VANWORMR':
        return [
          'Blueprints/VANWORMR/VANWORMR-01.pdf',
          'Blueprints/VANWORMR/VANWORMR-02.pdf',
          'Blueprints/VANWORMR/VANWORMR-03.pdf',
        ];
      case 'VVB':
        return [
          'Blueprints/VVB/VVB-02.pdf',
        ];
      case 'ZIMMER':
        return [
          'Blueprints/ZIMMER/ZIMMER-04.pdf',
        ];

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> pdfFiles = getPdfFilePaths();

    return Scaffold(
      appBar: AppBar(title: Text(buildingName)),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: pdfFiles.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPdf(context, pdfFiles[index]),
            child: Card(
              child: Center(
                child: Text('PDF Thumbnail'), // Replace with actual thumbnail
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPdf(BuildContext context, String pdfPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewPage(path: pdfPath),
      ),
    );
  }
}

class PdfViewPage extends StatelessWidget {
  final String path;

  PdfViewPage({Key? key, required this.path}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF View'),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}
