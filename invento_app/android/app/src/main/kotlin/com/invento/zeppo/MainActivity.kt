package com.invento.zeppo

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "zeppo_native_ocr",
        ).setMethodCallHandler { call, result ->
            if (call.method != "recognizeText") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val imagePath = call.argument<String>("imagePath")
            if (imagePath.isNullOrBlank()) {
                result.error("INVALID_ARGUMENTS", "Missing imagePath.", null)
                return@setMethodCallHandler
            }

            recognizeText(imagePath, result)
        }
    }

    private fun recognizeText(imagePath: String, result: MethodChannel.Result) {
        val imageFile = File(imagePath)
        if (!imageFile.exists()) {
            result.error("FILE_NOT_FOUND", "Could not find image at $imagePath", null)
            return
        }

        val inputImage =
            try {
                InputImage.fromFilePath(this, Uri.fromFile(imageFile))
            } catch (error: Exception) {
                result.error(
                    "OCR_INPUT_ERROR",
                    error.localizedMessage ?: "Failed to read the selected image.",
                    null,
                )
                return
            }

        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer
            .process(inputImage)
            .addOnSuccessListener { visionText ->
                recognizer.close()
                result.success(visionText.text)
            }.addOnFailureListener { error ->
                recognizer.close()
                result.error(
                    "OCR_FAILED",
                    error.localizedMessage ?: "Native OCR failed.",
                    null,
                )
            }
    }
}
