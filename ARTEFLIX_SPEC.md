# Arteflix — Especificación Técnica y Funcional

## Descripción General

Arteflix es una aplicación para Android TV inspirada en la experiencia de navegación de Netflix, diseñada para la Sala Interactiva Cauce del Centro de Ciencias Francisco José de Caldas.

La aplicación permite explorar y reproducir videos educativos organizados por categorías. Todo el contenido se administra mediante una carpeta pública de Google Drive, de manera que el personal encargado únicamente debe crear carpetas y cargar archivos multimedia sin necesidad de conocimientos técnicos.

La aplicación se ejecuta localmente en un televisor Android TV y no requiere publicación en tiendas de aplicaciones ni autenticación de usuarios.

## Objetivos

- Permitir la exploración intuitiva de contenido audiovisual mediante control remoto.
- Facilitar la administración de contenido por personal no técnico.
- Actualizar automáticamente el catálogo a partir de Google Drive al iniciar la app.
- Ofrecer una interfaz moderna inspirada en plataformas de streaming.
- Mantener una arquitectura simple, robusta y de bajo mantenimiento.

## Tecnologías Implementadas

### Framework
Flutter (Dart SDK ^3.6.2)

### Plataforma Objetivo
Android TV (API 21+). Soporte secundario en Windows (fallback con "abrir en navegador").

### Fuente de Contenido
Google Drive API v3 con API Key pública (sin OAuth).

### Reproductor Multimedia
`video_player` para Flutter, basado en ExoPlayer en Android.

### Miniaturas
`cached_network_image` con caché local en disco mediante `flutter_cache_manager`.

### Variables de Entorno
`flutter_dotenv` — carga `DRIVE_API_KEY` y `DRIVE_FOLDER_ID` desde archivo `.env`.

### API HTTP
`http` — cliente HTTP para llamadas a la API de Google Drive.

### Fallback Desktop
`url_launcher` — abre el video en el navegador cuando no se ejecuta en Android.

### Navegación
Nativa del framework: widgets `Focus`, `FocusNode` y `LogicalKeyboardKey` para manejo de control remoto. Sin librerías externas.

### Gestión de Estado
`StatefulWidget` con `setState`. Sin librerías externas (Provider, BLoC, Riverpod, etc.).

## Exclusión Deliberada

No se implementan:

- Usuarios ni autenticación
- Favoritos
- Historial
- Continuar viendo
- Base de datos local
- Sincronización de perfiles
- Reproducción en segundo plano
- Listas de reproducción
- Búsqueda
- Streaming adaptativo (HLS/DASH)

## Estructura del Contenido en Google Drive

La carpeta raíz de Google Drive contiene categorías representadas mediante subcarpetas:

```
Carpeta raíz
├── Astronomía/
│   ├── Agujeros Negros.mp4
│   ├── Agujeros Negros.jpg        (miniatura — opcional)
│   ├── Agujeros Negros.txt        (descripción — opcional)
│   └── Sistema Solar.mp4
├── Robótica/
│   ├── Introducción a Arduino.mp4
│   └── Impresión 3D.mp4
└── ...
```

- Cada subcarpeta es una categoría.
- Cada archivo `.mp4` es un video reproducible.
- Archivos `.jpg` o `.png` con el mismo nombre base del video se usan como miniatura oficial.
- Archivos `.txt` con el mismo nombre base del video se usan como descripción del contenido y se muestran debajo del título en el banner hero.
- Las categorías se ordenan por `modifiedTime` descendente (más reciente primero).

## Gestión de Miniaturas

### Prioridad 1
Buscar una imagen con el mismo nombre del video (`.jpg` primero, luego `.png`) dentro de la misma carpeta. Si existe, se usa como miniatura oficial.

### Prioridad 2
Si no existe imagen asociada, se consulta la API de Drive para obtener el `thumbnailLink` generado automáticamente.

### Prioridad 3
Si no hay miniatura disponible, se muestra un icono genérico (`Icons.movie_outlined`) sobre fondo gris.

