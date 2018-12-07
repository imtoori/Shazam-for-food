import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController _cameraController;
  bool _loading = false;
  bool _itsHotDog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _elaborateImage(context),
        child: Icon(Icons.camera),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: <Widget>[
          AnimatedContainer(
            width: double.infinity,
            height: 100.0,
            color: _itsHotDog == null
                ? Colors.black
                : _itsHotDog == true ? Colors.green : Colors.red,
            child: Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: Center(
                child: Text(
                  _itsHotDog == null
                      ? ""
                      : _itsHotDog == true ? "HOT DOG!" : "NOT HOT DOG!",
                  style: Theme.of(context).textTheme.display1,
                ),
              ),
            ),
            duration: Duration(milliseconds: 400),
          ),
          Center(
            child: _isReady()
                ? AspectRatio(
                    aspectRatio: _cameraController.value.aspectRatio,
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : CameraPreview(_cameraController),
                  )
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  Future _elaborateImage(BuildContext context) async {
    final path =
        (await getTemporaryDirectory()).path + DateTime.now().toString();
    await _cameraController.takePicture(path);
    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFilePath(path);
    final LabelDetector labelDetector = FirebaseVision.instance.labelDetector();
    List<Label> labels = await labelDetector.detectInImage(visionImage);

    // print labels for debugging purpose
    labels.forEach((l) => print(l.label));

    setState(() {
      // search for "Hot dog label"
      _itsHotDog = labels.where((label) => label.label == 'Hot dog').isNotEmpty;
      _loading = false;
    });
  }

  bool _isReady() =>
      _cameraController != null && _cameraController.value.isInitialized;

  @override
  void initState() {
    super.initState();

    availableCameras().then((cameras) async {
      _cameraController = new CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );
      await _cameraController.initialize();
      setState(() {});
    }).catchError((error) {
      print("Error $error");
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
