import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../services/scanner_camera_service.dart';
import '../widgets/empty_state.dart';
import 'edit_item_screen.dart';
import 'item_detail_screen.dart';

/// Full-screen barcode/QR scanner. On a successful scan it either opens the
/// existing item's detail screen, or pre-fills the add-item form.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  static const _cameraService = ScannerCameraService();

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
  );

  bool _handled = false;
  bool _isStartingCamera = false;
  bool get _supportsLiveScanning => _cameraService.supportsLiveScanning;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: _showManualEntryDialog,
            tooltip: 'Enter barcode manually',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _controller.value.isRunning
                ? () => _controller.toggleTorch()
                : null,
            tooltip: 'Toggle flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _controller.value.isRunning
                ? () => _controller.switchCamera()
                : null,
            tooltip: 'Flip camera',
          ),
        ],
      ),
      body: ValueListenableBuilder<MobileScannerState>(
        valueListenable: _controller,
        builder: (context, scannerState, _) {
          return Stack(
            children: [
              if (_supportsLiveScanning)
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                )
              else
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: EmptyState(
                      icon: Icons.camera_alt_outlined,
                      message: _cameraService.unsupportedMessage,
                      actionLabel: 'Enter barcode',
                      onAction: _showManualEntryDialog,
                    ),
                  ),
                ),
              if (_supportsLiveScanning && scannerState.isRunning) ...[
                // Scan-region overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Point camera at a barcode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withAlpha(180),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 88,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black.withAlpha(120),
                      ),
                      onPressed: _showManualEntryDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Enter barcode manually'),
                    ),
                  ),
                ),
              ],
              if (_supportsLiveScanning && !scannerState.isRunning)
                _buildCameraStartPanel(scannerState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraStartPanel(MobileScannerState scannerState) {
    final error = scannerState.error;
    final errorMessage = error?.errorDetails?.message;

    String guidance = 'Tap Open camera to allow permission and start scanning.';
    if (error?.errorCode == MobileScannerErrorCode.permissionDenied) {
      guidance =
          'Camera permission was denied. Grant permission and tap Open camera again.';
    } else if (error?.errorCode == MobileScannerErrorCode.unsupported) {
      guidance =
          'Camera scanning is not supported on this device. You can still enter barcode manually.';
    } else if (errorMessage != null && errorMessage.isNotEmpty) {
      guidance = errorMessage;
    }

    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    guidance,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isStartingCamera ? null : _openCamera,
                    icon: _isStartingCamera
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.videocam),
                    label: Text(_isStartingCamera ? 'Opening...' : 'Open camera'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter barcode manually'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera() async {
    if (_isStartingCamera) return;
    setState(() => _isStartingCamera = true);

    await _controller.start();

    if (!mounted) return;
    setState(() => _isStartingCamera = false);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    await _processBarcode(raw);
  }

  Future<void> _processBarcode(String raw) async {
    if (_handled) return;

    _handled = true;

    if (_supportsLiveScanning) {
      await _controller.stop();
    }

    if (!mounted) return;

    final inv = context.read<InventoryProvider>();
    final item = await inv.getItemByBarcode(raw);

    if (!mounted) return;

    if (item != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      );
    } else {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EditItemScreen(initialBarcode: raw)),
      );
    }
  }

  Future<void> _showManualEntryDialog() async {
    final controller = TextEditingController();

    final barcode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter barcode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Barcode / SKU',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    controller.dispose();

    final value = barcode?.trim() ?? '';
    if (value.isEmpty || !mounted) return;

    await _processBarcode(value);
  }
}
