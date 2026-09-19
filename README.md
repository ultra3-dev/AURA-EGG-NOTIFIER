# AURA EGG NOTIFIER

Notificador de huevos Secret, Eternal y Divine para **Steal an Egg**.

## Archivo principal

- `AURA_EGG_NOTIFIER.lua` — script autocontenido para el ejecutor.

## Configuración

Edita únicamente `CONFIG.WebhookURL` y coloca un webhook nuevo de Discord. Nunca publiques el webhook ni un token de GitHub dentro del código.

El notifier incluye una base de datos local de mascotas con:

- Ubicación
- Spawneo
- Money por segundo
- Tiempo de eclosión
- Velocidad recomendada

Los colores del embed son gris para Secret, morado para Eternal y amarillo para Divine. Los datos detectados directamente en el mensaje del juego tienen prioridad sobre la base local.

## Roles

- Secret: `1544734376640782346`
- Eternal: `1544734452054229173`
- Divine: `1544734510665699389`

## Seguridad

No subas tokens de GitHub ni webhooks a este repositorio. Si un webhook se filtra, elimínalo y genera uno nuevo desde Discord.
