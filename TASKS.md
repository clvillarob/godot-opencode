# Godot Opencode Plugin — Lista de tareas

## Fase 1: Fundación del proyecto

- [x] Crear estructura de directorios del proyecto
- [x] Escribir especificación de diseño (`docs/specs/2026-05-04-godot-opencode-plugin-design.md`)
- [x] Escribir guía de uso (`docs/usage.md`)
- [x] Escribir ROADMAP.md
- [x] Escribir TASKS.md
- [x] Escribir CHANGELOG.md
- [x] Actualizar README.md
- [x] Crear `plugin.cfg`
- [x] Crear `plugin.gd` con registro de docks
- [x] Crear `chat_dock.tscn` y `chat_dock.gd`
- [x] Crear `files_dock.tscn` y `files_dock.gd`
- [x] Crear `terminal_dock.tscn` y `terminal_dock.gd`
- [ ] Verificar que el plugin se activa sin errores en Godot 4.6+

## Fase 2: Comunicación con opencode

- [x] Crear `core/opencode_client.gd`
- [x] Implementar detección de opencode en PATH
- [x] Implementar envío de prompts via subproceso CLI
- [x] Implementar recepción de respuestas via Thread
- [x] Implementar señales de estado (connected, busy, error, disconnected)
- [x] Implementar cancelación de prompts
- [x] Manejo thread-safe con call_deferred

## Fase 3: Chat Dock

- [x] Diseñar UI del chat dock en .tscn
- [x] Implementar historial de mensajes con formato BBCode
- [x] Implementar campo de entrada con envío
- [x] Implementar indicador de estado
- [x] Implementar botones de comandos predefinidos
- [x] Implementar botón "Iniciar/Detener opencode"
- [x] Integrar con `opencode_client.gd` via señales

## Fase 4: EditorBridge

- [x] Crear `core/project_context.gd`
- [x] Obtener script actualmente abierto y su contenido
- [x] Obtener nodo(s) seleccionados en el árbol
- [x] Obtener escena activa
- [x] Crear `core/editor_bridge.gd`
- [x] Analizar respuestas de opencode en busca de código (RegEx)
- [x] Crear/actualizar scripts en el proyecto
- [x] Notificar al editor para refrescar archivos

## Fase 5: Files Dock

- [x] Diseñar UI del files dock en .tscn
- [x] Implementar árbol del proyecto (recursivo)
- [x] Implementar doble clic para abrir archivos
- [ ] Implementar menú contextual
- [ ] Refrescar cuando cambia el FileSystem de Godot

## Fase 6: Terminal Dock

- [x] Diseñar UI del terminal dock en .tscn
- [x] Implementar visualización de salida de opencode
- [x] Implementar línea de comandos
- [x] Implementar botones de limpiar
- [ ] Implementar botón detener

## Fase 7: Pulido y distribución

- [ ] Crear tema visual (`themes/chat_theme.tres`)
- [ ] Implementar manejo de errores robusto (opencode no instalado, conexión perdida)
- [ ] Probar en Windows, Linux y macOS
- [ ] Escribir pruebas de integración
- [ ] Preparar para Asset Library de Godot
- [ ] Publicar versión 1.0.0

## Leyenda

- `[x]` Completado
- `[ ]` Pendiente
