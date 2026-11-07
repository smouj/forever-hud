# Contribuir

Gracias por querer mejorar ForeverHUD. El proyecto prioriza tres cosas:
compatibilidad con la API oficial, legibilidad del codigo y que cualquier cambio
se pueda verificar sin abrir el juego.

## Entorno

- Lua 5.1 (el interprete del cliente). En Ubuntu: sudo apt-get install lua5.1
- Python 3 solo para regenerar capturas (scripts/screenshot.py)
- El complemento no usa dependencias externas

## Flujo

1. Abre un issue describiendo el problema o la mejora.
2. Crea una rama: feat/..., fix/..., docs/...
3. Cambia el codigo y anade o ajusta pruebas en tests/.
4. Ejecuta:

        bash scripts/check.sh          # sintaxis de todos los .lua
        lua5.1 tests/run_tests.lua     # 32 pruebas headless
        bash scripts/build.sh          # ZIP instalable en dist/

5. Abre un pull request con el resultado de los tres comandos.

## Reglas de codigo

- Lua 5.1 puro: nada de goto, table.unpack ni operadores de 5.3+.
- Nada de variables globales nuevas salvo las que exige el cliente
  (SLASH_*, SlashCmdList, StaticPopupDialogs).
- Cada modulo se registra con ns:RegisterModule y expone Initialize, Apply y
  Refresh. Un fallo en un modulo no debe tumbar el resto.
- Los eventos se declaran con ns:On; no se crea un OnUpdate por marco salvo para
  animaciones locales.
- Toda opcion nueva va en ns:DefaultProfile(), en el panel y en las pruebas.

## Reglas de seguridad

- Prohibido automatizar combate, movimiento, seleccion de objetivos o pulsaciones.
- Prohibido escribir atributos de marcos seguros en combate.
- Prohibido incluir codigo ofuscado, binarios o llamadas de red.
- Cualquier cambio que toque marcos seguros debe explicar por que es seguro y
  como se ha probado.

## Estilo visual

- Paleta y tipografias definidas en ns.theme; no se introducen colores sueltos.
- Textos nuevos en Locales.lua para espanol e ingles.
- Capturas actualizadas con python3 scripts/screenshot.py si cambia el HUD.
