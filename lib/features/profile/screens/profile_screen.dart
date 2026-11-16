import 'package:flutter/material.dart';
import '../../legal/screens/privacy_center_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/app_accessibility_service.dart';
import '../../../core/widgets/main_navigation_bar.dart';
import '../../admin/screens/admin_review_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../places/screens/my_contributions_screen.dart';
import '../../places/services/report_place_service.dart';
import '../../routes/services/route_visit_service.dart';
import 'explorer_tools_screens.dart';
import 'activity_inbox_screen.dart';
import 'my_trip_screen.dart';
import 'passport_screen.dart';
import 'saved_places_screen.dart';
import 'place_comparison_screen.dart';
import 'personalized_recommendations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _styleOptions = <(IconData, String)>[
    (Icons.backpack_outlined, 'Mochilero'),
    (Icons.hiking_outlined, 'Trekking'),
    (Icons.forest_outlined, 'Naturaleza'),
    (Icons.account_balance_outlined, 'Cultura'),
    (Icons.restaurant_outlined, 'Gastronomía'),
    (Icons.kayaking_outlined, 'Aventura'),
    (Icons.family_restroom_outlined, 'Familiar'),
  ];

  late Future<_ProfileData> _future;
  String get _userKey =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final contributionsFuture = ReportPlaceService().obtenerMisAportes();
    final visitsFuture = RouteVisitService().passport();
    final preferencesFuture = SharedPreferences.getInstance();
    final contributions = await contributionsFuture;
    final visits = await visitsFuture;
    final preferences = await preferencesFuture;
    final styles = preferences.getStringList(
      'rutaamiga_travel_styles_v1_$_userKey',
    );
    return _ProfileData(
      contributions: contributions,
      visits: visits,
      biography:
          preferences.getString('rutaamiga_profile_bio_v1_$_userKey') ??
          'Explorando el Perú, un rincón a la vez.',
      styles: styles == null || styles.isEmpty
          ? const ['Mochilero', 'Naturaleza']
          : styles,
    );
  }

  Future<void> _refresh() async {
    final next = _loadProfile();
    setState(() => _future = next);
    await next;
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile(_ProfileData data) async {
    final user = Supabase.instance.client.auth.currentUser;
    final nameController = TextEditingController(
      text: user?.userMetadata?['name']?.toString() ?? 'Viajero RutaAmiga',
    );
    final biographyController = TextEditingController(text: data.biography);
    final selected = data.styles.toSet();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu perfil viajero',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cuéntanos cómo exploras para personalizar tu experiencia.',
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre visible',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: biographyController,
                  maxLength: 100,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Una frase sobre ti',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Cómo te gusta viajar?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _styleOptions)
                      FilterChip(
                        avatar: Icon(option.$1, size: 17),
                        label: Text(option.$2),
                        selected: selected.contains(option.$2),
                        onSelected: (value) => setSheetState(() {
                          if (value) {
                            selected.add(option.$2);
                          } else if (selected.length > 1) {
                            selected.remove(option.$2);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final preferences = await SharedPreferences.getInstance();
                      await preferences.setString(
                        'rutaamiga_profile_bio_v1_$_userKey',
                        biographyController.text.trim(),
                      );
                      await preferences.setStringList(
                        'rutaamiga_travel_styles_v1_$_userKey',
                        selected.toList(),
                      );
                      await Supabase.instance.client.auth.updateUser(
                        UserAttributes(data: {'name': name}),
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    child: const Text('Guardar perfil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    biographyController.dispose();
    if (saved == true) await _refresh();
  }

  Future<void> _showSettings() async {
    final preferences = await SharedPreferences.getInstance();
    var notifications =
        preferences.getBool('rutaamiga_notifications_v1') ?? true;
    var presence = preferences.getBool('rutaamiga_presence_support_v1') ?? true;
    var largeText = AppAccessibilityService.instance.largeText;
    var highContrast = AppAccessibilityService.instance.highContrast;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text(
                      'Notificaciones',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Aportes y recordatorios de viaje'),
                    value: notifications,
                    onChanged: (value) async {
                      setSheetState(() => notifications = value);
                      await preferences.setBool(
                        'rutaamiga_notifications_v1',
                        value,
                      );
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.text_increase_rounded),
                    title: const Text(
                      'Texto más grande',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Aumenta el tamaño en toda la aplicación',
                    ),
                    value: largeText,
                    onChanged: (value) async {
                      setSheetState(() => largeText = value);
                      await AppAccessibilityService.instance.setLargeText(
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.contrast_rounded),
                    title: const Text(
                      'Contraste reforzado',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Diferencia mejor botones, bordes y acciones',
                    ),
                    value: highContrast,
                    onChanged: (value) async {
                      setSheetState(() => highContrast = value);
                      await AppAccessibilityService.instance.setHighContrast(
                        value,
                      );
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.location_history_outlined),
                    title: const Text(
                      'Respaldar visitas con ubicación',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Muestras temporales para validar aportes por 24 horas',
                    ),
                    value: presence,
                    onChanged: (value) async {
                      setSheetState(() => presence = value);
                      await preferences.setBool(
                        'rutaamiga_presence_support_v1',
                        value,
                      );
                    },
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock_outline),
                    title: Text(
                      'Privacidad de ubicación',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Tu ubicación no se muestra públicamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = user?.appMetadata['role'] == 'admin';
    return Scaffold(
      bottomNavigationBar: const MainNavigationBar(currentIndex: 4),
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data ?? _ProfileData.empty();
            final name =
                user?.userMetadata?['name']?.toString() ?? 'Viajero RutaAmiga';
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mi perfil',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Novedades',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActivityInboxScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      const SizedBox(width: 7),
                      IconButton.filledTonal(
                        onPressed: _showSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _profileHero(name, user?.email ?? 'Sin correo', data),
                  const SizedBox(height: 14),
                  _stats(data),
                  const SizedBox(height: 24),
                  _passport(data),
                  const SizedBox(height: 24),
                  _title(
                    'Tu estilo de viaje',
                    TextButton(
                      onPressed: () => _editProfile(data),
                      child: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final style in data.styles)
                        Chip(
                          avatar: Icon(_styleIcon(style), size: 17),
                          label: Text(style),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _title('Insignias'),
                  const SizedBox(height: 10),
                  _badges(data),
                  const SizedBox(height: 24),
                  _yearSummary(data),
                  const SizedBox(height: 24),
                  _title('Tu aporte al mapa'),
                  const SizedBox(height: 10),
                  _contributionSummary(data),
                  const SizedBox(height: 26),
                  _title('Planifica tu viaje'),
                  const SizedBox(height: 10),
                  _tile(
                    Icons.luggage_outlined,
                    'Mi viaje',
                    'Organiza tus próximas paradas',
                    const MyTripScreen(),
                  ),
                  _tile(
                    Icons.auto_awesome_outlined,
                    'Recomendado para ti',
                    'Sugerencias según tu estilo y guardados',
                    const PersonalizedRecommendationsScreen(),
                  ),
                  _tile(
                    Icons.favorite_outline_rounded,
                    'Lugares guardados',
                    'Tus favoritos para volver cuando quieras',
                    const SavedPlacesScreen(),
                  ),
                  _tile(
                    Icons.compare_arrows_rounded,
                    'Comparar destinos',
                    'Clima, altitud, acceso y procedencia',
                    const PlaceComparisonScreen(),
                  ),
                  _tile(
                    Icons.backpack_outlined,
                    'Preparar recorrido',
                    'Lista esencial y recomendaciones',
                    const TripPreparationScreen(),
                  ),
                  const SizedBox(height: 20),
                  _title('Comunidad'),
                  const SizedBox(height: 10),
                  _tile(
                    Icons.notifications_outlined,
                    'Novedades de tu actividad',
                    'Validaciones, resultados y cuestionarios',
                    const ActivityInboxScreen(),
                  ),
                  _tile(
                    Icons.landscape_outlined,
                    'Mis aportes',
                    'Revisa su estado y resultado',
                    const MyContributionsScreen(),
                  ),
                  _tile(
                    Icons.auto_stories_outlined,
                    'Diario de exploración',
                    'Recuerdos y notas privadas',
                    const ExplorerJournalScreen(),
                  ),
                  if (isAdmin)
                    _tile(
                      Icons.admin_panel_settings_outlined,
                      'Revisión administrativa',
                      'Abre la cola técnica de validación',
                      const AdminReviewScreen(),
                    ),
                  const SizedBox(height: 16),
                  _title('Cuenta'),
                  const SizedBox(height: 10),
                  _actionTile(
                    Icons.edit_outlined,
                    'Editar perfil viajero',
                    'Nombre, descripción y estilo',
                    () => _editProfile(data),
                  ),
                  _actionTile(
                    Icons.verified_user_outlined,
                    'Privacidad y consentimiento',
                    'Mis datos de viajero, términos y derechos',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyCenterScreen(),
                      ),
                    ),
                  ),
                  _actionTile(
                    Icons.settings_outlined,
                    'Configuración y privacidad',
                    'Notificaciones y ubicación',
                    _showSettings,
                  ),
                  _logout(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileHero(String name, String email, _ProfileData data) {
    final level = data.level;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF126F6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.biography.isEmpty ? email : data.biography,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editProfile(data),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .14),
                ),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.explore, color: Color(0xFF76E2C1), size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  level.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${data.xp} XP',
                style: const TextStyle(
                  color: Color(0xFF9AF0D5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: level.progress,
              minHeight: 7,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF76E2C1)),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              level.remaining == null
                  ? 'Alcanzaste el nivel más alto'
                  : '${level.remaining} XP para ${level.nextName}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats(_ProfileData data) => _threeStats([
    ('${data.verifiedVisits}', 'Lugares'),
    ('${data.regionCount}', 'Regiones'),
    ('${data.routeCount}', 'Recorridos'),
  ]);

  Widget _contributionSummary(_ProfileData data) => _threeStats([
    ('${data.contributions.length}', 'Enviados'),
    ('${data.validatedContributions}', 'Validados'),
    ('${data.inProgressContributions}', 'En revisión'),
  ]);

  Widget _threeStats(List<(String, String)> values) => Container(
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE4EBE8)),
    ),
    child: Row(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0)
            Container(width: 1, height: 34, color: const Color(0xFFE2E9E6)),
          Expanded(
            child: Column(
              children: [
                Text(
                  values[index].$1,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  values[index].$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _passport(_ProfileData data) => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PassportScreen()),
    ),
    borderRadius: BorderRadius.circular(24),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E3CA)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .17),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              color: AppColors.warning,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pasaporte RutaAmiga',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  data.verifiedVisits == 0
                      ? 'Tu primera visita verificada aparecerá aquí.'
                      : '${data.verifiedVisits} sellos · ${data.regionCount} regiones',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.warning),
        ],
      ),
    ),
  );

  Widget _badges(_ProfileData data) => SizedBox(
    height: 190,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: data.badges.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, index) {
        final badge = data.badges[index];
        return Container(
          width: 164,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: badge.color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badge.color.withValues(alpha: .28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(badge.icon, color: badge.color),
                  const Spacer(),
                  Icon(
                    badge.completed
                        ? Icons.workspace_premium_rounded
                        : badge.count > 0
                        ? Icons.stars_rounded
                        : Icons.lock_outline,
                    size: 16,
                    color: badge.count > 0 ? badge.color : AppColors.textLight,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.tier,
                  style: TextStyle(
                    color: badge.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                badge.name,
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                badge.detail,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  minHeight: 5,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(badge.color),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _yearSummary(_ProfileData data) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE9F5F0), Color(0xFFF7F2E8)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .8),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.insights_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu ${DateTime.now().year} viajero',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.yearVisits} visitas · ${data.yearPhotos} recuerdos · ${data.regionCount} regiones',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _title(String text, [Widget? action]) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ),
      if (action != null) action,
    ],
  );

  Widget _tile(IconData icon, String title, String subtitle, Widget screen) =>
      _actionTile(
        icon,
        title,
        subtitle,
        () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      );

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );

  Widget _logout() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEEE),
      borderRadius: BorderRadius.circular(18),
    ),
    child: ListTile(
      leading: const Icon(Icons.logout, color: AppColors.danger),
      title: const Text(
        'Cerrar sesión',
        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800),
      ),
      onTap: _signOut,
    ),
  );

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'RA';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static IconData _styleIcon(String style) {
    for (final option in _styleOptions) {
      if (option.$2 == style) return option.$1;
    }
    return Icons.explore_outlined;
  }
}