## Gestión de Descripciones

Durante el escaneo de cada carpeta, el sistema busca un archivo `.txt` cuyo nombre base coincida con el del video (por ejemplo, `Agujeros Negros.txt` para `Agujeros Negros.mp4`).

- Si existe, se descarga y se lee completamente con codificación UTF-8.
- El texto se asocia al modelo del video (`VideoItem.description`) y se mantiene en memoria.
- Si no existe, la descripción es `null` y no se reserva espacio visual adicional.
- Si existe pero no puede leerse, se registra el error en el log y se continúa sin descripción.

## Navegación

La aplicación es completamente navegable mediante control remoto Android TV.

### Controles soportados

| Tecla | Acción |
|---|---|
| Arriba / Abajo | Moverse entre categorías o entre secciones (banner, perfil, carrusel) |
| Izquierda / Derecha | Navegar entre videos del mismo carrusel / entre botones del banner |
| Enter / OK | Seleccionar video / reproducir / abrir panel |
| Back | Retroceder: cerrar panel de perfil → deseleccionar video → salir de la app |

No se requiere interacción táctil. La experiencia se basa completamente en navegación por foco (Focus Navigation).

### Flujo de navegación

```
[Logo Arteflix]  [Logo Cauce]  [Perfil]

[Banner hero]
  └─ Cuando hay video seleccionado:
       [Título del video]
       [Descripción del video]   (solo si existe .txt asociado)
       [▶ Reproducir]

[Categoría 1]
  [Video] [Video] [Video] → (scroll horizontal)

[Categoría 2]
  [Video] [Video] [Video] → (scroll horizontal)
```

## Interfaz de Usuario

### Pantalla Principal (`HomeScreen`)

Elementos visibles:

1. **Barra superior**: logo de Arteflix (izquierda), logo de Cauce (centro), botón de perfil (derecha).
2. **Banner hero**: si no hay video seleccionado, muestra una imagen de cabecera estática (`cabecera.png`). Si hay un video seleccionado, muestra su miniatura de fondo con el título, la descripción opcional debajo del título (cuando exista un archivo `.txt` asociado) y el botón "Reproducir" (rojo).
3. **Carruseles de categorías**: filas horizontales con tarjetas de video. Cada fila tiene gradientes en los bordes que aparecen/desaparecen según la posición del scroll.
4. **Panel de perfil**: al hacer foco en el botón de perfil y presionar Enter, se despliega un panel con información del espacio cultural. Se cierra con Back o Enter nuevamente.

### Tarjeta de Video (`VideoCard`)

- Dimensiones: 420×260 px.
- Al recibir foco: borde blanco brillante (3 px) + sombra exterior.
- Nombre del video en la parte inferior con fondo semitransparente.
- **Efecto marquee**: si el nombre del video excede el ancho disponible, al recibir foco el texto se desplaza horizontalmente en un bucle continuo.

### Reproductor de Video (`PlayerScreen`)

- Pantalla completa, orientación forzada a landscape.
- Al iniciar: reproducción automática.
- Controles superpuestos en la parte inferior:
  - Botón play/pausa.
  - Barra de progreso (seeking permitido).
  - Tiempo transcurrido / duración total.
- Al tocar la pantalla (o con mando) se muestran/ocultan los controles.
- Al finalizar la reproducción: regreso automático al catálogo tras 500 ms.
- En Windows: muestra mensaje "Reproductor disponible solo en Android TV" con botón para abrir el video en el navegador.

## Arquitectura del Código

```
lib/
├── main.dart                        # Entry point
├── config/
│   └── constants.dart               # AppConfig con credenciales
├── models/
│   ├── category.dart                # Category {id, name, videos, modifiedTime}
│   └── video_item.dart              # VideoItem {id, name, videoUrl, thumbnailUrl, duration}
├── screens/
│   ├── home_screen.dart             # Catálogo principal (~803 líneas)
│   └── player_screen.dart           # Reproductor de video (~259 líneas)
├── services/
│   └── google_drive_service.dart    # Cliente Google Drive API v3 (~165 líneas)
└── widgets/
    ├── category_row.dart            # Fila horizontal con scroll y gradientes (~309 líneas)
    └── video_card.dart              # Tarjeta con foco, miniatura y marquee (~196 líneas)
```

