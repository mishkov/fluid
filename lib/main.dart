// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pasteboard/pasteboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

enum EditStage { pickup, editing }

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EditStage _stage = EditStage.pickup;

  Uint8List? _originImageBytes;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();

    PackageInfo.fromPlatform().then((value) => _packageInfo = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluid'),
        actions: [
          IconButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Fluid',
                applicationVersion: _packageInfo?.version,
                applicationLegalese: 'Mishkov Mikita',
                children: [
                  Text(
                      'You can use ctrl+p to paste the image to edit. Also you can use ctrl+c to copy cropped image.')
                ],
              );
            },
            icon: const Icon(Icons.help),
          ),
        ],
      ),
      body: _stage == EditStage.editing
          ? _originImageBytes != null
              ? Editor(
                  rawImage: _originImageBytes!,
                )
              : const Center(
                  child: Text('_imageBytes is null!'),
                )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Uploader(
                onUpload: (file) {
                  setState(() {
                    _originImageBytes = file;
                    _stage = EditStage.editing;
                  });
                },
              ),
            ),
    );
  }
}

class Uploader extends StatefulWidget {
  const Uploader({
    Key? key,
    required this.onUpload,
  }) : super(key: key);

  final void Function(Uint8List file) onUpload;

  @override
  State<Uploader> createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  DropzoneViewController? controller;
  bool highlighted = false;
  StreamSubscription? _onPasteEvent;

  @override
  void initState() {
    super.initState();
    _onPasteEvent = html.document
        .getElementsByTagName('body')
        .first
        .on['paste']
        .listen((event) {
      Pasteboard.image.then(_handleImageFromClipBoard);
    });
  }

  @override
  void dispose() {
    _onPasteEvent?.cancel();
    super.dispose();
  }

  Future<void> _handleImageFromClipBoard(Uint8List? image) async {
    if (image == null) {
      return;
    }

    widget.onUpload(image);
  }

  Future<void> _handleFile(file) async {
    if (file == null) {
      return;
    }
    if (controller == null) {
      return;
    }

    setState(() {
      highlighted = false;
    });
    final bytes = await controller?.getFileData(file);
    if (bytes != null) {
      widget.onUpload(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = 5.0;
    const borderPadding = 8.0;

    return Container(
      decoration: BoxDecoration(
        color: highlighted ? Colors.amber : Colors.green,
        borderRadius: BorderRadius.circular(borderRadius + borderPadding),
      ),
      child: DottedBorder(
        color: Colors.white,
        strokeWidth: 3,
        padding: const EdgeInsets.all(borderPadding),
        borderType: BorderType.RRect,
        borderPadding: const EdgeInsets.all(borderPadding),
        radius: const Radius.circular(borderRadius),
        dashPattern: const [12, 8],
        child: Stack(
          children: [
            DropzoneView(
              operation: DragOperation.copy,
              cursor: CursorType.grab,
              onCreated: (ctrl) => controller = ctrl,
              onHover: () {
                setState(() {
                  highlighted = true;
                });
              },
              onLeave: () {
                setState(() {
                  highlighted = false;
                });
              },
              onDrop: _handleFile,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drop something here',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'or',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (controller == null) {
                        return;
                      }

                      final files = await controller!
                          .pickFiles(mime: ['image/jpeg', 'image/png']);
                      await _handleFile(files.firstOrNull);
                    },
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll(EdgeInsets.all(16.0)),
                    ),
                    child: const Text(
                      'Choose file',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Editor extends StatefulWidget {
  const Editor({
    Key? key,
    required this.rawImage,
  }) : super(key: key);

  final Uint8List rawImage;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final _cropController = CropController();
  StreamSubscription? _onCopyEvent;

  @override
  void initState() {
    super.initState();
    _onCopyEvent = html.document
        .getElementsByTagName('body')
        .first
        .on['copy']
        .listen((event) {
      _cropController.crop();
    });
  }

  @override
  void dispose() {
    _onCopyEvent?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32.0),
      child: Crop(
        aspectRatio: 547 / 470,
        image: widget.rawImage,
        controller: _cropController,
        baseColor: Colors.transparent,
        interactive: false,
        onCropped: (image) {
          Pasteboard.writeImage(image);
        },
      ),
    );
  }
}
