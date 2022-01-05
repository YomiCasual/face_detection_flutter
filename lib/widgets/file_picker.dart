// Dart imports:
// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, use_key_in_widget_constructors

import 'dart:io';

// Flutter imports:
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';

// Project imports:

//Custom Import

class FileUpload extends StatefulWidget {
  final bool cameraOnly;
  final onSaved;
  final Color? color;
  final String floatingLabel;
  final Function(File? image)? handleImage;
  final IconData? icon;
  final String label;
  final String errorText;
  final bool readOnly;
  final Function? getLocation;

  const FileUpload({
    required this.label,

    //Optional
    this.onSaved,
    this.readOnly = false,
    this.cameraOnly = false,
    this.color,
    this.errorText = "",
    this.icon,
    this.floatingLabel = '',
    this.handleImage,
    this.getLocation,
  });

  @override
  _FileUploadState createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  var _imagePath;
  var _imageSize;
  var _imageName = '';
  String _largeSize = '';

  final faceDetector =
      GoogleMlKit.vision.faceDetector(const FaceDetectorOptions(
    enableLandmarks: true,
    mode: FaceDetectorMode.accurate,
    enableContours: true,
    enableClassification: true,
  ));

  //This is use to control error field
  final fieldController = TextEditingController();

  bool detectHumanFace(Face face) {
    // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
    // eyes, cheeks, and nose available):
    final FaceLandmark? leftEar = face.getLandmark(FaceLandmarkType.leftEar);
    final FaceLandmark? rightEar = face.getLandmark(FaceLandmarkType.rightEar);
    final FaceLandmark? bottomMouth =
        face.getLandmark(FaceLandmarkType.bottomMouth);
    final FaceLandmark? leftEye = face.getLandmark(FaceLandmarkType.leftEye);
    final FaceLandmark? rightEye = face.getLandmark(FaceLandmarkType.rightEye);
    final FaceLandmark? noseBase = face.getLandmark(FaceLandmarkType.noseBase);

    final double? rotY =
        face.headEulerAngleY ?? 0; // Head is rotated to the right rotY degrees
    final double? rotZ = face.headEulerAngleZ ?? 0;

    List<FaceLandmark?> landmarks = [
      leftEar,
      rightEar,
      bottomMouth,
      leftEye,
      rightEye,
      noseBase
    ];

    bool hasAllLandmarks = landmarks.every((FaceLandmark? element) {
      if (element == null) return false;

      print('element${element.type}${element.position}');
      return true;
    });
    double? hasOpenLeftEye = face.leftEyeOpenProbability ?? 0;
    double? hasOpenRightEye = face.rightEyeOpenProbability ?? 0;
    print('rotY$rotY');
    print('rotZ$rotZ');
    print('hasAllLandmarks$hasAllLandmarks');
    print('openLeftEye$hasOpenLeftEye');
    print('openRightEye$hasOpenRightEye');

    if (hasAllLandmarks && hasOpenLeftEye >= 0.95 && hasOpenRightEye >= 0.95) {
      return true;
    }
    return false;
  }

  void _selectImageSource(ImageSource imageSource) async {
    // final ImagePicker _picker = ImagePicker();
    // final dynamic image = await _picker.pickImage(
    //     source: imageSource,
    //     preferredCameraDevice: CameraDevice.front,
    //     imageQuality: 50);
    // if (image == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    //Check if no file was picked
    if (result == null) return;

    //Get the raw file in order to get properties
    var image = result.files.single;

    //Get the raw image Size
    var rawImageSize = 200;

    //Confirm that the image is not greater than 10MB
    if (rawImageSize / 1000 > 3000) {
      setState(() {
        _largeSize = "large Size";
        fieldController.text = '';
      });
      return;
    }

    print('here');

    final inputImage = InputImage.fromFilePath(image.path as String);

    final List<Face> faces = await faceDetector.processImage(inputImage);

    print('faces$faces');

    if (faces.length > 1 || faces.isEmpty) return;
    final face = faces[0];

    final isHumanFace = detectHumanFace(face);

    print('isHumanFace$isHumanFace');
    setState(() {
      _imagePath = image.path;
      _imageName = image.name;
      _imageSize = (rawImageSize / 1000);
      _largeSize = '';
      fieldController.text = 'filled';
    });

    //Pass image to the function passed in
    if (widget.handleImage != null) {
      // widget.handleImage!(image);
    }
    FocusScope.of(context).requestFocus(FocusNode());
  }

  //Bottom sheet that pops up to ask user to select image type
  void _showImageSourceActionSheet(BuildContext context) async {
    // Check Platform type
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _selectImageSource(ImageSource.camera);
              },
              child: const Text('Camera'),
            ),
            // Don't display gallery if camera only is true
            widget.cameraOnly
                ? Container()
                : CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.pop(context);

                      _selectImageSource(ImageSource.gallery);
                    },
                    child: const Text('Gallery'),
                  ),
          ],
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.blue,
                ),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageSource(ImageSource.camera);
                },
              ),
              // Don't display gallery if camera only is true
              widget.cameraOnly
                  ? Container()
                  : ListTile(
                      leading: const Icon(
                        Icons.photo_album,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'Gallery',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _selectImageSource(ImageSource.gallery);
                      },
                    ),
            ],
          ),
        ),
      );
    }
  }

  //Return Function
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upload'),
        if (_imagePath == null) _uploadContainer() else _fileImageContainer()
      ],
    );
  }

  //Child Componeents

  Widget _uploadContainer() {
    return InkWell(
      onTap: widget.readOnly
          ? null
          : () {
              _showImageSourceActionSheet(context);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              TextFormField(
                  controller: fieldController,
                  readOnly: true,
                  onSaved: (value) {
                    if (widget.onSaved != null) {}
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please upload a file";
                    }
                  }),
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.blue,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.label,
                        style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Icon(
                      widget.icon ?? Icons.file_upload_outlined,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 10, left: 10),
            child: Text(
              _largeSize.isNotEmpty ? _largeSize : '',
            ),
          )
        ],
      ),
    );
  }

  Widget _fileImageContainer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description,
            size: 50,
            color: Colors.blue,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _imageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_imageSize.toString()} KB',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: () {
              setState(() {
                _imagePath = null;
                fieldController.text = '';
              });
              //Pass image to the function passed in
              if (widget.handleImage != null) {
                widget.handleImage!(null);
              }
            },
            child: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          )
        ],
      ),
    );
  }
}
