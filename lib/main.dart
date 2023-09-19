import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

enum EditStage { pickup, editing }

class _MyAppState extends State<MyApp> {
  DropzoneViewController? controller;
  bool highlighted = false;
  EditStage _stage = EditStage.pickup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dropzone example'),
        ),
        body: _stage == EditStage.pickup
            ? SizedBox.shrink()
            : Container(
                color: highlighted ? Colors.red : Colors.green,
                margin: const EdgeInsets.all(8.0),
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
                          const Text('Drop something here'),
                          const Text('or'),
                          ElevatedButton(
                            onPressed: () async {
                              if (controller == null) {
                                return;
                              }

                              print(await controller!.pickFiles(
                                  mime: ['image/jpeg', 'image/png']));
                            },
                            child: const Text('Pick file'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _handleFile(file) async {
    if (controller == null) {
      return;
    }

    setState(() {
      highlighted = false;
    });
    final bytes = await controller?.getFileData(file);
  }
}
