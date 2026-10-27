import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class CameraImageConverter {
  static InputImage? convert({
    required CameraImage cameraImage,
    required CameraDescription camera,
  }) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    if (format == null) return null;

    if (cameraImage.planes.isEmpty) return null;

    final allBytes = WriteBuffer();
    for (final plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: cameraImage.planes.first.bytesPerRow,
      ),
    );
  }
}
