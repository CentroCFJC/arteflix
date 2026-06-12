# Arteflix

## Descripción General

Arteflix es una aplicación para Android TV inspirada en la experiencia de navegación de Netflix, diseñada para la Sala Interactiva Cauce del Centro de Ciencias Francisco José de Caldas.

La aplicación permitirá explorar y reproducir videos educativos organizados por categorías. Todo el contenido será administrado mediante una carpeta pública de Google Drive, de manera que el personal encargado únicamente deba crear carpetas y cargar archivos multimedia sin necesidad de conocimientos técnicos.

La aplicación se ejecutará localmente en un televisor Android TV específico y no requiere publicación en tiendas de aplicaciones ni autenticación de usuarios.

## Objetivos

* Permitir la exploración intuitiva de contenido audiovisual mediante control remoto.
* Facilitar la administración de contenido por personal no técnico.
* Actualizar automáticamente el catálogo a partir de Google Drive.
* Ofrecer una interfaz moderna inspirada en plataformas de streaming.
* Mantener una arquitectura simple, robusta y de bajo mantenimiento.

## Tecnologías Seleccionadas

### Framework

Flutter

### Plataforma Objetivo

Android TV

### Fuente de Contenido

Google Drive público

### Reproductor Multimedia

Video Player para Flutter (basado en ExoPlayer en Android)

### Persistencia Local

Solo caché temporal para mejorar rendimiento.

No se implementarán:

* Usuarios
* Autenticación
* Favoritos
* Historial
* Continuar viendo
* Base de datos local
* Sincronización de perfiles

## Estructura del Contenido

La carpeta raíz de Google Drive contendrá categorías representadas mediante subcarpetas.

Ejemplo:

Arteflix/

├── Astronomía/

│   ├── Agujeros Negros.mp4

│   ├── Agujeros Negros.jpg

│   ├── Sistema Solar.mp4

│

├── Robótica/

│   ├── Introducción a Arduino.mp4

│   ├── Impresión 3D.mp4

│

├── Biodiversidad/

│   ├── Bosques Andinos.mp4

│   ├── Polinizadores.mp4

Cada carpeta representa una categoría visible dentro de la aplicación.

Cada archivo de video representa un elemento reproducible.

## Gestión de Miniaturas

Las miniaturas se resolverán utilizando la siguiente prioridad:

### Prioridad 1

Buscar una imagen con el mismo nombre del video.

Ejemplo:

Agujeros Negros.mp4

Agujeros Negros.jpg

Si existe la imagen, esta será utilizada como miniatura oficial.

### Prioridad 2

Si no existe una imagen asociada, utilizar la miniatura generada automáticamente por Google Drive.

### Prioridad 3

Si Google Drive no proporciona miniatura, mostrar una imagen genérica de respaldo definida por la aplicación.

## Navegación

La aplicación debe ser completamente navegable mediante control remoto Android TV.

Controles esperados:

* Arriba
* Abajo
* Izquierda
* Derecha
* OK / Enter
* Back

No se requiere interacción táctil.

La experiencia debe priorizar la navegación por foco (Focus Navigation).

## Interfaz Principal

La pantalla principal mostrará:

* Logo de Arteflix
* Categorías obtenidas desde Google Drive
* Carruseles horizontales de contenido
* Elemento seleccionado destacado visualmente

Diseño inspirado en Netflix:

Categoría

[Video] [Video] [Video] [Video]

Categoría

[Video] [Video] [Video] [Video]

## Pantalla de Detalle

Al seleccionar un contenido se mostrará:

* Miniatura
* Nombre del video
* Duración
* Botón de reproducción

No se requiere descripción textual obligatoria.

## Reproducción

Al iniciar un video:

* Reproducción en pantalla completa
* Controles básicos del reproductor
* Compatibilidad con MP4

Al finalizar:

* Regresar automáticamente al catálogo principal

## Sincronización

Al iniciar la aplicación:

1. Consultar Google Drive.
2. Leer categorías.
3. Leer videos.
4. Resolver miniaturas.
5. Construir catálogo.

Opcionalmente se podrá implementar actualización automática periódica.

## Identidad Visual

La identidad visual estará basada en el logo oficial de Arteflix entregado en formato PNG.

La interfaz debe transmitir una estética moderna, limpia y cercana a plataformas de streaming comerciales.

## Consideraciones de Mantenimiento

El personal administrador únicamente deberá:

1. Crear carpetas para nuevas categorías.
2. Subir videos.
3. Subir imágenes JPG opcionales con el mismo nombre del video.

No deberá modificar archivos JSON, configuraciones ni estructuras técnicas.

## Requisitos No Funcionales

* Inicio rápido.
* Navegación fluida mediante control remoto.
* Interfaz optimizada para televisores.
* Bajo consumo de recursos.
* Funcionamiento estable en sesiones prolongadas.
* Arquitectura modular y mantenible.
* Código preparado para futuras ampliaciones.