class _ProfileData {
  const _ProfileData({
    required this.contributions,
    required this.visits,
    required this.biography,
    required this.styles,
  });

  factory _ProfileData.empty() => const _ProfileData(
    contributions: [],
    visits: [],
    biography: 'Explorando el Perú, un rincón a la vez.',
    styles: ['Mochilero', 'Naturaleza'],
  );

  final List<Map<String, dynamic>> contributions;
  final List<Map<String, dynamic>> visits;
  final String biography;
  final List<String> styles;

  Iterable<Map<String, dynamic>> get verified =>
      visits.where((visit) => visit['visit_verified'] == true);
  int get verifiedVisits => verified.length;
  int get routeCount => verified
      .map((visit) => visit['route_id']?.toString() ?? '')
      .where((value) => value.isNotEmpty)
      .toSet()
      .length;
  int get regionCount => verified
      .map((visit) => _department(visit['place_region']?.toString() ?? ''))
      .where((value) => value.isNotEmpty)
      .toSet()
      .length;
  int get validatedContributions =>
      contributions.where((item) => item['status'] == 'validated').length;
  int get inProgressContributions => contributions
      .where(
        (item) => const {
          'pending',
          'processing_ai',
          'processing_gis',
          'candidate',
          'needs_review',
        }.contains(item['status']),
      )
      .length;
  int get xp =>
      verifiedVisits * 100 + routeCount * 50 + validatedContributions * 150;
  _ExplorerLevel get level => _ExplorerLevel.fromXp(xp);

