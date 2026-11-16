import '../models/tourism_benefit.dart';

class MockBenefitCatalog {
  const MockBenefitCatalog._();

  static List<TourismBenefit> forPlace({
    required String placeName,
    required String category,
  }) {
    final normalizedCategory = category.toLowerCase();
    final experience = _experienceFor(normalizedCategory);
    return [
      TourismBenefit(
        id: 'andes-conecta',
        agencyName: 'Andes Conecta',
        agencyInitials: 'AC',
        title: '$experience en $placeName',
        summary:
            'Salida de día completo con acompañamiento local y horarios coordinados.',
        benefitLabel: '10% de descuento',
        originalPrice: 150,
        rutaAmigaPrice: 135,
        duration: 'Día completo',
        included: const [
          'Movilidad de ida y retorno',
          'Acompañamiento de guía local',
          'Asistencia durante el recorrido',
        ],
        conditions: const [
          'Reserva con 24 horas de anticipación',
          'Sujeto a disponibilidad y condiciones climáticas',
          'Beneficio válido para una persona',
        ],
        rating: 4.8,
        recommended: true,
      ),
      TourismBenefit(
        id: 'origen-peru',
        agencyName: 'Origen Perú Tours',
        agencyInitials: 'OP',
        title: 'Ruta acompañada a $placeName',
        summary:
            'Experiencia en grupo pequeño con orientación previa y paradas fotográficas.',
        benefitLabel: 'Transporte incluido',
        originalPrice: 128,
        rutaAmigaPrice: 128,
        duration: '7 horas',
        included: const [
          'Transporte turístico compartido',
          'Guía durante la experiencia',
          'Kit básico de orientación',
        ],
        conditions: const [
          'Mínimo cuatro participantes',
          'Punto de encuentro por confirmar',
          'No incluye alimentación ni entrada al atractivo',
        ],
        rating: 4.6,
      ),
      TourismBenefit(
        id: 'camino-local',
        agencyName: 'Camino Local',
        agencyInitials: 'CL',
        title: 'Escapada flexible a $placeName',
        summary:
            'Opción ligera para viajeros que prefieren organizar parte de la visita por cuenta propia.',
        benefitLabel: '15% de descuento',
        originalPrice: 120,
        rutaAmigaPrice: 102,
        duration: '5 horas',
        included: const [
          'Traslado desde el punto de encuentro',
          'Recomendaciones de un anfitrión local',
          'Tiempo libre para explorar',
        ],
        conditions: const [
          'Reserva con 48 horas de anticipación',
          'Cupos limitados por salida',
          'Beneficio no acumulable con otras promociones',
        ],
        rating: 4.5,
      ),
    ];
  }

  static String _experienceFor(String category) {
    if (category.contains('lago') || category.contains('laguna')) {
      return 'Experiencia de naturaleza';
    }
    if (category.contains('cascada')) return 'Caminata y cascada';
    if (category.contains('playa')) return 'Día de playa';
    if (category.contains('arqueol')) return 'Ruta cultural guiada';
    if (category.contains('bosque')) return 'Inmersión en el bosque';
    return 'Experiencia turística';
  }
}
