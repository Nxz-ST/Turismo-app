import 'package:flutter/material.dart';

/// Opciones cerradas del perfil de viajero. Deben coincidir con
/// `app/schemas/profile.py` y `sql/017_user_profiles.sql` del backend.
class TravelerProfileOptions {
  const TravelerProfileOptions._();

  static const travelerTypes = <String, String>{
    'local': 'Local',
    'national': 'Nacional',
    'foreign': 'Extranjero',
  };

  static const travelerTypeHints = <String, String>{
    'local': 'Vivo en la región que visito',
    'national': 'Viajo desde otra región del Perú',
    'foreign': 'Vengo de otro país',
  };

  static const peruRegions = <String>[
    'Amazonas',
    'Áncash',
    'Apurímac',
    'Arequipa',
    'Ayacucho',
    'Cajamarca',
    'Callao',
    'Cusco',
    'Huancavelica',
    'Huánuco',
    'Ica',
    'Junín',
    'La Libertad',
    'Lambayeque',
    'Lima',
    'Loreto',
    'Madre de Dios',
    'Moquegua',
    'Pasco',
    'Piura',
    'Puno',
    'San Martín',
    'Tacna',
    'Tumbes',
    'Ucayali',
  ];

  static const countries = <String>[
    'Alemania',
    'Argentina',
    'Bolivia',
    'Brasil',
    'Canadá',
    'Chile',
    'Colombia',
    'Ecuador',
    'España',
    'Estados Unidos',
    'Francia',
    'Italia',
    'México',
    'Reino Unido',
    'Venezuela',
    'Otro país',
  ];

  static const ageRanges = <String>[
    '18-24',
    '25-34',
    '35-44',
    '45-54',
    '55-64',
    '65+',
  ];

  static const interests = <String, (String, IconData)>{
    'nature': ('Naturaleza', Icons.forest_outlined),
    'adventure': ('Aventura', Icons.hiking),
    'culture': ('Cultura', Icons.account_balance_outlined),
    'beach': ('Playa', Icons.beach_access_outlined),
    'gastronomy': ('Gastronomía', Icons.restaurant_outlined),
    'photography': ('Fotografía', Icons.photo_camera_outlined),
    'relaxation': ('Descanso', Icons.spa_outlined),
  };

  static const hikingLevels = <String, (String, String)>{
    'beginner': ('Principiante', 'Caminatas cortas y sin altura'),
    'intermediate': ('Intermedio', 'Algunas horas, desnivel moderado'),
    'advanced': ('Avanzado', 'Alta montaña, varios días'),
  };

  static const referralSources = <String, String>{
    'friends': 'Amigos o familia',
    'social_media': 'Redes sociales',
    'university': 'Universidad',
    'agency': 'Agencia de turismo',
    'search': 'Buscador o tienda de apps',
    'other': 'Otro',
  };
}
