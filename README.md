# Fuga en el Trópico

Runner 3D infinito de ambientación tropical/latina hecho con Godot 4.

## Instalar en Android
1. Entra a la sección **Releases** de este repositorio.
2. Descarga el archivo `.apk` de la última versión.
3. Ábrelo en tu teléfono y permite instalar apps de esta fuente cuando Android lo pida.

Las nuevas versiones se avisan dentro del juego: aparece el botón **Actualizar** en el menú.

## Qué incluye
- 3 carriles, salto, deslizamiento, perseguidor (jaguar) y power-ups (imán, escudo, x2, vuelo)
- Obstáculos: barreras bajas y altas, vallas anchas, rampas con plataformas y bolas rodantes
- 3 zonas (Playa Dorada, Selva Esmeralda, Ciudad Colonial) cada 500 m, con aviso de dificultad
- Evento especial al final de cada zona
- Tienda con monedas: 6 personajes, 7 disfraces y 16 accesorios (gorro, cara, espalda)
- Logros que se reclaman por monedas, misiones de carrera (multiplicador) y misiones diarias
- Música por zona y efectos de sonido generados por código
- Progreso guardado en el teléfono

## Desarrollo
Requiere Godot 4.7. Abre la carpeta y pulsa F5, o:

    godot --path .

Prueba automática (un bot juega sin ventana):

    godot --headless --path . --fixed-fps 60 --quit-after 9000 -- --autoplay

### Exportar el APK
Con las plantillas de exportación de Godot y el SDK de Android configurados:

    godot --headless --path . --export-debug "Android" build/fuga-en-el-tropico.apk

Para publicar una versión: subir `config/version` en `project.godot` y `version/name` y `version/code`
en `export_presets.cfg`, crear un release con una etiqueta `vX.Y.Z` y adjuntar el `.apk`.
