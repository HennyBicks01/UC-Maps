import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullScreenImagePage({Key? key, required this.imagePath}) : super(key: key);

  // Updated method to extract building and floor number
  Map<String, String> extractInfo(String path) {
    RegExp regExp = RegExp(r'Blueprints/([^/]+)/[^-]+-([0-9A-Za-z]+)\.svg$');
    var matches = regExp.firstMatch(path);
    return {
      'building': matches?.group(1) ?? 'Unknown',
      'floor': matches?.group(2) ?? 'Unknown'
    };
  }

  @override
  Widget build(BuildContext context) {
    var info = extractInfo(imagePath);

    // Create a TransformationController
    final TransformationController _controller = TransformationController();
    // Set an initial zoom and position
    _controller.value = Matrix4.identity()..scale(2.0); // Adjust scale value for initial zoom level

    return Scaffold(
      appBar: AppBar(
        title: Text('${info['building']} - Floor ${info['floor']}'),
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 0.1,
          maxScale: 5.0,
          child: SvgPicture.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
