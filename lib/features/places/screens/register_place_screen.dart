import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/friendly_error.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/presence_service.dart';
import '../services/report_place_service.dart';
import '../models/existing_place_target.dart';
import '../widgets/place_profile_questionnaire.dart';

class RegisterPlaceScreen extends StatefulWidget {
  const RegisterPlaceScreen({super.key, this.existingPlace});

  final ExistingPlaceTarget? existingPlace;

  @override
  State<RegisterPlaceScreen> createState() => _RegisterPlaceScreenState();
}

class _RegisterPlaceScreenState extends State<RegisterPlaceScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ReportPlaceService _reportPlaceService = ReportPlaceService();

  bool isSavingReport = false;

  File? selectedImage;
  Position? currentPosition;
  ImageSource? selectedSource;
  DateTime? selectedCapturedAt;
  Map<String, dynamic>? selectedPresenceSample;
  List<Map<String, dynamic>> recentPresenceSamples = [];
  Timer? _countdownTimer;

  bool isGettingLocation = true;
  bool isAnalyzingImage = false;
  bool imageAccepted = false;

  String? aiCategory;
  double? aiConfidence;
  String? aiMessage;
  int _currentStep = 0;
  bool _allowPop = false;

  String get _draftKey {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'place_contribution_draft_v2_${userId}_${widget.existingPlace?.id ?? 'new'}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingPlace != null) {
      nameController.text = widget.existingPlace!.name;
      descriptionController.text =
          'Evidencia adicional para ${widget.existingPlace!.name}';
    }
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _restoreDraft();
    _loadLocation();
  }

  Future<void> _restoreDraft() async {
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString('${_draftKey}_name');
    final description = preferences.getString('${_draftKey}_description');
    final imagePath = preferences.getString('${_draftKey}_image');
    final source = preferences.getString('${_draftKey}_source');
    final capturedAt = preferences.getString('${_draftKey}_captured_at');
    final step = preferences.getInt('${_draftKey}_step');
    if (!mounted) return;
    final image = imagePath == null ? null : File(imagePath);
    setState(() {
      if (name != null && name.isNotEmpty) nameController.text = name;
      if (description != null) descriptionController.text = description;
      if (image != null && image.existsSync()) selectedImage = image;
      selectedSource = source == 'camera'
          ? ImageSource.camera
          : source == 'gallery'
          ? ImageSource.gallery
          : selectedSource;
      selectedCapturedAt = DateTime.tryParse(capturedAt ?? '');
      _currentStep = (step ?? 0).clamp(0, 3);
    });
  }

  Future<void> _saveDraft({bool exit = false, bool notifyUser = true}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '${_draftKey}_name',
      nameController.text.trim(),
    );
    await preferences.setString(
      '${_draftKey}_description',
      descriptionController.text.trim(),
    );
    await preferences.setInt('${_draftKey}_step', _currentStep);
    if (selectedImage != null) {
      final imagePath = await _persistDraftImage(selectedImage!);
      selectedImage = File(imagePath);
      await preferences.setString('${_draftKey}_image', imagePath);
    }
    if (selectedSource != null) {
      await preferences.setString(
        '${_draftKey}_source',
        selectedSource == ImageSource.camera ? 'camera' : 'gallery',
      );
    }
    if (selectedCapturedAt != null) {
      await preferences.setString(
        '${_draftKey}_captured_at',
        selectedCapturedAt!.toIso8601String(),
      );
    }
    if (!mounted) return;
    if (!exit) {
      if (notifyUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Borrador guardado en este dispositivo.'),
          ),
        );
      }
      return;
    }
    setState(() => _allowPop = true);
    await Future<void>.delayed(Duration.zero);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clearDraft() async {
    final preferences = await SharedPreferences.getInstance();
    final imagePath = preferences.getString('${_draftKey}_image');
    for (final suffix in const [
      'name',
      'description',
      'image',
      'source',
      'captured_at',
      'step',
    ]) {
      await preferences.remove('${_draftKey}_$suffix');
    }
    await _deleteManagedDraftImage(imagePath);
  }

  Future<String> _persistDraftImage(File image) async {
    if (!await image.exists()) return image.path;
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(root.path, 'rutaamiga', 'drafts'));
    await directory.create(recursive: true);
    final extension = path.extension(image.path).toLowerCase();
    final safeKey = _draftKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destination = File(
      path.join(
        directory.path,
        '$safeKey${extension.isEmpty ? '.jpg' : extension}',
      ),
    );
    if (path.equals(image.path, destination.path)) return destination.path;
    await image.copy(destination.path);
    return destination.path;
  }

  Future<void> _deleteManagedDraftImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    final root = await getApplicationDocumentsDirectory();
    final draftsDirectory = path.join(root.path, 'rutaamiga', 'drafts');
    if (!path.isWithin(draftsDirectory, imagePath)) return;
    final image = File(imagePath);
    if (await image.exists()) await image.delete();
  }

  Future<void> _requestExit() async {
    if (isSavingReport) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Quieres continuar después?',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Puedes guardar este aporte en el dispositivo y retomarlo cuando quieras.',
                style: TextStyle(color: AppColors.textLight),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, 'save'),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Guardar borrador y salir'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext, 'discard'),
                  child: const Text('Descartar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == 'save') {
      await _saveDraft(exit: true);
    } else if (choice == 'discard') {
      await _clearDraft();
      if (!mounted) return;
      setState(() => _allowPop = true);
      await Future<void>.delayed(Duration.zero);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final currentSample = await PresenceService.instance.recordPosition(
        position,
        source: 'manual',
        force: true,
      );
      List<Map<String, dynamic>> recent = const [];
      try {
        recent = await PresenceService.instance.recent(limit: 12);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        currentPosition = position;
        recentPresenceSamples = recent;
        selectedPresenceSample =
            currentSample ?? (recent.isNotEmpty ? recent.first : null);
        isGettingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isGettingLocation = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (pickedFile == null) return;

    if (source == ImageSource.camera && currentPosition != null) {
      try {
        final captureSample = await PresenceService.instance.recordPosition(
          currentPosition!,
          source: 'capture',
          force: true,
        );
        if (captureSample != null) selectedPresenceSample = captureSample;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      selectedImage = File(pickedFile.path);
      selectedSource = source;
      selectedCapturedAt = DateTime.now();
      isAnalyzingImage = false;
      imageAccepted = false;
      aiCategory = null;
      aiConfidence = null;
      aiMessage =
          'Imagen lista. Completa el nombre y envía el reporte para analizarla.';
    });
  }

  bool get _hasValidLocation =>
      selectedPresenceSample != null || currentPosition != null;

  Future<void> _submitReport() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final image = selectedImage;

    if (name.isEmpty) {
      _showStepMessage('Escribe un nombre para el lugar.');
      setState(() => _currentStep = 2);
      return;
    }
    if (image == null || !image.existsSync()) {
      _showStepMessage('Vuelve a seleccionar la fotografía para continuar.');
      setState(() => _currentStep = 0);
      return;
    }

    // La ubicación puede terminar de cargarse después de restaurar un
    // borrador. Antes de rechazar el aporte, la recuperamos una vez más.
    if (!_hasValidLocation) {
      setState(() => isGettingLocation = true);
      await _loadLocation();
    }
    if (!_hasValidLocation) {
      _showStepMessage(
        'No pudimos recuperar tu ubicación. Revisa el permiso de GPS e inténtalo otra vez.',
      );
      setState(() => _currentStep = 1);
      return;
    }

    try {
      setState(() {
        isSavingReport = true;
        isAnalyzingImage = true;
        aiMessage = 'Subiendo y analizando la evidencia desde el servidor...';
      });

      final result = await _reportPlaceService.submitAndProcess(
        imageFile: image,
        nombre: name,
        descripcion: description,
        latitud: _selectedLatitude,
        longitud: _selectedLongitude,
        altitud: _selectedAltitude,
        gpsAccuracy: _selectedAccuracy,
        captureSource: selectedSource == ImageSource.camera
            ? 'camera'
            : 'gallery',
        capturedAt: selectedCapturedAt ?? DateTime.now(),
        presenceSampleId: selectedPresenceSample?['id']?.toString(),
        targetPlaceId: widget.existingPlace?.isCommunity == true
            ? null
            : int.tryParse(widget.existingPlace?.id ?? ''),
        targetCommunityPlaceId: widget.existingPlace?.isCommunity == true
            ? widget.existingPlace?.id
            : null,
      );

      if (!mounted) return;

      final estado = result['status']?.toString() ?? 'failed';
      final motivo = friendlyDecisionReason(result['decision_reason']);
      final categoria =
          result['predicted_category']?.toString() ?? 'No determinada';
      final confianza =
          double.tryParse(result['confidence']?.toString() ?? '0') ?? 0;
      final accepted = estado == 'candidate' || estado == 'validated';
      final queued = const {
        'offline_pending',
        'pending',
        'processing_ai',
        'processing_gis',
      }.contains(estado);

      final title = switch (estado) {
        'candidate' || 'validated' => 'Aporte validado',
        'needs_review' => 'Caso enviado a revisión',
        'duplicate' => 'Aporte asociado para revisión',
        'rejected' => 'La evidencia no fue aceptada',
        'offline_pending' => 'Aporte guardado sin conexión',
        'pending' ||
        'processing_ai' ||
        'processing_gis' => 'Evidencia enviada a procesamiento',
        _ => 'No se pudo completar la validación',
      };

      setState(() {
        isSavingReport = false;
        isAnalyzingImage = false;
        imageAccepted = accepted;
        aiCategory = categoria;
        aiConfidence = confianza;
        aiMessage = '$title\n$motivo';
      });

      if (estado == 'rejected') {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 34,
            ),
            title: const Text('Necesitamos otra fotografía'),
            content: Text(motivo),
            actions: [
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tomar otra fotografía'),
              ),
            ],
          ),
        );
        if (mounted) setState(() => _currentStep = 0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              estado == 'offline_pending'
                  ? 'Aporte guardado sin conexión. Se enviará automáticamente cuando recuperes internet.'
                  : queued
                  ? 'Aporte enviado. Te avisaremos aquí cuando termine la validación.'
                  : accepted || estado == 'needs_review'
                  ? 'Evidencia registrada correctamente.'
                  : title,
            ),
          ),
        );
      }

      if (!mounted) return;
      if (estado == 'validated') {
        final contributionType =
            result['contribution_type']?.toString() ?? 'new_place';
        final snapshot = Map<String, dynamic>.from(
          result['target_place_snapshot'] as Map? ?? const {},
        );
        final answers = await showPlaceProfileQuestionnaire(
          context,
          existingPlace: contributionType == 'existing_place',
          placeName: snapshot['nombre']?.toString() ?? name,
        );
        if (answers != null) {
          try {
            await _reportPlaceService.completeProfile(
              evidenceId: result['id'].toString(),
              answers: answers,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Información del lugar guardada.'),
                ),
              );
            }
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(friendlyErrorMessage(error))),
              );
            }
          }
        }
      }

      if (accepted || queued || estado == 'needs_review') {
        await _clearDraft();
        if (!mounted) return;
        setState(() => _allowPop = true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      final message = friendlyErrorMessage(
        e,
        fallback:
            'No pudimos guardar el aporte. Tus datos siguen en el formulario para que puedas intentarlo nuevamente.',
      );

      setState(() {
        isSavingReport = false;
        isAnalyzingImage = false;
        aiMessage = message;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  LatLng get _currentLatLng {
    return LatLng(_selectedLatitude, _selectedLongitude);
  }

  double get _selectedLatitude =>
      double.tryParse(selectedPresenceSample?['latitude']?.toString() ?? '') ??
      currentPosition?.latitude ??
      -12.0464;
  double get _selectedLongitude =>
      double.tryParse(selectedPresenceSample?['longitude']?.toString() ?? '') ??
      currentPosition?.longitude ??
      -77.0428;
  double get _selectedAltitude =>
      double.tryParse(selectedPresenceSample?['altitude']?.toString() ?? '') ??
      currentPosition?.altitude ??
      0;
  double get _selectedAccuracy =>
      double.tryParse(
        selectedPresenceSample?['accuracy_m']?.toString() ?? '',
      ) ??
      currentPosition?.accuracy ??
      10000;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _requestExit,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
        ),
        title: Text(
          widget.existingPlace == null
              ? 'Aportar un lugar'
              : 'Aportar evidencia',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: () => _saveDraft(),
            child: const Text('Guardar'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: _progressHeader(),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 230),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                key: ValueKey(_currentStep),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: _stepContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _wizardNavigation(),
    );
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: scaffold,
    );
  }

  Widget _progressHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'PASO ${_currentStep + 1} DE 4',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            _stepLabels[_currentStep],
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 5,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : const Color(0xFFDCE6E2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  static const _stepLabels = [
    'Fotografía',
    'Ubicación',
    'Información',
    'Confirmación',
  ];

  Widget _stepContent() => switch (_currentStep) {
    0 => _photoStep(),
    1 => _locationStep(),
    2 => _detailsStep(),
    _ => _reviewStep(),
  };

  Widget _stepIntro(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 27,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _photoStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'Muéstranos el lugar',
        'Usa una fotografía clara donde el paisaje sea el protagonista.',
      ),
      const SizedBox(height: 22),
      _imageCard(),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: Icons.camera_alt_rounded,
              label: selectedImage == null ? 'Abrir cámara' : 'Otra foto',
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              icon: Icons.photo_library_outlined,
              label: 'Galería',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Evita capturas de pantalla, fotografías borrosas o imágenes donde no se pueda reconocer el entorno.',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _locationStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'Confirma tu visita',
        'Selecciona la ubicación que corresponda al momento en que estuviste en el lugar.',
      ),
      const SizedBox(height: 20),
      _locationMapCard(),
    ],
  );

  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'Identifica el lugar',
        'No necesitas saber si ya está registrado. RutaAmiga comparará el nombre, la ubicación y la fotografía; después te hará preguntas sencillas.',
      ),
      const SizedBox(height: 24),
      const Text(
        'Nombre del lugar',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      _inputField(
        controller: nameController,
        hint: 'Ej. Cascada de Pumacayán',
        icon: Icons.place_outlined,
      ),
      const SizedBox(height: 18),
      const Text(
        'Nota breve · opcional',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      _inputField(
        controller: descriptionController,
        hint:
            'Puedes añadir una referencia; la ficha se construirá con preguntas verificables.',
        icon: Icons.notes_rounded,
        maxLines: 5,
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.textLight,
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'No necesitas identificar la categoría; el sistema contrastará la fotografía y el entorno.',
              style: TextStyle(color: AppColors.textLight, fontSize: 10),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepIntro(
        'Todo listo para aportar',
        'Revisa la evidencia antes de enviarla. La validación continuará en segundo plano.',
      ),
      const SizedBox(height: 20),
      if (selectedImage != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            selectedImage!,
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
          ),
        ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E9E6)),
        ),
        child: Column(
          children: [
            _reviewRow(
              Icons.place_outlined,
              'Lugar',
              nameController.text.trim().isEmpty
                  ? 'Sin nombre'
                  : nameController.text.trim(),
              () => setState(() => _currentStep = 2),
            ),
            const Divider(height: 25),
            _reviewRow(
              Icons.my_location_rounded,
              'Ubicación',
              '${_selectedLatitude.toStringAsFixed(5)}, ${_selectedLongitude.toStringAsFixed(5)}',
              () => setState(() => _currentStep = 1),
            ),
            const Divider(height: 25),
            _reviewRow(
              selectedSource == ImageSource.camera
                  ? Icons.camera_alt_outlined
                  : Icons.photo_library_outlined,
              'Fotografía',
              selectedSource == ImageSource.camera
                  ? 'Tomada desde la cámara'
                  : 'Elegida de la galería',
              () => setState(() => _currentStep = 0),
            ),
            const Divider(height: 25),
            _reviewRow(
              Icons.gps_fixed_rounded,
              'Precisión GPS',
              '${_selectedAccuracy.toStringAsFixed(0)} metros',
              () => setState(() => _currentStep = 1),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'RutaAmiga verificará si es un nuevo descubrimiento o un aporte para un lugar existente. La fotografía, ubicación y fecha quedarán como evidencia auditable.',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _reviewRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onEdit,
  ) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: onEdit,
        tooltip: 'Editar $label',
        icon: const Icon(Icons.edit_outlined, size: 19),
      ),
    ],
  );

  Widget _wizardNavigation() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE1E9E6))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                onPressed: isSavingReport
                    ? null
                    : () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                child: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: isSavingReport ? null : _advanceWizard,
                icon: isSavingReport
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _currentStep == 3
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  isSavingReport
                      ? 'Enviando aporte...'
                      : _currentStep == 3
                      ? 'Enviar aporte'
                      : 'Continuar',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _advanceWizard() async {
    if (_currentStep == 0 && selectedImage == null) {
      _showStepMessage('Agrega una fotografía para continuar.');
      return;
    }
    if (_currentStep == 1 && !_hasValidLocation) {
      _showStepMessage('Necesitamos una ubicación para respaldar la visita.');
      return;
    }
    if (_currentStep == 2 && nameController.text.trim().isEmpty) {
      _showStepMessage('Escribe un nombre para el lugar.');
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      await _saveDraft(notifyUser: false);
      return;
    }
    await _submitReport();
  }

  void _showStepMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1E9E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE1E9E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _locationMapCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: isGettingLocation
          ? const Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 14),
                Text('Obteniendo ubicación...'),
              ],
            )
          : currentPosition == null
          ? const Text(
              'No se pudo obtener la ubicación.',
              style: TextStyle(color: AppColors.textLight),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ubicación seleccionada',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '± ${_selectedAccuracy.toStringAsFixed(0)} m',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 235,
                    child: GoogleMap(
                      key: ValueKey(selectedPresenceSample?['id'] ?? 'current'),
                      initialCameraPosition: CameraPosition(
                        target: _currentLatLng,
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('report_location'),
                          position: _currentLatLng,
                          infoWindow: const InfoWindow(
                            title: 'Ubicación del reporte',
                          ),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  selectedSource == ImageSource.gallery
                      ? 'Imagen de galería: selecciona abajo la visita que corresponda al lugar. El panel conservará esta diferencia para la revisión.'
                      : 'La ubicación fue capturada desde el dispositivo al momento del registro.',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                if (recentPresenceSamples.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Elige cuándo estuviste en el lugar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentPresenceSamples.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final sample = recentPresenceSamples[index];
                        final selected =
                            sample['id'] == selectedPresenceSample?['id'];
                        return ChoiceChip(
                          selected: selected,
                          avatar: Icon(
                            sample['source'] == 'capture'
                                ? Icons.camera_alt
                                : Icons.location_on,
                            size: 16,
                          ),
                          label: Text(_sampleLabel(sample)),
                          onSelected: (_) =>
                              setState(() => selectedPresenceSample = sample),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _presenceCountdownCard(),
                ],
              ],
            ),
    );
  }

  String _sampleLabel(Map<String, dynamic> sample) {
    final parsed = DateTime.tryParse(
      sample['recorded_at']?.toString() ?? '',
    )?.toLocal();
    if (parsed == null) return 'Ubicación reciente';
    final now = DateTime.now();
    if (now.difference(parsed).inMinutes < 2) return 'Ahora';
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.day}/${parsed.month} $hour:$minute';
  }

  Widget _presenceCountdownCard() {
    final expiry = DateTime.tryParse(
      selectedPresenceSample?['expires_at']?.toString() ?? '',
    )?.toLocal();
    if (expiry == null) return const SizedBox.shrink();
    final remaining = expiry.difference(DateTime.now());
    final expired = remaining.isNegative;
    final urgent = !expired && remaining <= const Duration(hours: 2);
    final hours = remaining.inHours.clamp(0, 24);
    final minutes = (remaining.inMinutes % 60).clamp(0, 59);
    final color = expired
        ? Colors.grey
        : urgent
        ? Colors.deepOrange
        : remaining <= const Duration(hours: 12)
        ? Colors.amber.shade800
        : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              expired
                  ? 'Este respaldo GPS venció. Puedes enviar la evidencia, pero requerirá otras señales de validación.'
                  : 'Respaldo GPS disponible por $hours h ${minutes.toString().padLeft(2, '0')} min. El tiempo se cuenta desde esta visita y no se reinicia al abrir la app.',
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageCard() {
    return Container(
      width: double.infinity,
      height: 315,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE5EFEB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD8E5E0)),
      ),
      child: selectedImage == null
          ? Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  right: -34,
                  bottom: -40,
                  child: Icon(
                    Icons.landscape_rounded,
                    size: 210,
                    color: AppColors.primary.withValues(alpha: .07),
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        size: 31,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Añade la evidencia principal',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'JPG, PNG o WEBP',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(selectedImage!, fit: BoxFit.cover),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedSource == ImageSource.camera
                              ? Icons.camera_alt_rounded
                              : Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedSource == ImageSource.camera
                              ? 'Tomada ahora'
                              : 'Desde galería',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E9E6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
