# Plan de pruebas

ForeverHUD se distribuye con dos niveles de verificacion: automatica (sin
cliente) y manual (dentro del cliente). Este documento es la lista de
comprobacion para la segunda.

## 1. Verificacion automatica (CI)

| Comprobacion | Comando | Estado |
| --- | --- | --- |
| Sintaxis Lua 5.1 de todos los ficheros | bash scripts/check.sh | verde |
| 32 pruebas headless con API simulada | lua5.1 tests/run_tests.lua | verde |
| Estructura del TOC y ficheros declarados | incluida en las pruebas | verde |
| Empaquetado instalable | bash scripts/build.sh | verde |
| Integridad del ZIP | testzip de Python | verde |

La suite cubre: carga del addon, base de datos y perfiles, marcos de unidad,
eventos de unidad, castbars, auras con filtros y orden, barras de accion,
bloqueo en combate, posiciones, vista previa, comandos y panel de configuracion.

## 2. Verificacion manual en el cliente

Precondiciones:

- Cliente World of Warcraft: Forever con Interface 16001.
- Copia limpia del complemento en _forever_\Interface\AddOns\ForeverHUD.
- Personaje nivel 60 con al menos un hechizo con lanzamiento y uno instantaneo.
- Interfaz del juego en espanol o ingles para comprobar textos.

Ejecuta cada caso y anota el resultado. Un fallo debe ir con captura y el mensaje
de error de /console scriptErrors 1.

| ID | Caso | Pasos | Resultado esperado |
| --- | --- | --- | --- |
| T01 | Carga | Iniciar sesion | Mensaje de ForeverHUD; /fh abre el panel |
| T02 | Marcos base | Observar jugador y objetivo | Vida, recurso, nombre y nivel correctos |
| T03 | Objetivo sin objetivo | Seleccionar y deseleccionar | El marco se oculta y reaparece sin errores |
| T04 | Objetivo del objetivo | Seleccionar un mob que ataque a otro | Nombre y vida del objetivo del objetivo |
| T05 | Foco | /focus a un jugador | Marco con clase y vida correctas |
| T06 | Mascota | Invocar y descartar mascota | El marco aparece y desaparece |
| T07 | Dano y curacion | Recibir dano y curarse | Barras y porcentajes siguen el cambio |
| T08 | Castbar propia | Lanzar un hechizo de 2 s | Nombre, icono, tiempo y barra progresan |
| T09 | Castbar ajena | Provocar un lanzamiento enemigo | Barra roja, nombre y aviso de interrumpible |
| T10 | Canalizacion | Lanzar un canal | La barra se llena y se oculta al terminar |
| T11 | Auras propias | Aplicar buff y debuff | Iconos, stacks y barrido correctos |
| T12 | Auras del objetivo | Aplicar 2 debuffs | Orden por expiracion y color de dispel |
| T13 | Barras de accion | Pulsar botones 1-12 y 61-72 | Cada boton lanza la accion de su ranura |
| T14 | Enfriamientos | Usar una habilidad con CD | Barrido y contador correctos |
| T15 | Cambio en combate | Mover un slider en combate | La barra no se reconstruye hasta salir |
| T16 | Mover y bloquear | /fh unlock, arrastrar, /fh lock | Posicion guardada tras /reload |
| T17 | Perfiles | Crear perfil, cambiar, /reload | Cada personaje conserva su perfil |
| T18 | Exportar e importar | Exportar, borrar perfil, importar | El perfil restaurado mantiene ajustes |
| T19 | Vista previa | /fh preview | Datos simulados sin combate |
| T20 | Ocultar Blizzard | Activar la opcion | Marcos originales ocultos y restaurables |

## 3. Plantilla de resultados

    Fecha:
    Cliente / build:
    Interface:
    Personaje y clase:
    Resolucion y escala de UI:

    T01: OK / FALLO - notas
    ...
    T20: OK / FALLO - notas

    Errores de Lua:

Adjunta el resultado a un issue con la etiqueta test-report.
