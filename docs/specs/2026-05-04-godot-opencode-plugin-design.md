# Godot Opencode Plugin — Especificación de Diseño

**Fecha:** 2026-05-04
**Versión:** 0.1.0
**Autor:** Roberto Villalobos
**Licencia:** MIT

---

## 1. Objetivo

Plugin para Godot 4.6+ que integra el agente [opencode](https://opencode.ai) directamente en el editor, permitiendo chatear con IA, explorar archivos del proyecto y ejecutar comandos a través de docks nativos del editor. El plugin actúa como un puente entre opencode (que genera código) y el editor de Godot (que aplica cambios al proyecto).

## 2. Características principales

- **Chat interactivo:** Conversación con opencode con contexto del editor (script activo, nodo seleccionado, escena actual)
- **Comandos predefinidos:** Explicar código, mejorar, refactorizar, generar documentación, crear scripts
- **Explorador de archivos:** Navegación del proyecto Godot actual desde un dock nativo
- **Terminal/consola:** Salida de opencode + línea de comandos para enviar instrucciones
- **EditorBridge:** Aplica automáticamente los cambios generados por opencode (scripts, escenas, archivos)
- **Integración total con el editor:** Cambios reflejados inmediatamente en el FileSystem dock, script editor y scene tree

## 3. Arquitectura

El plugin se compone de tres capas:

- **UI Layer (docks):** Paneles acoplables nativos de Godot para chat, archivos y terminal. Cada uno con su escena `.tscn` y script `.gd`.
- **Core Layer:** Lógica central que maneja la comunicación con opencode CLI, recolección de contexto del editor, y aplicación de cambios.
- **Config Layer:** Configuración del plugin y reutilización de la configuración global de opencode.

### Diagrama de flujo

```
Usuario escribe prompt en Chat Dock
       ↓
EditorBridge recolecta contexto (script activo, nodo, escena)
       ↓
OpencodeClient envía prompt + contexto a opencode CLI via stdin
       ↓
Opencode procesa y responde via stdout
       ↓
OpencodeClient recibe respuesta y emite señal
       ↓
Chat Dock muestra respuesta
EditorBridge aplica cambios automáticos si los hay
```

## 4. Comunicación con opencode

- **Mecanismo:** Subproceso CLI local (`OS.create_process()`)
- **Transporte:** stdin/stdout
- **Gestión:** El usuario inicia/detiene opencode manualmente desde el dock de chat
- **Hilos:** La lectura de stdout se delega a `WorkerThreadPool` para no bloquear la UI
- **Señales:** El cliente emite señales (`response_received`, `status_changed`, `error_occurred`) a las que se suscriben los docks

### Manejo de estados

| Estado | Descripción |
|--------|-------------|
| `disconnected` | Opencode no está corriendo |
| `connecting` | Iniciando subproceso |
| `connected` | Listo para recibir prompts |
| `busy` | Procesando un prompt |
| `error` | Error en la comunicación |

## 5. EditorBridge y contexto del proyecto

### `project_context.gd`

Recolecta y empaqueta el contexto actual del editor:

- Script actualmente abierto + su contenido
- Nodo(s) seleccionados en el árbol de la escena
- Escena activa (.tscn)
- Tipo de proyecto (2D/3D)
- Sistema operativo

### `editor_bridge.gd`

Analiza las respuestas de opencode y las traduce en acciones del editor:

- **Código GDScript:** Crear/actualizar scripts en el proyecto
- **Cambios en escenas:** Modificar archivos .tscn
- **Instrucciones de texto:** Mostrar en el chat
- **Comandos de terminal:** Reenviar al terminal dock

## 6. Comandos predefinidos

| Comando | Descripción |
|---------|-------------|
| Explicar código | Envía el script activo a opencode para obtener una explicación |
| Mejorar código | Solicita sugerencias de optimización para el script activo |
| Generar documentación | Genera documentación para el código activo |
| Crear script | Crea un nuevo script basado en una descripción |
| Refactorizar | Refactoriza el código siguiendo mejores prácticas |

## 7. Diseño de los docks

### Chat Dock
- Historial de conversación con formato (bloques de código, texto)
- Campo de entrada de texto con botón de envío
- Barra de comandos predefinidos
- Indicador de estado de opencode (conectado/ocupado/error)
- Botón "Aplicar al proyecto" en respuestas con código

### Files Dock
- Árbol del proyecto Godot
- Doble clic para abrir archivos en el editor
- Menú contextual (copiar ruta, abrir en chat)

### Terminal Dock
- Salida de opencode en tiempo real
- Línea de comandos para escribir prompts directamente
- Botones de limpiar y detener proceso

## 8. Estructura del proyecto

```
godot-opencode/
├── LICENSE
├── README.md
├── ROADMAP.md
├── TASKS.md
├── CHANGELOG.md
├── docs/
│   ├── specs/
│   │   └── 2026-05-04-godot-opencode-plugin-design.md
│   └── usage.md
└── addons/
    └── godot-opencode/
        ├── plugin.cfg
        ├── plugin.gd
        ├── docks/
        │   ├── chat_dock.gd
        │   ├── chat_dock.tscn
        │   ├── files_dock.gd
        │   ├── files_dock.tscn
        │   ├── terminal_dock.gd
        │   └── terminal_dock.tscn
        ├── core/
        │   ├── opencode_client.gd
        │   ├── project_context.gd
        │   ├── editor_bridge.gd
        │   └── settings.gd
        └── themes/
            └── chat_theme.tres
```

## 9. Configuración del plugin

**plugin.cfg:**
- name: "Godot Opencode"
- description: "Asistente de IA opencode integrado en el editor de Godot"
- author, version, script

**Configuración global de opencode:**
- El plugin detecta automáticamente la instalación de opencode en el PATH del sistema
- Usa la configuración existente de opencode (API keys, modelos, etc.)
- Si opencode no está instalado, muestra instrucciones claras al usuario

## 10. Consideraciones técnicas

### Versiones soportadas
- Godot 4.6+
- Sistema operativo: Windows, Linux, macOS

### Manejo de errores
- **Opencode no instalado:** Mensaje claro con enlace a documentación de instalación
- **Subproceso caído:** Detección automática, botón de reconexión
- **Timeout:** El usuario puede cancelar un prompt en curso
- **Error de sintaxis en respuesta:** Validación antes de aplicar cambios al editor

### Temas
- Usa el theme nativo del editor de Godot para consistencia visual
- Bloques de código con fuente monospace

### Rendimiento
- La comunicación con opencode se maneja en segundo plano
- La UI no se bloquea durante el procesamiento
- Límite de tamaño en el historial del chat para evitar consumo excesivo de memoria

## 11. Licencia

MIT License. Ver LICENSE para detalles completos.