  int get yearVisits => verified.where(_isCurrentYear).length;
  int get yearPhotos => verified.where((visit) {
    final hasPhoto =
        (visit['photo_url']?.toString().isNotEmpty ?? false) ||
        (visit['photo_local_path']?.toString().isNotEmpty ?? false);
    return _isCurrentYear(visit) && hasPhoto;
  }).length;

  List<_Badge> get badges => [
    _Badge.fromTiers(
      Icons.location_on_outlined,
      'Huella viajera',
      verifiedVisits,
      const [1, 5, 15, 30],
      'visitas',
      const Color(0xFF078B69),
    ),
    _Badge.fromTiers(
      Icons.route_outlined,
      'Rutero',
      routeCount,
      const [1, 5, 15, 30],
      'recorridos',
      const Color(0xFF7655A6),
    ),
    _Badge.fromTiers(
      Icons.public_outlined,
      'Explorador del Perú',
      regionCount,
      const [1, 3, 10, 20],
      'regiones',
      const Color(0xFF1D7FA6),
    ),
    _Badge.fromTiers(
      Icons.volunteer_activism_outlined,
      'Guardián del mapa',
      validatedContributions,
      const [1, 5, 15, 50],
      'aportes',
      const Color(0xFFF59E45),
    ),
  ];

