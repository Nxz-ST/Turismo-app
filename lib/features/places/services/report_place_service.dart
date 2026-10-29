import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../core/network/backend_api_client.dart';

class ReportPlaceService {
  final BackendApiClient _api = BackendApiClient();

  Future<Map<String, dynamic>> submitAndProcess({
    required File imageFile,
    required String nombre,
    required String descripcion,
    required double latitud,
    required double longitud,
    required double altitud,
    required double gpsAccuracy,
    required String captureSource,
    required DateTime capturedAt,
    String? presenceSampleId,
    int? targetPlaceId,
  }) async {
    final filename = path.basename(imageFile.path);
    final contentType = _contentType(filename);
    final fileSize = await imageFile.length();
    final contentHash = await sha256.bind(imageFile.openRead()).first;

    final presign = Map<String, dynamic>.from(
      await _api.post(
            '/uploads/presign',
            body: {
              'filename': filename,
              'content_type': contentType,
              'size_bytes': fileSize,
            },
          )
          as Map,
    );

    await _api.uploadFile(
      uploadUrl: presign['upload_url'].toString(),
      file: imageFile,
      headers: Map<String, String>.from(presign['required_headers'] as Map),
    );

    final evidence = Map<String, dynamic>.from(
      await _api.post(
            '/evidences',
            body: {
              'client_evidence_id': const Uuid().v4(),
              'object_key': presign['object_key'],
              'original_filename': filename,
              'mime_type': contentType,
              'name': nombre,
              'description': descripcion,
              'latitude': latitud,
              'longitude': longitud,
              'altitude': altitud,
              'gps_accuracy_m': gpsAccuracy,
              'capture_source': captureSource,
              'captured_at': capturedAt.toUtc().toIso8601String(),
              'content_hash': contentHash.toString(),
              if (presenceSampleId != null)
                'presence_sample_id': presenceSampleId,
              'contribution_type': targetPlaceId == null
                  ? 'new_place'
                  : 'existing_place',
              if (targetPlaceId != null) 'target_place_id': targetPlaceId,
            },
          )
          as Map,
    );

    final evidenceId = evidence['id'].toString();
    await _api.post('/evidences/$evidenceId/process');
    return {...evidence, 'status': 'pending'};
  }

  Future<List<Map<String, dynamic>>> obtenerReportesCercanos({
    required double latitud,
    required double longitud,
    double radio = 10000,
  }) async {
    final response = await _api.get(
      '/evidences/nearby',
      query: {'latitude': latitud, 'longitude': longitud, 'radius': radio},
    );
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerMisAportes({int limit = 50}) async {
    final response = await _api.get('/evidences', query: {'limit': limit});
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  String _contentType(String filename) {
    final extension = path.extension(filename).toLowerCase();
    if (extension == '.png') return 'image/png';
    if (extension == '.webp') return 'image/webp';
    return 'image/jpeg';
  }
}
