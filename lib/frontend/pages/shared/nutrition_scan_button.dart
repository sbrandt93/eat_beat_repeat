import 'package:eat_beat_repeat/logic/models/scanned_nutrients.dart';
import 'package:eat_beat_repeat/logic/services/nutrition_scan_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// True on Android and iOS — the only platforms with a physical camera.
bool get _hasMobileCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// A reusable button that triggers a nutrition label scan and reports the
/// extracted values via [onResult].
///
/// On Android/iOS: shows a bottom sheet to pick Camera or Gallery, then runs
/// ML Kit OCR on-device.
/// On other platforms: tapping shows an informational message — the button is
/// still rendered so forms look consistent everywhere.
class NutritionScanButton extends StatefulWidget {
  final void Function(ScannedNutrients nutrients) onResult;

  const NutritionScanButton({super.key, required this.onResult});

  @override
  State<NutritionScanButton> createState() => _NutritionScanButtonState();
}

class _NutritionScanButtonState extends State<NutritionScanButton> {
  bool _isLoading = false;

  Future<void> _scan(ImageSource source) async {
    setState(() => _isLoading = true);
    final service = NutritionScanService();
    try {
      final result = source == ImageSource.camera
          ? await service.scanFromCamera()
          : await service.scanFromGallery();

      if (!mounted) return;
      if (result == null) return; // user cancelled

      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Keine Nährwerte erkannt. '
              'Bitte ein deutlicheres Foto der Nährwerttabelle versuchen.',
            ),
          ),
        );
      } else {
        widget.onResult(result);
        final found = [
          if (result.calories != null) 'kcal',
          if (result.protein != null) 'Protein',
          if (result.carbs != null) 'Kohlenhydrate',
          if (result.fat != null) 'Fett',
        ];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erkannt: ${found.join(', ')}'),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Scannen: $e')),
      );
    } finally {
      service.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleTap() {
    if (!_hasMobileCamera) {
      // Desktop: no camera, directly open file picker
      _scan(ImageSource.gallery);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Nährwerte scannen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Fotografiere die Nährwerttabelle auf der Verpackung.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _scan(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus Galerie wählen'),
              onTap: () {
                Navigator.pop(ctx);
                _scan(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _handleTap,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.document_scanner_outlined),
      label: Text(_isLoading ? 'Wird erkannt...' : 'Nährwerte scannen'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
