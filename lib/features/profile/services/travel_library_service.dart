import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/backend_api_client.dart';
import '../../places/models/tourist_place_model.dart';

class TravelLibraryService {
  TravelLibraryService._();

  static final TravelLibraryService instance = TravelLibraryService._();

  static const _legacyFavoritesKey = 'rutaamiga_favorite_places_v1';
  static const _legacyTripKey = 'rutaamiga_active_trip_v1';
  static const _legacyReviewsKey = 'rutaamiga_local_reviews_v1';
  final BackendApiClient _api = BackendApiClient();
  bool _syncAttempted = false;
  String? _syncUserId;

  String get _userId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'guest';
  String get _stateKey => 'rutaamiga_travel_state_v2_$_userId';
  String get _dirtyKey => 'rutaamiga_travel_state_dirty_v2_$_userId';

  Future<List<TouristPlaceModel>> favorites() async {
    final state = await _loadSyncedState();
    return _decodePlaces(state['favorites']);
  }

  Future<List<TouristPlaceModel>> trip() async {
    final state = await _loadSyncedState();
    return _decodePlaces(state['trip']);
  }

  Future<bool> isFavorite(int placeId) async =>
      (await favorites()).any((place) => place.id == placeId);

  Future<bool> toggleFavorite(TouristPlaceModel place) async {
    final state = await _loadSyncedState();
    final items = _decodePlaces(state['favorites']);
    final index = items.indexWhere((item) => item.id == place.id);
    final added = index < 0;
    if (added) {
      items.insert(0, place);
    } else {
      items.removeAt(index);
    }
    state['favorites'] = _encodePlaces(items);
    await _saveAndSync(state);
    return added;
  }

  Future<bool> addToTrip(TouristPlaceModel place) async {
    final state = await _loadSyncedState();
    final items = _decodePlaces(state['trip']);
    if (items.any((item) => item.libraryKey == place.libraryKey)) return false;
    items.add(place);
    state['trip'] = _encodePlaces(items);
    await _saveAndSync(state);
    return true;
  }

  Future<bool> isInTrip(TouristPlaceModel place) async =>
      (await trip()).any((item) => item.libraryKey == place.libraryKey);

  Future<void> removeFromTrip(int placeId) async {
    final state = await _loadSyncedState();
    final items = _decodePlaces(state['trip'])
      ..removeWhere((item) => item.id == placeId);
    state['trip'] = _encodePlaces(items);
    await _saveAndSync(state);
  }

