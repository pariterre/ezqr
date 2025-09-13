import 'dart:typed_data';
import 'dart:ui' as ui show Image, ImageByteFormat;
import 'dart:js_interop';
import 'package:flutter/rendering.dart';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fast QR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text('Fast QR'),
        ),
        body: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _qrKey = GlobalKey();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _exportToPng() async {
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception('Failed to encode image.');
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Convert Uint8List -> JSUint8Array (typed array) using .toJS
      final jsTypedArray = pngBytes.toJS; // JSUint8Array

      // Create a JSArray<BlobPart>. Two common approaches:
      //
      // 1) Reliable casting approach (works well and avoids constructor confusion):
      final JSArray<web.BlobPart> blobParts =
          ([jsTypedArray] as dynamic) as JSArray<web.BlobPart>;

      // 2) Alternative: construct and set element (may also work depending on SDK):
      // final blobParts = JSArray<web.BlobPart>()..[0] = jsTypedArray;

      // Build the blob and object URL
      final web.Blob blob = web.Blob(
        blobParts,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final String url = web.URL.createObjectURL(blob);

      // Create an anchor, trigger download, cleanup
      final web.HTMLAnchorElement anchor =
          web.HTMLAnchorElement()
            ..href = url
            ..download = 'qr_code.png';
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
    } catch (e, st) {
      // helpful debug print for development
      debugPrint('Export failed: $e\n$st');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Enter message to encode',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: 20),
          RepaintBoundary(
            key: _qrKey,
            child: QrImageView(
              data: _messageController.text,
              version: QrVersions.auto,
              size: 400.0,
              gapless: false,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _exportToPng,
            child: Text('Export QR Code'),
          ),
        ],
      ),
    );
  }
}
