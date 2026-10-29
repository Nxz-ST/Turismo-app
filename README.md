# RutaAmiga

Aplicación móvil Flutter para descubrir atractivos naturales oficiales,
registrar evidencias de nuevos lugares y seguir su validación.

El backend FastAPI se mantiene como proyecto independiente en la carpeta hermana
`../turismo_backend`. La aplicación actual se mantiene operativa mientras se
valida y despliega la API.

## Aplicación Flutter

La app usa archivos por ambiente ubicados en `config/env/`. Para desarrollo:

```bash
# Android Emulator
flutter run --dart-define-from-file=config/env/development.android.json

# iOS Simulator
flutter run --dart-define-from-file=config/env/development.ios.json

# Web
flutter run -d chrome --dart-define-from-file=config/env/development.web.json
```

En un dispositivo físico se debe usar la IP local del equipo que ejecuta
FastAPI. En producción se debe proporcionar una URL HTTPS desplegada.

Supabase se usa directamente únicamente para autenticación y obtención del JWT.
Las consultas de lugares, reportes, fotografías, servicios, rutas y revisión
administrativa pasan por el backend.

## Experiencias principales

- Atractivos oficiales cercanos desde la base turística.
- Mapa con aportes comunitarios diferenciados por estado.
- Registro de evidencia fotográfica y geolocalizada.
- Historial “Mis aportes” con decisión y explicación.
- Panel de revisión para usuarios con rol administrador.
- Restaurantes, alojamiento y servicios de Google como contexto de una visita,
  no como fuente de validación turística.

Las claves nativas de Google Maps están fuera del código:

- Android: `android/maps.properties`.
- iOS: `ios/Flutter/Secrets.xcconfig`.

Ambos archivos están ignorados por Git y cuentan con una plantilla `.example`.
La clave del backend para Places/Routes es independiente de estas claves
nativas.

## Calidad

```bash
flutter analyze
flutter test
```
