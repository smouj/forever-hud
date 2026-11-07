# Seguridad

## Versiones soportadas

| Version | Soporte |
| --- | --- |
| 1.0.x | Si |

## Como reportar una vulnerabilidad

No abras un issue publico. Usa **Security > Report a vulnerability** en
<https://github.com/smouj/forever-hud/security/advisories/new> o escribe a
smouj@users.noreply.github.com.

Incluye version de ForeverHUD, version e interfaz del cliente, pasos para
reproducir y el impacto esperado. Respondemos en un plazo orientativo de 7 dias.

## Alcance y modelo de seguridad

ForeverHUD es un complemento local:

- No abre conexiones de red ni envia datos a ningun servidor.
- No descarga codigo ni actualizaciones en tiempo de ejecucion.
- Solo persiste ajustes en ForeverHUDDB (SavedVariables del cliente).
- No automatiza combate, no pulsa botones, no mueve al personaje y no lee
  informacion fuera de la API publica del cliente.
- Los cambios en marcos seguros (barras de accion) se aplazan fuera del combate
  mediante InCombatLockdown; el complemento nunca fuerza atributos seguros en
  combate.

Quedan fuera de alcance los fallos del propio cliente, de otros complementos o
de configuraciones que desactiven las protecciones del juego.
