import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/inventory_controller.dart';
import '../../core/utils/date_utils.dart';
import '../../models/product_model.dart';
import '../../models/scan_payload_model.dart';
import '../../services/ocr_service.dart';
import '../scan/scan_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const List<String> _locationPositions = [
    'front',
    'middle',
    'back',
    'unspecified',
  ];

  final _formKey = GlobalKey<FormState>();
  final _inventoryController = InventoryController();
  final _ocrService = OcrService();
  final _productNameController = TextEditingController();
  final _skuController = TextEditingController();
  final _codeController = TextEditingController();
  final _batchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _warehouseController = TextEditingController();
  final _locationController = TextEditingController();

  String _source = 'manual';
  String _locationPosition = 'front';
  String? _selectedProductId;
  ScanPayloadModel? _lastScanPayload;
  DateTime? _manufacturedAt;
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _skuController.dispose();
    _codeController.dispose();
    _batchController.dispose();
    _quantityController.dispose();
    _warehouseController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _supportsNativeOcr {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  ProductModel? _findSelectedProduct(List<ProductModel> products) {
    for (final product in products) {
      if (product.id == _selectedProductId) {
        return product;
      }
    }

    return null;
  }

  ProductModel? _findMatchingProduct(
    List<ProductModel> products,
    ScanPayloadModel payload,
  ) {
    final scannableCode = payload.scannableCode?.trim();
    final sku = payload.sku?.trim();
    final productName = payload.productName?.trim().toLowerCase();

    for (final product in products) {
      if (scannableCode != null &&
          scannableCode.isNotEmpty &&
          product.qrCode.trim().isNotEmpty &&
          product.qrCode.trim() == scannableCode) {
        return product;
      }

      if (sku != null &&
          sku.isNotEmpty &&
          product.sku.trim().isNotEmpty &&
          product.sku.trim().toLowerCase() == sku.toLowerCase()) {
        return product;
      }

      if (productName != null &&
          productName.isNotEmpty &&
          product.name.trim().toLowerCase() == productName) {
        return product;
      }
    }

    return null;
  }

  void _setControllerValue(TextEditingController controller, String? value) {
    if (value == null || value.trim().isEmpty) {
      return;
    }

    controller.text = value.trim();
  }

  String? _normalizeLocationPosition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim().toLowerCase();
    if (normalized.contains('front')) {
      return 'front';
    }
    if (normalized.contains('middle') || normalized.contains('center')) {
      return 'middle';
    }
    if (normalized.contains('back') || normalized.contains('rear')) {
      return 'back';
    }
    if (normalized.contains('unspecified')) {
      return 'unspecified';
    }
    return null;
  }

  String _captureStatusLabel(ScanPayloadModel payload) {
    if (payload.codeFormat == 'ocr') {
      return payload.hasStructuredData
          ? 'Label text extracted'
          : 'Label text captured';
    }
    if (payload.hasStructuredData) {
      return 'Structured code detected';
    }
    if (payload.hasScannableCode) {
      return 'Raw code captured';
    }
    return 'Capture ready';
  }

  String _capturePreview(ScanPayloadModel payload) {
    final previewSource = payload.hasRecognizedText
        ? payload.recognizedText
        : payload.hasScannableCode
        ? payload.scannableCode
        : payload.rawValue;
    return previewSource?.trim() ?? payload.rawValue;
  }

  void _applyPayload(
    List<ProductModel> products,
    ScanPayloadModel payload, {
    required String source,
  }) {
    final matchedProduct = _findMatchingProduct(products, payload);
    final normalizedLocationPosition = _normalizeLocationPosition(
      payload.locationPosition,
    );

    setState(() {
      _source = source;
      _lastScanPayload = payload;

      if (matchedProduct != null) {
        _selectedProductId = matchedProduct.id;
        _productNameController.clear();
        _skuController.clear();
      } else {
        _selectedProductId = null;
        _setControllerValue(_productNameController, payload.productName);
        _setControllerValue(_skuController, payload.sku);
      }

      _setControllerValue(_codeController, payload.scannableCode);
      _setControllerValue(_batchController, payload.batchNumber);
      if (payload.quantity != null) {
        _quantityController.text = payload.quantity.toString();
      }
      _setControllerValue(_warehouseController, payload.warehouseName);
      _setControllerValue(_locationController, payload.locationCode);
      if (normalizedLocationPosition != null) {
        _locationPosition = normalizedLocationPosition;
      }
      _manufacturedAt = payload.manufacturedAt ?? _manufacturedAt;
      _expiryDate = payload.expiryDate ?? _expiryDate;
    });

    if (!mounted) {
      return;
    }

    final message = switch (source) {
      'ocr' =>
        payload.hasStructuredData
            ? 'Label text extracted and the batch form was filled where possible.'
            : 'Label text was captured. Review the result and complete the missing fields.',
      _ =>
        matchedProduct != null
            ? 'Code matched ${matchedProduct.name} and filled the batch form.'
            : payload.hasStructuredData
            ? 'Code scanned and batch fields were filled from the payload.'
            : 'Code scanned. Raw value saved to the scannable code field.',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openScanner(List<ProductModel> products) async {
    final payload = await Navigator.of(context).push<ScanPayloadModel>(
      MaterialPageRoute<ScanPayloadModel>(builder: (_) => const ScanScreen()),
    );

    if (!mounted || payload == null) {
      return;
    }

    _applyPayload(products, payload, source: 'scan');
  }

  Future<void> _readLabel(
    List<ProductModel> products,
    ImageSource source,
  ) async {
    try {
      final payload = await _ocrService.captureLabel(source);
      if (!mounted || payload == null) {
        return;
      }

      _applyPayload(products, payload, source: 'ocr');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openLabelReader(List<ProductModel> products) async {
    if (!_supportsNativeOcr) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Label OCR is currently available on Android and iOS.'),
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take label photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose label photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _readLabel(products, source);
  }

  Future<void> _save(List<ProductModel> products) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }

    final selectedProduct = _findSelectedProduct(products);

    setState(() {
      _isSaving = true;
    });

    try {
      await _inventoryController.addInventoryEntry(
        existingProduct: selectedProduct,
        productName: _productNameController.text,
        sku: _skuController.text,
        scannableCode: _codeController.text,
        batchNumber: _batchController.text,
        quantity: quantity,
        manufacturedAt: _manufacturedAt,
        expiryDate: _expiryDate,
        warehouseName: _warehouseController.text,
        locationCode: _locationController.text,
        locationPosition: _locationPosition,
        source: _source,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Batch saved')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add inventory batch')),
      body: StreamBuilder<List<ProductModel>>(
        stream: _inventoryController.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;
          final selectedProduct = _findSelectedProduct(products);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.qr_code_scanner_rounded),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Scan a barcode or read a market label',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Zeppo accepts QR codes, standard product barcodes, and printed labels through OCR. Use this when stock already comes labeled from the market.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : () => _openScanner(products),
                                      icon: const Icon(
                                        Icons.center_focus_strong_rounded,
                                      ),
                                      label: const Text('Scan code'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : () => _openLabelReader(products),
                                      icon: const Icon(
                                        Icons.document_scanner_outlined,
                                      ),
                                      label: const Text('Read label'),
                                    ),
                                    if (_lastScanPayload != null)
                                      Chip(
                                        avatar: const Icon(Icons.check_circle),
                                        label: Text(
                                          _captureStatusLabel(
                                            _lastScanPayload!,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (_lastScanPayload != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Last capture: ${_capturePreview(_lastScanPayload!)}',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedProductId,
                            decoration: const InputDecoration(
                              labelText: 'Existing product',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Create new product'),
                              ),
                              ...products.map(
                                (product) => DropdownMenuItem<String?>(
                                  value: product.id,
                                  child: Text(product.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedProductId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          if (selectedProduct == null) ...[
                            TextFormField(
                              controller: _productNameController,
                              decoration: const InputDecoration(
                                labelText: 'Product name',
                              ),
                              validator: (value) {
                                if (_selectedProductId != null) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return 'Product name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _skuController,
                              decoration: const InputDecoration(
                                labelText: 'SKU',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeController,
                              decoration: const InputDecoration(
                                labelText: 'Scannable code',
                                helperText: 'QR, barcode, or supplier code',
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            Text(
                              'Selected product: ${selectedProduct.name}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (selectedProduct.sku.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('SKU: ${selectedProduct.sku}'),
                            ],
                            if (selectedProduct.qrCode.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Code: ${selectedProduct.qrCode}'),
                            ],
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _batchController,
                            decoration: const InputDecoration(
                              labelText: 'Batch number',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Batch number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Quantity is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _warehouseController,
                            decoration: const InputDecoration(
                              labelText: 'Warehouse / zone',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Warehouse is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location code',
                              helperText:
                                  'Multiple batches can share the same location.',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Location code is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _locationPosition,
                            decoration: const InputDecoration(
                              labelText: 'Position in location',
                              helperText:
                                  'Keep the earliest-expiry batch at the front.',
                            ),
                            items: _locationPositions
                                .map(
                                  (position) => DropdownMenuItem(
                                    value: position,
                                    child: Text(switch (position) {
                                      'front' => 'Front',
                                      'middle' => 'Middle',
                                      'back' => 'Back',
                                      _ => 'Unspecified',
                                    }),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _locationPosition = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _source,
                            decoration: const InputDecoration(
                              labelText: 'Capture source',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'manual',
                                child: Text('Manual'),
                              ),
                              DropdownMenuItem(
                                value: 'scan',
                                child: Text('Barcode / QR scan'),
                              ),
                              DropdownMenuItem(
                                value: 'ocr',
                                child: Text('Label OCR'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _source = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _pickDate(
                                  initialDate: _manufacturedAt,
                                  onSelected: (value) {
                                    setState(() {
                                      _manufacturedAt = value;
                                    });
                                  },
                                ),
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(
                                  'Mfg ${formatShortDate(_manufacturedAt)}',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickDate(
                                  initialDate: _expiryDate,
                                  onSelected: (value) {
                                    setState(() {
                                      _expiryDate = value;
                                    });
                                  },
                                ),
                                icon: const Icon(
                                  Icons.event_available_outlined,
                                ),
                                label: Text(
                                  'Expiry ${formatShortDate(_expiryDate)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _save(products),
                              child: Text(
                                _isSaving ? 'Saving batch...' : 'Save batch',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
