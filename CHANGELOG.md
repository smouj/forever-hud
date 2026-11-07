# Changelog

Todas las versiones relevantes de ForeverHUD. Formato basado en
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y versionado
[semantico](https://semver.org/lang/es/).

## [1.1.0] - 2026-11-07

### Anadido

- Nueva identidad visual: icono, banner y simbolo oficiales del kit de marca.
- Paleta "Acero" por defecto y cinco colores de acento (Acero, Oro, Hielo,
  Sangre y Esmeralda) aplicados a bordes, esquinas y barras de lanzamiento.
- Seccion **Estilo** en el panel con tres disenos de un clic: Clasico, Compacto
  y Minimo.
- Texturas de barra suaves o planas, con opcion de adornos en las esquinas.
- Chispa de progreso en las barras de lanzamiento.
- Esquinas ornamentales en marcos, barras de lanzamiento y barra de accion.

### Cambiado

- Paleta general del HUD a azul acero, mas legible sobre fondos oscuros.
- README reescrito para jugadores: instalacion en tres pasos, personalizacion y
  preguntas frecuentes, sin secciones tecnicas.
- Capturas y vista previa actualizadas al nuevo estilo.

### Corregido

- Las barras de lanzamiento usaban el color verde por defecto; ahora la del
  jugador usa el color de acento y la del objetivo un rojo apagado.
- Los textos largos de los marcos ya no se solapan: nombre arriba, nivel y vida
  en la linea inferior.

### Pruebas

- 32 pruebas headless (antes 30), incluyendo disenos y color de acento.

## [1.0.0] - 2026-11-07

Primera version publica.

### Anadido

- HUD de fantasia oscura para World of Warcraft: Forever (Interface 16001).
- Marcos de jugador, objetivo, foco, mascota y objetivo del objetivo con vida,
  recurso, nombre, nivel, clasificacion, marcador de banda y retrato opcional.
- Barras de lanzamiento de jugador y objetivo con icono, tiempo restante y aviso
  de hechizo interrumpible.
- Auras: buffs y debuffs del jugador y debuffs del objetivo, con contador de
  stacks, barrido de reutilizacion y color por tipo de dispel.
- Barras de accion seguras de 1 a 3 filas y hasta 12 botones por fila, con
  atajos, contadores, enfriamientos y feedback de uso y alcance.
- Panel de configuracion en espanol e ingles con seis secciones y controles en
  vivo, sin dependencias externas.
- Perfiles por personaje, exportacion e importacion en texto y restablecimiento
  de fabrica.
- Modo preview con datos simulados para revisar el diseno sin entrar en combate.
- Posiciones libres con /fh unlock y guardado automatico por elemento.
- Instalador de Windows (install/Install-ForeverHUD.ps1) con deteccion de la
  carpeta del cliente, copia de seguridad y verificacion del destino.
- Arnes de pruebas headless (tests/) con una implementacion simulada de la API
  del cliente: 30 pruebas, sin necesidad de ejecutar el juego.
- CI en GitHub Actions (sintaxis Lua 5.1, pruebas y empaquetado) y flujo de
  release con ZIP verificado.

### Limitaciones conocidas

- La validacion dentro del cliente real esta pendiente; ver TEST_PLAN.md.
- Las barras de accion usan ranuras fijas: no hay paginacion automatica por
  forma, sigilo o vehiculo en 1.0.
- Los marcos de unidad son solo de lectura: no seleccionan objetivo al hacer clic.
- El cliente puede reabrir sus marcos originales tras ciertos eventos si se
  activa "Ocultar marcos de Blizzard"; es un ajuste opcional y reversible.

[1.0.0]: https://github.com/smouj/forever-hud/releases/tag/v1.0.0
