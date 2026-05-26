import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../models/scan_payload_model.dart';
import 'scan_payload_parser.dart';

class OcrService {
  OcrService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  static const MethodChannel _channel = MethodChannel('zeppo_native_ocr');

  final ImagePicker _imagePicker;

  Future<ScanPayloadModel?> captureLabel(ImageSource source) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'Label OCR is currently available on Android and iOS only.',
      );
    }

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null) {
      return null;
    }

    final rawText =
        (await _channel.invokeMethod<String>('recognizeText', {
          'imagePath': file.path,
        }))?.trim() ??
        '';
    if (rawText.isEmpty) {
      throw StateError('No readable label text was found in the image.');
    }

    return ScanPayloadParser.parseLabelText(rawText);
  }
}
