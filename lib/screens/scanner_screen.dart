import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
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
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

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
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Flip camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
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
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    await _controller.stop();

    if (!mounted) return;

    final inv  = context.read<InventoryProvider>();
    final item = await inv.getItemByBarcode(raw);

    if (!mounted) return;

    if (item != null) {
      // Item already exists – open detail / quantity screen
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      );
    } else {
      // New item – open add-item form pre-filled with barcode
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => EditItemScreen(initialBarcode: raw)),
      );
    }
  }
}
