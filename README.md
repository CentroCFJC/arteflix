# Arteflix

Aplicación para Android TV inspirada en Netflix, diseñada para la Sala Interactiva Cauce del **Centro de Ciencias Francisco José de Caldas**.

Explora y reproduce videos educativos organizados por categorías, con contenido administrado mediante una carpeta pública de Google Drive.

## Requisitos

- Flutter SDK ^3.6.2
- Android TV (API 21+) como dispositivo objetivo

## Configuración

1. Clona el repositorio y entra en la carpeta:
   ```sh
   git clone <repo-url>
   cd arteflix
   ```

2. Copia el archivo de entorno:
   ```sh
   cp .env.example .env
   ```

3. Edita `.env` con tus credenciales de Google Drive:
   ```env
   DRIVE_API_KEY=tu-api-key-de-google-drive
   DRIVE_FOLDER_ID=id-de-la-carpeta-raiz-en-drive
   ```

   > **Importante:** El archivo `.env` contiene credenciales sensibles y está incluido en `.gitignore`.

4. Instala las dependencias:
   ```sh
   flutter pub get
   ```

5. Ejecuta la aplicación:
   ```sh
   flutter run           # desarrollo
   flutter run -d emulator-5554  # en emulador Android TV
   flutter build apk --release   # APK de producción
   ```

## Estructura del contenido en Google Drive

```
Carpeta raíz (DRIVE_FOLDER_ID)
├── Astronomía/
│   ├── Agujeros Negros.mp4
│   └── Agujeros Negros.jpg      (miniatura opcional)
├── Robótica/
│   ├── Introducción a Arduino.mp4
│   └── Arduino.jpg              (miniatura opcional)
└── ...
```

Cada subcarpeta es una categoría. Los archivos `.mp4` son los videos. Las imágenes `.jpg`/`.png` con el mismo nombre del video se usan como miniaturas (prioridad 1); si no existen, se usa la miniatura generada automáticamente por Google Drive.

## Funcionalidades

### Navegación por control remoto
Toda la interfaz es navegable con las flechas del control remoto Android TV (arriba/abajo/izquierda/derecha), Enter para seleccionar y Back para retroceder. No requiere interacción táctil.

### Pantalla principal
- **Logo de Arteflix** en la esquina superior izquierda y logo de Cauce en la derecha.
- **Banner hero**: al seleccionar un video, se muestra un banner con el título, botón "Reproducir" y "Más información", con navegación por foco entre los botones.
- **Categorías en carrusel horizontal**: cada categoría despliega sus videos en una fila horizontal con scroll. Al hacer foco en un video, el carrusel se centra automáticamente.
- **Paneles de gradiente**: bordes oscuros en los extremos del carrusel para indicar contenido desplazable.
- **Panel de perfil**: al presionar el botón circular con la letra "A" se despliega un panel informativo del espacio cultural.

### Video cards
Cada video se muestra como una tarjeta con miniatura y nombre. Al recibir foco:
- Borde blanco brillante y sombra.
- Si el nombre es más largo que el contenedor, se activa un efecto **marquee** (desplazamiento horizontal del texto).

### Reproductor de video
- Reproducción en pantalla completa usando ExoPlayer (Android TV).
- Barra de control inferior: botón play/pausa, indicador de progreso (seeking permitido), tiempo transcurrido y duración total.
- Al finalizar el video, regresa automáticamente al catálogo después de 500 ms.
- En Windows, muestra un mensaje informativo con botón para abrir el video en el navegador.

### Sincronización con Google Drive
Al iniciar la aplicación:
1. Consulta la carpeta raíz en Google Drive.
2. Lee las subcarpetas (categorías), ordenadas por fecha de modificación descendente.
3. Dentro de cada carpeta, lista los archivos `.mp4`.
4. Resuelve las miniaturas (imagen del mismo nombre > miniatura automática de Drive > icono genérico).
5. Construye el catálogo en memoria.

## Arquitectura

```
lib/
├── main.dart                          # Entry point
├── config/
│   └── constants.dart                 # AppConfig (API Key, Folder ID)
├── models/
│   ├── category.dart                  # Modelo Category
│   └── video_item.dart                # Modelo VideoItem
├── screens/
│   ├── home_screen.dart               # Pantalla principal con catálogo
│   └── player_screen.dart             # Reproductor de video
├── services/
│   └── google_drive_service.dart      # Cliente Google Drive API v3
└── widgets/
    ├── category_row.dart              # Fila horizontal de categoría
    └── video_card.dart                # Tarjeta de video con foco y marquee
```

## Stack técnico

| Componente | Tecnología |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.6.2) |
| **Plataforma destino** | Android TV (API 21+) |
| **Fuente de contenido** | Google Drive API v3 (pública, sin OAuth) |
| **Reproductor** | `video_player` (ExoPlayer en Android) |
| **Miniaturas** | `cached_network_image` (con caché local) |
| **Env vars** | `flutter_dotenv` |
| **API HTTP** | `http` |
| **Fallback desktop** | `url_launcher` |
| **Navegación** | Nativa con `Focus` + `FocusNode` + `LogicalKeyboardKey` |
| **Estado** | `StatefulWidget` con `setState` (sin librería externa) |

## Comandos útiles

```sh
flutter analyze          # Análisis estático
flutter test             # Pruebas unitarias
flutter build apk --release  # Build release para Android TV
```

## Desarrollo

Este proyecto usa `flutter_lints` para mantener la calidad del código. Corre `flutter analyze` antes de cada commit para asegurar que no haya warnings ni errores.

## Licencia

Uso interno — Centro de Ciencias Francisco José de Caldas.