  bool _isCurrentYear(Map<String, dynamic> visit) {
    final date = DateTime.tryParse(visit['captured_at']?.toString() ?? '');
    return date?.toLocal().year == DateTime.now().year;
  }

  static String _department(String value) {
    if (value.trim().isEmpty) return '';
    return value.split(',').last.trim();
  }
}

class _ExplorerLevel {
  const _ExplorerLevel(
    this.name,
    this.progress, {
    this.remaining,
    this.nextName,
  });

  final String name;
  final double progress;
  final int? remaining;
  final String? nextName;

  factory _ExplorerLevel.fromXp(int xp) {
    if (xp < 300) {
      return _ExplorerLevel(
        'Viajero curioso',
        xp / 300,
        remaining: 300 - xp,
        nextName: 'Explorador',
      );
    }
    if (xp < 700) {
      return _ExplorerLevel(
        'Explorador',
        (xp - 300) / 400,
        remaining: 700 - xp,
        nextName: 'Aventurero',
      );
    }
    if (xp < 1300) {
      return _ExplorerLevel(
        'Aventurero',
        (xp - 700) / 600,
        remaining: 1300 - xp,
        nextName: 'Guardián del Perú',
      );
    }
    if (xp < 2200) {
      return _ExplorerLevel(
        'Guardián del Perú',
        (xp - 1300) / 900,
        remaining: 2200 - xp,
        nextName: 'Leyenda viajera',
      );
    }
    return const _ExplorerLevel('Leyenda viajera', 1);
  }
}

class _Badge {
  const _Badge({
    required this.icon,
    required this.name,
    required this.tier,
    required this.detail,
    required this.count,
    required this.progress,
    required this.completed,
    required this.color,
  });

  factory _Badge.fromTiers(
    IconData icon,
    String name,
    int count,
    List<int> targets,
    String unit,
    Color color,
  ) {
    const tierNames = ['Bronce', 'Plata', 'Oro', 'Leyenda'];
    var achieved = -1;
    for (var index = 0; index < targets.length; index++) {
      if (count >= targets[index]) achieved = index;
    }
    final completed = achieved == targets.length - 1;
    final nextIndex = completed ? achieved : achieved + 1;
    final nextTarget = targets[nextIndex];
    return _Badge(
      icon: icon,
      name: name,
      tier: achieved < 0 ? 'POR DESCUBRIR' : tierNames[achieved].toUpperCase(),
      detail: completed
          ? '$count $unit · colección completa'
          : '$count/$nextTarget $unit para ${tierNames[nextIndex]}',
      count: count,
      progress: completed ? 1 : (count / nextTarget).clamp(0, 1).toDouble(),
      completed: completed,
      color: color,
    );
  }

  final IconData icon;
  final String name;
  final String tier;
  final String detail;
  final int count;
  final double progress;
  final bool completed;
  final Color color;
}