### Flujo de datos

```
Inicio App
  → dotenv carga .env
  → HomeScreen.initState()
    → GoogleDriveService.fetchCatalog()
      → _listFolderNames()          (GET /files?q=...folder)
      → por cada carpeta:
          _listVideosInFolder()      (GET /files?q=...video)
          _resolveThumbnail()        (GET /files?q=...jpg|png  o  GET /files/{id}?fields=thumbnailLink)
          _resolveDescription()      (GET /files?q=...txt  o  GET /files/{id}?alt=media)
    → setState() con categorías
  → Usuario navega y selecciona video
    → PlayerScreen(video)
      → VideoPlayerController.networkUrl()
      → reproduce hasta completar
      → Navigator.pop() automático
```

## Sincronización

Al iniciar la aplicación:

1. Cargar variables de entorno (`.env`).
2. Consultar Google Drive para obtener lista de subcarpetas (categorías).
3. Por cada carpeta, consultar archivos de video (`.mp4`).
4. Resolver miniaturas para cada video.
5. Construir y mostrar el catálogo en memoria.

No hay actualización automática periódica. Para refrescar el catálogo, se debe reiniciar la aplicación.

## Identidad Visual

- **Fondo**: negro (#000000).
- **Acento principal**: rojo Netflix (#E50914).
- **Texto secundario**: blanco con opacidad reducida (aproximadamente 70%) para descripciones e información de menor jerarquía.
- **Texto**: blanco y variantes de blanco semitransparente.
- **Material 3** habilitado.
- **Logo Arteflix**: asset `assets/logo.png`.
- **Imagen de cabecera**: asset `assets/cabecera.png`.
- **Logo Cauce**: desde Cloudinary (URL remota).

## Comandos de Desarrollo

```sh
flutter pub get             # Instalar dependencias
flutter run                 # Ejecutar en dispositivo/emulador
flutter build apk --release # Generar APK para Android TV
flutter analyze             # Análisis estático (linter)
flutter test                # Ejecutar tests
```

## Dependencias (pubspec.yaml)

### Producción
| Paquete | Propósito |
|---|---|
| `http` | Cliente HTTP para Google Drive API |
| `video_player` | Reproducción de video (ExoPlayer) |
| `url_launcher` | Abrir videos en navegador (fallback desktop) |
| `cached_network_image` | Miniaturas con caché |
| `flutter_dotenv` | Variables de entorno desde `.env` |

### Desarrollo
| Paquete | Propósito |
|---|---|
| `flutter_test` | Framework de tests |
| `flutter_lints` | Reglas de linting |

## Mantenimiento

El personal administrador únicamente debe:

1. Crear carpetas en Google Drive para nuevas categorías.
2. Subir videos `.mp4`.
3. Subir imágenes `.jpg`/`.png` opcionales con el mismo nombre del video.
4. Subir archivos `.txt` opcionales con el mismo nombre del video para mostrar una descripción.

No requiere modificar archivos JSON, configuraciones técnicas ni código fuente.

## Requisitos No Funcionales

- Inicio rápido (carga única del catálogo desde Drive).
- Navegación fluida mediante control remoto (focus navigation nativa).
- Interfaz optimizada para televisores (tipografía grande, alto contraste).
- Bajo consumo de recursos (sin estado persistente, sin librerías pesadas).
- Funcionamiento estable en sesiones prolongadas.
- Arquitectura modular y mantenible (separación clara en modelos, servicios, screens, widgets).
- Código preparado para futuras ampliaciones (agregar nuevas pantallas o servicios sin reescribir).