  Future<void> reorderTrip(int oldIndex, int newIndex) async {
    final state = await _loadSyncedState();
    final items = _decodePlaces(state['trip']);
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex > oldIndex) newIndex--;
    newIndex = newIndex.clamp(0, items.length - 1);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state['trip'] = _encodePlaces(items);
    await _saveAndSync(state);
  }

  Future<void> replaceTrip(List<TouristPlaceModel> places) async {
    final state = await _loadSyncedState();
    state['trip'] = _encodePlaces(places);
    await _saveAndSync(state);
  }

  Future<List<Map<String, dynamic>>> savedRoutes() async {
    final state = await _loadSyncedState();
    return (state['saved_routes'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> saveCurrentTrip(String name) async {
    final state = await _loadSyncedState();
    final places = _decodePlaces(state['trip']);
    if (places.length < 2) return;
    final routes = (state['saved_routes'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final now = DateTime.now().toUtc();
    routes.insert(0, {
      'id': 'saved-${now.microsecondsSinceEpoch}',
      'name': name.trim(),
      'created_at': now.toIso8601String(),
      'places': _encodePlaces(places),
    });
    state['saved_routes'] = routes.take(50).toList();
    await _saveAndSync(state);
  }

  Future<void> loadSavedRoute(String routeId) async {
    final state = await _loadSyncedState();
    Map<String, dynamic>? route;
    for (final item in state['saved_routes'] as List? ?? const []) {
      final candidate = Map<String, dynamic>.from(item as Map);
      if (candidate['id']?.toString() == routeId) {
        route = candidate;
        break;
      }
    }
    if (route == null) return;
    state['trip'] = (route['places'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    await _saveAndSync(state);
  }

  Future<void> deleteSavedRoute(String routeId) async {
    final state = await _loadSyncedState();
    final routes =
        (state['saved_routes'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
          ..removeWhere((item) => item['id']?.toString() == routeId);
    state['saved_routes'] = routes;
    await _saveAndSync(state);
  }

  Future<List<Map<String, dynamic>>> reviews(int placeId) async {
    final state = await _loadSyncedState();
    final reviews = Map<String, dynamic>.from(
      state['reviews'] as Map? ?? const {},
    );
    return (reviews['$placeId'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> addReview({
    required int placeId,
    required int rating,
    required String comment,
    required bool visitVerified,
  }) async {
    final state = await _loadSyncedState();
    final reviews = Map<String, dynamic>.from(
      state['reviews'] as Map? ?? const {},
    );
    final items = (reviews['$placeId'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    items.insert(0, {
      'rating': rating,
      'comment': comment,
      'visit_verified': visitVerified,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    reviews['$placeId'] = items;
    state['reviews'] = reviews;
    await _saveAndSync(state);
  }

  Future<void> sync() async {
    _syncAttempted = false;
    _syncUserId = _userId;
    await _loadSyncedState();
  }

  Future<Map<String, dynamic>> _loadSyncedState() async {
    if (_syncUserId != _userId) {
      _syncUserId = _userId;
      _syncAttempted = false;
    }
    final local = await _localState();
    if (_syncAttempted || _userId == 'guest') return local;
    _syncAttempted = true;
    final preferences = await SharedPreferences.getInstance();
    final dirty = preferences.getBool(_dirtyKey) ?? false;
    try {
      if (dirty) {
        await _push(local);
        await preferences.setBool(_dirtyKey, false);
        return local;
      }
      final response = Map<String, dynamic>.from(
        await _api.get('/me/travel/state') as Map,
      );
      final remote = _normalizeState(response);
      await _writeLocal(remote);
      return remote;
    } catch (_) {
      return local;
    }
  }

  Future<Map<String, dynamic>> _localState() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_stateKey);
    if (raw != null) {
      try {
        return _normalizeState(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {
        await preferences.remove(_stateKey);
      }
    }
    final migrated = await _migrateLegacy(preferences);
    await _writeLocal(migrated);
    return migrated;
  }

  Future<Map<String, dynamic>> _migrateLegacy(
    SharedPreferences preferences,
  ) async {
    dynamic decode(String key, dynamic fallback) {
      final raw = preferences.getString(key);
      if (raw == null) return fallback;
      try {
        return jsonDecode(raw);
      } catch (_) {
        return fallback;
      }
    }

    final state = _normalizeState({
      'favorites': decode(_legacyFavoritesKey, const []),
      'trip': decode(_legacyTripKey, const []),
      'reviews': decode(_legacyReviewsKey, const {}),
      'saved_routes': const [],
      'version': 1,
    });
    if (_userId != 'guest' &&
        ((state['favorites'] as List).isNotEmpty ||
            (state['trip'] as List).isNotEmpty ||
            (state['reviews'] as Map).isNotEmpty)) {
      await preferences.setBool(_dirtyKey, true);
    }
    if (_userId != 'guest') {
      await preferences.remove(_legacyFavoritesKey);
      await preferences.remove(_legacyTripKey);
      await preferences.remove(_legacyReviewsKey);
    }
    return state;
  }

  Map<String, dynamic> _normalizeState(Map<String, dynamic> value) => {
    'favorites': (value['favorites'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    'trip': (value['trip'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    'reviews': Map<String, dynamic>.from(value['reviews'] as Map? ?? const {}),
    'saved_routes': (value['saved_routes'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    'version': int.tryParse(value['version']?.toString() ?? '') ?? 1,
  };

  List<TouristPlaceModel> _decodePlaces(dynamic value) =>
      (value as List? ?? const [])
          .map(
            (item) => TouristPlaceModel.fromStorage(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

  List<Map<String, dynamic>> _encodePlaces(List<TouristPlaceModel> places) =>
      places.map((place) => place.toStorageJson()).toList();

  Future<void> _saveAndSync(Map<String, dynamic> state) async {
    state['version'] = (state['version'] as int? ?? 0) + 1;
    final preferences = await SharedPreferences.getInstance();
    await _writeLocal(state);
    await preferences.setBool(_dirtyKey, true);
    if (_userId == 'guest') return;
    try {
      await _push(state);
      await preferences.setBool(_dirtyKey, false);
    } catch (_) {
      // El documento queda marcado para el siguiente intento.
    }
  }

  Future<void> _push(Map<String, dynamic> state) async {
    await _api.put(
      '/me/travel/state',
      body: {
        'favorites': state['favorites'],
        'trip': state['trip'],
        'reviews': state['reviews'],
        'saved_routes': state['saved_routes'],
        'version': state['version'],
      },
    );
  }

  Future<void> _writeLocal(Map<String, dynamic> state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_stateKey, jsonEncode(state));
  }
}
