# Godot Opencode Plugin — Roadmap

## Objetivo final

Integrar el agente de IA opencode como una herramienta nativa dentro del editor de Godot 4.6+, proporcionando una experiencia similar a la extensión de opencode en VS Code.

## Hitos

### Fase 1 — Fundación del proyecto
- [x] Estructura de proyecto y documentación inicial
- [x] Especificación de diseño
- [x] Plugin base con `plugin.cfg` y `plugin.gd` funcional
- [x] Docks registrados en el editor (Chat, Files, Terminal)

### Fase 2 — Comunicación con opencode
- [x] `opencode_client.gd` — Comunicación CLI con threading
- [x] Envío de prompts y recepción de respuestas via subproceso
- [x] Manejo de estados y señales vía call_deferred
- [x] Detección de instalación de opencode

### Fase 3 — Chat Dock
- [x] Interfaz de chat con historial (RichTextLabel)
- [x] Formato de texto con BBCode
- [x] Campo de entrada y envío
- [x] Comandos predefinidos (explicar, mejorar, documentar, refactorizar, crear)
- [x] Botón "Iniciar/Detener" opencode

### Fase 4 — EditorBridge
- [x] `project_context.gd` — Recolección de contexto del editor
- [x] `editor_bridge.gd` — Parseo de bloques de código y aplicación
- [x] Integración con script editor y scene tree

### Fase 5 — Files Dock
- [x] Árbol del proyecto con recursión de directorios
- [x] Doble clic para abrir archivos en el editor
- [ ] Menú contextual

### Fase 6 — Terminal Dock
- [x] Consola de salida de opencode con auto-scroll
- [x] Línea de comandos
- [x] Botones de limpiar

### Fase 7 — Pulido y distribución
- [ ] Temas visuales consistentes
- [ ] Manejo de errores robusto (opencode no instalado, conexión perdida)
- [ ] Pruebas de integración en Godot 4.6+
- [ ] Publicación en Asset Library de Godot

## Estado actual

**Versión:** 0.1.0
**Fase activa:** Fase 7 — Pulido y distribución
