import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/colors.dart';
import '../../services/scan_payload_parser.dart';
import '../../services/scanner_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _hasHandledCode = false;
  bool _torchEnabled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_hasHandledCode) {
      return;
    }

    Barcode? matchedBarcode;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim() ?? '';
      if (rawValue.isNotEmpty) {
        matchedBarcode = barcode;
        break;
      }
    }

    if (matchedBarcode == null) {
      return;
    }

    _hasHandledCode = true;
    final payload = ScannerService.fromBarcode(matchedBarcode);

    await _controller.stop();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(payload);
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) {
      return;
    }

    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  Future<void> _submitManualEntry(String rawValue) async {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (!_hasHandledCode) {
      _hasHandledCode = true;
      final payload = ScanPayloadParser.parse(trimmed, codeFormat: 'manual');
      if (mounted) {
        Navigator.of(context).pop(payload);
      }
    }
  }

  Future<void> _openManualEntryDialog() async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Paste code data'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'Paste a barcode, QR payload, or structured code data',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('Use value'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value == null) {
      return;
    }

    await _submitManualEntry(value);
  }

  Widget _buildScannerError(
    BuildContext context,
    MobileScannerException error,
  ) {
    final isUnsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    final title = switch (error.errorCode) {
      MobileScannerErrorCode.unsupported => 'Camera scanning unavailable',
      MobileScannerErrorCode.permissionDenied => 'Camera permission needed',
      _ => 'Scanner unavailable',
    };

    final description = switch (error.errorCode) {
      MobileScannerErrorCode.unsupported =>
        'This usually happens on simulators and emulators because they do not expose a real camera. You can keep testing by pasting code data manually, or use a physical phone for live scanning.',
      MobileScannerErrorCode.permissionDenied =>
        'Zeppo needs camera access to scan barcodes and QR codes. Allow camera permission in Settings, or paste code data manually to continue testing.',
      _ =>
        error.errorDetails?.message ??
            'The scanner could not start on this device right now.',
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          color: Colors.black.withValues(alpha: 0.78),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.amber,
                  size: 34,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _openManualEntryDialog,
                      icon: const Icon(Icons.content_paste_rounded),
                      label: const Text('Paste code data'),
                    ),
                    if (isPermissionDenied)
                      OutlinedButton.icon(
                        onPressed: _openManualEntryDialog,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Enter manually'),
                      ),
                    if (isUnsupported)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Back to form'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan product code'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
            tooltip: _torchEnabled ? 'Torch off' : 'Torch on',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetection,
            errorBuilder: _buildScannerError,
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.amber, width: 3),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Align a barcode or QR code inside the frame.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Zeppo supports common market barcodes plus QR codes. When the code contains extra data, Zeppo will auto-fill the batch form.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
