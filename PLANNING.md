# Arteflix - Plan de Desarrollo

## Fase 1: Configuración del Entorno ✓

- [x] Instalar Flutter SDK (v3.27.4)
- [x] Crear proyecto Flutter `arteflix` con soporte Android
- [x] Configurar AndroidManifest.xml para Android TV (leanback, banner)
- [x] Configurar build.gradle (minSdk 21)
- [x] Agregar dependencias (http, video_player, cached_network_image, path_provider)

## Fase 2: Modelos de Datos ✓

- [x] `VideoItem` - id, name, videoUrl, thumbnailUrl, duration
- [x] `Category` - id, name, list de VideoItem

## Fase 3: Servicio de Google Drive ✓

- [x] `GoogleDriveService` - fetchCatalog()
- [x] Listar carpetas (categorías) desde Drive API v3
- [x] Listar videos .mp4 dentro de cada carpeta
- [x] Resolver miniaturas (Prioridad 1: JPG同名, Prioridad 2: thumbnailLink, Prioridad 3: placeholder)
- [x] Construir URLs de descarga directa

## Fase 4: Pantalla Principal (Home) ✓

- [x] Logo "ARTEFLIX" estilo Netflix
- [x] Lista vertical de categorías
- [x] Carruseles horizontales de videos por categoría
- [x] Navegación por foco con control remoto
- [x] Estados de carga y error

## Fase 5: Pantalla de Detalle ✓

- [x] Miniatura del video
- [x] Nombre del video
- [x] Duración
- [x] Botón "Reproducir"

## Fase 6: Reproductor de Video ✓

- [x] Pantalla completa
- [x] VideoPlayerController con networkUrl
- [x] Controles básicos (play/pause, progress bar)
- [x] Regreso automático al finalizar

## Fase 7: Próximos Pasos / Mejoras Futuras

- [ ] Configurar Google Drive API Key real en `lib/config/constants.dart`
- [ ] Configurar el ID de la carpeta raíz de Drive
- [ ] Agregar icono/banner personalizado de Arteflix
- [ ] Agregar splash screen
- [ ] Implementar actualización automática periódica del catálogo
- [ ] Agregar animaciones de transición entre pantallas
- [ ] Probar en dispositivo Android TV real
- [ ] Optimizar rendimiento con listas perezosas
- [ ] Manejar errores de red más robustamente

## Arquitectura

```
lib/
├── main.dart                    # Punto de entrada
├── config/
│   └── constants.dart           # Configuración (API Key, Folder ID)
├── models/
│   ├── category.dart            # Modelo Category
│   └── video_item.dart          # Modelo VideoItem
├── services/
│   └── google_drive_service.dart # Llamadas a Google Drive API
├── screens/
│   ├── home_screen.dart         # Pantalla principal (catálogo)
│   ├── detail_screen.dart       # Pantalla de detalle del video
│   └── player_screen.dart       # Reproductor de video
└── widgets/
    ├── category_row.dart        # Fila de categoría con carrusel
    └── video_card.dart          # Tarjeta de video individual
```

## Configuración Requerida

Antes de ejecutar, editar `lib/config/constants.dart`:

| Constante | Descripción |
|-----------|-------------|
| `driveApiKey` | API Key de Google Cloud con Drive API habilitada |
| `driveFolderId` | ID de la carpeta raíz de Google Drive |

## Comandos

```bash
# Desarrollo
flutter run

# Build APK
flutter build apk --release

# Análisis
flutter analyze
```
