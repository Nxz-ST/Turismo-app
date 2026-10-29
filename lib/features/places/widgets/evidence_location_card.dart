import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';

class EvidenceLocationCard extends StatelessWidget {
  const EvidenceLocationCard({super.key, required this.evidence});

  final Map<String, dynamic> evidence;

  @override
  Widget build(BuildContext context) {
    final latitude = _number(evidence['latitude']);
    final longitude = _number(evidence['longitude']);
    if (latitude == null || longitude == null) {
      return const SizedBox.shrink();
    }
    final position = LatLng(latitude, longitude);
    final accuracy = _number(evidence['gps_accuracy_m']);
    final source = evidence['capture_source']?.toString();
    final capturedAt = DateTime.tryParse(
      evidence['captured_at']?.toString() ?? '',
    )?.toLocal();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Ubicación de la evidencia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 180,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: position,
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('evidence_location'),
                    position: position,
                    infoWindow: const InfoWindow(title: 'Punto de captura'),
                  ),
                },
                circles: accuracy == null
                    ? const {}
                    : {
                        Circle(
                          circleId: const CircleId('gps_accuracy'),
                          center: position,
                          radius: accuracy,
                          fillColor: AppColors.primary.withValues(alpha: 0.12),
                          strokeColor: AppColors.primary,
                          strokeWidth: 1,
                        ),
                      },
                zoomControlsEnabled: false,
                mapToolbarEnabled: true,
                myLocationButtonEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _detail(
            Icons.gps_fixed,
            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          ),
          if (accuracy != null)
            _detail(
              Icons.radar,
              'Precisión aproximada: ${accuracy.toStringAsFixed(1)} m',
            ),
          if (capturedAt != null)
            _detail(Icons.schedule, 'Capturada: ${_date(capturedAt)}'),
          _detail(
            source == 'camera'
                ? Icons.camera_alt_outlined
                : Icons.photo_outlined,
            source == 'camera'
                ? 'Fotografía tomada desde la cámara'
                : source == 'gallery'
                ? 'Imagen seleccionada desde la galería'
                : 'Origen de imagen no registrado',
          ),
          const SizedBox(height: 5),
          const Text(
            'Se muestra el punto asociado a la evidencia; RutaAmiga no realiza seguimiento GPS en tiempo real.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textLight),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  double? _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '');
  }

  String _date(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
