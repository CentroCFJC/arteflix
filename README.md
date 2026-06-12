# Arteflix

Aplicación para Android TV inspirada en Netflix, diseñada para la Sala Interactiva Cauce del **Centro de Ciencias Francisco José de Caldas**.

Permite explorar y reproducir videos educativos organizados por categorías, con contenido administrado mediante una carpeta pública de Google Drive.

## Requisitos

- Flutter SDK ^3.6.2
- Android TV como dispositivo objetivo

## Configuración

1. Copia el archivo de entorno:
   ```sh
   cp .env.example .env
   ```

2. Edita `.env` con tus credenciales de Google Drive:
   ```env
   DRIVE_API_KEY=tu-api-key-de-google-drive
   DRIVE_FOLDER_ID=id-de-la-carpeta-raiz-en-drive
   ```

   > **Importante:** El archivo `.env` contiene credenciales sensibles y está incluido en `.gitignore`. Nunca se debe subir al repositorio.

3. Instala las dependencias:
   ```sh
   flutter pub get
   ```

4. Ejecuta la aplicación:
   ```sh
   flutter run
   ```

## Estructura del contenido en Google Drive

```
Carpeta raíz (DRIVE_FOLDER_ID)
├── Astronomía/
│   ├── Agujeros Negros.mp4
│   └── Agujeros Negros.jpg
├── Robótica/
│   ├── Introducción a Arduino.mp4
│   └── ...
└── ...
```

Cada subcarpeta es una categoría. Los archivos `.mp4` son los videos. Las imágenes `.jpg`/`.png` con el mismo nombre del video se usan como miniaturas.

## Stack técnico

- **Framework:** Flutter
- **Fuente de contenido:** Google Drive API v3
- **Reproductor:** `video_player` (ExoPlayer en Android)
- **Estado:** Solo caché temporal en memoria
