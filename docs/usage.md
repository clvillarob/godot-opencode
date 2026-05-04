# Godot Opencode Plugin — Guía de uso

## Requisitos

- Godot 4.6 o superior
- [opencode](https://opencode.ai) instalado y configurado en el sistema (accesible via PATH)
- API key configurada en opencode (OpenAI, Anthropic u otro proveedor)

## Instalación

1. Copia la carpeta `addons/godot-opencode/` en la carpeta `addons/` de tu proyecto Godot
2. Abre tu proyecto en Godot
3. Ve a **Proyecto > Configuración del proyecto > Plugins**
4. Busca "Godot Opencode" y haz clic en **Activar**

## Primeros pasos

### 1. Iniciar opencode

Una vez activado el plugin, verás tres docks nuevos:

- **Opencode Chat** — Para conversar con el agente
- **Opencode Files** — Explorador de archivos del proyecto
- **Opencode Terminal** — Consola de salida y comandos

Haz clic en el botón **Iniciar opencode** en el dock de Chat para iniciar el subproceso.

### 2. Usar el chat interactivo

Escribe un prompt en el campo de texto y presiona Enter o haz clic en el botón de enviar. El plugin automáticamente incluye contexto del editor (archivo abierto, nodo seleccionado, etc.) en el prompt.

Ejemplos:

- "Crea un script de movimiento para un CharacterBody2D"
- "Explica qué hace esta función"
- "Agrega un sistema de partículas a la escena actual"

### 3. Comandos predefinidos

Usa los botones en la barra de comandos para acciones rápidas:

- **Explicar código** — Explica el script actualmente abierto
- **Mejorar** — Sugiere optimizaciones
- **Documentar** — Genera documentación
- **Refactorizar** — Refactoriza el código
- **Crear script** — Formula una descripción para un nuevo script

### 4. Explorar archivos

El dock de Files muestra la estructura de tu proyecto. Haz doble clic para abrir archivos en el editor.

### 5. Terminal

La terminal muestra la salida de opencode. También puedes escribir comandos directamente.

## Solución de problemas

| Problema | Solución |
|----------|----------|
| "opencode no encontrado" | Instala opencode y asegúrate de que esté en el PATH del sistema |
| "Error de conexión" | Haz clic en "Reiniciar opencode" |
| El chat no responde | Verifica que opencode esté iniciado (botón verde) |
