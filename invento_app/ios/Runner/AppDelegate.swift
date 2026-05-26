import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "NativeOcrPlugin"
    ) {
      NativeOcrPlugin.register(with: registrar)
    }
  }
}

final class NativeOcrPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "zeppo_native_ocr",
      binaryMessenger: registrar.messenger()
    )
    let instance = NativeOcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognizeText" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let imagePath = args["imagePath"] as? String,
      !imagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "Missing imagePath.",
          details: nil
        )
      )
      return
    }

    recognizeText(imagePath: imagePath, result: result)
  }

  private func recognizeText(imagePath: String, result: @escaping FlutterResult) {
    let imageUrl = URL(fileURLWithPath: imagePath)
    guard FileManager.default.fileExists(atPath: imageUrl.path) else {
      result(
        FlutterError(
          code: "FILE_NOT_FOUND",
          message: "Could not find image at \(imagePath)",
          details: nil
        )
      )
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "OCR_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
        return
      }

      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      let text = observations
        .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

      DispatchQueue.main.async {
        result(text)
      }
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["en-US"]

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let handler = VNImageRequestHandler(url: imageUrl, options: [:])
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "OCR_INPUT_ERROR",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }
}
