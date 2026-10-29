class TouristPlaceModel {
  final int id;
  final int codigo;
  final String nombre;
  final String categoria;
  final String departamento;
  final String provincia;
  final String distrito;
  final double latitud;
  final double longitud;
  final double altitud;
  final String coordinateQuality;
  final double? accessLatitud;
  final double? accessLongitud;
  final String accessNotes;

  final String descripcion;
  final String tipoIngreso;
  final String tarifaAdulto;
  final String tarifaNino;
  final String tarifaExtranjero;
  final String epocaVisita;
  final String horarioVisita;
  final String recomendacionesVisita;
  final String actividades;

  TouristPlaceModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.departamento,
    required this.provincia,
    required this.distrito,
    required this.latitud,
    required this.longitud,
    required this.altitud,
    this.coordinateQuality = 'reported',
    this.accessLatitud,
    this.accessLongitud,
    this.accessNotes = '',
    required this.descripcion,
    required this.tipoIngreso,
    required this.tarifaAdulto,
    required this.tarifaNino,
    required this.tarifaExtranjero,
    required this.epocaVisita,
    required this.horarioVisita,
    required this.recomendacionesVisita,
    required this.actividades,
  });

  factory TouristPlaceModel.fromJson(Map<String, dynamic> json) {
    final codigo = int.tryParse(json['Código']?.toString() ?? '0') ?? 0;
    return TouristPlaceModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? codigo,
      codigo: codigo,
      nombre: json['Nombre']?.toString() ?? '',
      categoria: json['Categoría']?.toString() ?? '',
      departamento: json['Departamento']?.toString() ?? '',
      provincia: json['Provincia']?.toString() ?? '',
      distrito: json['Distrito']?.toString() ?? '',
      latitud: double.tryParse(json['Latitud']?.toString() ?? '') ?? 0.0,
      longitud: double.tryParse(json['Longitud']?.toString() ?? '') ?? 0.0,
      altitud: double.tryParse(json['Altitud']?.toString() ?? '') ?? 0.0,
      coordinateQuality: json['coordinate_quality']?.toString() ?? 'reported',
      accessLatitud: double.tryParse(json['access_latitud']?.toString() ?? ''),
      accessLongitud: double.tryParse(
        json['access_longitud']?.toString() ?? '',
      ),
      accessNotes: json['access_notes']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      tipoIngreso: json['tipo_ingreso']?.toString() ?? '',
      tarifaAdulto: json['tarifa_adulto']?.toString() ?? '',
      tarifaNino: json['tarifa_nino']?.toString() ?? '',
      tarifaExtranjero: json['tarifa_extranjero']?.toString() ?? '',
      epocaVisita: json['epoca_visita']?.toString() ?? '',
      horarioVisita: json['horario_visita']?.toString() ?? '',
      recomendacionesVisita: json['recomendaciones_visita']?.toString() ?? '',
      actividades: json['actividades']?.toString() ?? '',
    );
  }

  factory TouristPlaceModel.fromSupabase(Map<String, dynamic> json) {
    return TouristPlaceModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      codigo: int.tryParse(json['codigo']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria_texto']?.toString() ?? '',
      departamento: json['departamento']?.toString() ?? '',
      provincia: json['provincia']?.toString() ?? '',
      distrito: json['distrito']?.toString() ?? '',
      latitud: double.tryParse(json['latitud']?.toString() ?? '') ?? 0.0,
      longitud: double.tryParse(json['longitud']?.toString() ?? '') ?? 0.0,
      altitud: double.tryParse(json['altitud']?.toString() ?? '') ?? 0.0,
      coordinateQuality: json['coordinate_quality']?.toString() ?? 'reported',
      accessLatitud: double.tryParse(json['access_latitud']?.toString() ?? ''),
      accessLongitud: double.tryParse(
        json['access_longitud']?.toString() ?? '',
      ),
      accessNotes: json['access_notes']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      tipoIngreso: json['tipo_ingreso']?.toString() ?? '',
      tarifaAdulto: json['tarifa_adulto']?.toString() ?? '',
      tarifaNino: json['tarifa_nino']?.toString() ?? '',
      tarifaExtranjero: json['tarifa_extranjero']?.toString() ?? '',
      epocaVisita: json['epoca_visita']?.toString() ?? '',
      horarioVisita: json['horario_visita']?.toString() ?? '',
      recomendacionesVisita: json['recomendaciones_visita']?.toString() ?? '',
      actividades: json['actividades']?.toString() ?? '',
    );
  }

  factory TouristPlaceModel.fromStorage(Map<String, dynamic> json) {
    return TouristPlaceModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      codigo: int.tryParse(json['codigo']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      departamento: json['departamento']?.toString() ?? '',
      provincia: json['provincia']?.toString() ?? '',
      distrito: json['distrito']?.toString() ?? '',
      latitud: double.tryParse(json['latitud']?.toString() ?? '') ?? 0,
      longitud: double.tryParse(json['longitud']?.toString() ?? '') ?? 0,
      altitud: double.tryParse(json['altitud']?.toString() ?? '') ?? 0,
      coordinateQuality: json['coordinate_quality']?.toString() ?? 'reported',
      accessLatitud: double.tryParse(json['access_latitud']?.toString() ?? ''),
      accessLongitud: double.tryParse(
        json['access_longitud']?.toString() ?? '',
      ),
      accessNotes: json['access_notes']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      tipoIngreso: json['tipo_ingreso']?.toString() ?? '',
      tarifaAdulto: json['tarifa_adulto']?.toString() ?? '',
      tarifaNino: json['tarifa_nino']?.toString() ?? '',
      tarifaExtranjero: json['tarifa_extranjero']?.toString() ?? '',
      epocaVisita: json['epoca_visita']?.toString() ?? '',
      horarioVisita: json['horario_visita']?.toString() ?? '',
      recomendacionesVisita: json['recomendaciones_visita']?.toString() ?? '',
      actividades: json['actividades']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre,
    'categoria': categoria,
    'departamento': departamento,
    'provincia': provincia,
    'distrito': distrito,
    'latitud': latitud,
    'longitud': longitud,
    'altitud': altitud,
    'coordinate_quality': coordinateQuality,
    'access_latitud': accessLatitud,
    'access_longitud': accessLongitud,
    'access_notes': accessNotes,
    'descripcion': descripcion,
    'tipo_ingreso': tipoIngreso,
    'tarifa_adulto': tarifaAdulto,
    'tarifa_nino': tarifaNino,
    'tarifa_extranjero': tarifaExtranjero,
    'epoca_visita': epocaVisita,
    'horario_visita': horarioVisita,
    'recomendaciones_visita': recomendacionesVisita,
    'actividades': actividades,
  };

  TouristPlaceModel copyWith({String? coordinateQuality}) => TouristPlaceModel(
    id: id,
    codigo: codigo,
    nombre: nombre,
    categoria: categoria,
    departamento: departamento,
    provincia: provincia,
    distrito: distrito,
    latitud: latitud,
    longitud: longitud,
    altitud: altitud,
    coordinateQuality: coordinateQuality ?? this.coordinateQuality,
    accessLatitud: accessLatitud,
    accessLongitud: accessLongitud,
    accessNotes: accessNotes,
    descripcion: descripcion,
    tipoIngreso: tipoIngreso,
    tarifaAdulto: tarifaAdulto,
    tarifaNino: tarifaNino,
    tarifaExtranjero: tarifaExtranjero,
    epocaVisita: epocaVisita,
    horarioVisita: horarioVisita,
    recomendacionesVisita: recomendacionesVisita,
    actividades: actividades,
  );

  bool get hasVerifiedAccess => accessLatitud != null && accessLongitud != null;

  double get navigationLatitud => accessLatitud ?? latitud;

  double get navigationLongitud => accessLongitud ?? longitud;
}
