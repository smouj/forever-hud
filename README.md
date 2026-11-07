<div align="center">

<img src="assets/banner.svg" alt="ForeverHUD" width="100%">

# ForeverHUD

**Tu combate, enfocado.** Un HUD limpio y personalizable para World of Warcraft: Forever.

[![Ultima version](https://img.shields.io/github/v/release/smouj/forever-hud?style=flat-square&color=cddaea)](https://github.com/smouj/forever-hud/releases/latest)
[![CI](https://github.com/smouj/forever-hud/actions/workflows/ci.yml/badge.svg)](https://github.com/smouj/forever-hud/actions/workflows/ci.yml)
[![Interface](https://img.shields.io/badge/interface-16001-33414f?style=flat-square)](ForeverHUD/ForeverHUD.toc)
[![Licencia](https://img.shields.io/badge/licencia-MIT-3a7d44?style=flat-square)](LICENSE)

**[Descargar](https://github.com/smouj/forever-hud/releases/latest)** · [Vista previa](https://smouj.github.io/forever-hud/) · [Como se usa](#como-se-usa) · [Preguntas](#preguntas-frecuentes)

</div>

---

## Que es

ForeverHUD pone la informacion importante en el centro de la pantalla: tu vida,
la del objetivo, tus lanzamientos, tus auras y tus botones. Todo con un estilo
sobrio de fantasia oscura y un panel en espanol para cambiarlo a tu gusto.

- Se instala copiando una carpeta.
- Se configura con **/fh**, sin archivos de texto.
- Guarda un perfil por personaje.
- No necesita otros complementos.

## Instalar

**1. Descarga** el archivo **ForeverHUD-1.1.0.zip** desde
[Releases](https://github.com/smouj/forever-hud/releases/latest).

**2. Copia la carpeta** **ForeverHUD** dentro de:

    World of Warcraft\_forever_\Interface\AddOns\

**3. Entra al juego**, comprueba que el addon esta activado y escribe:

    /fh

### Instalador automatico (opcional, Windows)

Si prefieres que lo haga todo solo, ejecuta desde la carpeta del repositorio:

    powershell -ExecutionPolicy Bypass -File install\Install-ForeverHUD.ps1

Detecta el juego, guarda una copia de la version anterior y copia la nueva.

## Como se usa

| Escribe | Para que sirve |
| --- | --- |
| /fh | Abrir el panel de configuracion |
| /fh preview | Ver el HUD con datos de ejemplo, sin combatir |
| /fh unlock | Mover los marcos con el raton |
| /fh lock | Guardar la posicion y bloquear |
| /fh reset | Volver al estilo de fabrica |

Dentro del panel tienes todo lo demas: tamanos, colores, que mostrar y que no.

## Personalizalo a tu gusto

- **Disenos de un clic**: Clasico, Compacto o Minimo. Cambian tamanos y posiciones
  de todo el HUD a la vez.
- **Color de acento**: Acero, Oro, Hielo, Sangre o Esmeralda. Se aplica a bordes,
  esquinas y barras de lanzamiento.
- **Barras**: textura suave o plana, con o sin adornos en las esquinas.
- **Unidades**: muestra u oculta jugador, objetivo, foco, mascota y objetivo del
  objetivo; ajusta anchura, altura, retrato, nombre, nivel y texto de vida.
- **Auras**: tamano, iconos por fila, cuantos mostrar y que grupos ensenar.
- **Barras de accion**: filas, botones, tamano, atajos y contadores.
- **Perfiles**: uno por personaje, con exportar e importar para compartirlo.

## Capturas

<img src="assets/screenshots/hud-clasico.png" alt="ForeverHUD, diseno clasico" width="100%">

<table>
  <tr>
    <td width="50%"><img src="assets/screenshots/hud-compacto.png" alt="Diseno compacto"><br><sub>Compacto</sub></td>
    <td width="50%"><img src="assets/screenshots/configuracion.png" alt="Panel de configuracion"><br><sub>Panel de configuracion</sub></td>
  </tr>
</table>

Las imagenes son una vista previa del diseno con datos de ejemplo, no capturas
del juego.

## Preguntas frecuentes

**¿Funciona en WoW Classic o en otro servidor?**
Esta hecho para World of Warcraft: Forever (Interface 16001). En otros clientes
puede no cargar o verse raro.

**¿Sustituye a ElvUI u otros packs?**
No. ForeverHUD cubre el HUD de combate con un estilo concreto. Si quieres una
suite completa con decenas de modulos, no es esta la herramienta.

**¿Puedo moverlo y cambiar el tamano?**
Si. Escribe /fh unlock, arrastra lo que quieras y luego /fh lock. Los tamanos y
colores se cambian desde el panel.

**¿Se guarda mi configuracion?**
Si, por personaje. Tambien puedes exportar el perfil y volver a importarlo.

**¿Hace algo automatico en combate?**
No. No lanza hechizos, no mueve al personaje y no pulsa botones. Solo muestra
informacion y deja que tus barras de accion funcionen como siempre.

**¿Como lo desinstalo?**
Borra la carpeta ForeverHUD de AddOns y listo.

## Estado

Version **1.1.0**. El complemento pasa las pruebas automaticas del repositorio
(sintaxis, carga, configuracion, auras, lanzamientos y barras), pero la validacion
dentro del cliente esta pendiente. Si algo no se ve bien en tu juego, abre un
issue con una captura y lo corregimos.

## Creditos

Hecho por [SMOUJ](https://github.com/smouj). Licencia [MIT](LICENSE).
World of Warcraft es una marca de Blizzard Entertainment; este proyecto es
comunitario y no esta afiliado ni respaldado por Blizzard.

Para desarrollar o colaborar: [CONTRIBUTING.md](CONTRIBUTING.md).
