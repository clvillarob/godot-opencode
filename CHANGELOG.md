# Godot Opencode Plugin — Changelog

## 0.1.0 (2026-05-04)

### Añadido
- Estructura base del proyecto y documentación inicial
- Especificación de diseño en `docs/specs/`
- Guía de uso en `docs/usage.md`
- ROADMAP con hitos del proyecto
- Lista de tareas detallada
- `settings.gd`: Detección de opencode en PATH, rutas del proyecto
- `opencode_client.gd`: Comunicación con opencode CLI via Thread + call_deferred
- `project_context.gd`: Recolección de contexto del editor (scripts, nodos, escenas)
- `editor_bridge.gd`: Parseo de bloques de código con RegEx y aplicación al editor
- `chat_dock`: Chat interactivo con historial, comandos predefinidos y control de estado
- `files_dock`: Explorador de archivos del proyecto con árbol recursivo
- `terminal_dock`: Consola de salida con auto-scroll y línea de comandos
- `plugin.gd`: Punto de entrada con inicialización completa y señalización
