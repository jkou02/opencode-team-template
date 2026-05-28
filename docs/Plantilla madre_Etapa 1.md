# Desarrollo de la plantilla madre de OpenCode: Etapa 1
***
## Etapa 1:
### Principios de diseño:
Con lo que respondiste, la etapa 1 puede quedar fijada en estos principios:
- **Seguridad por defecto**: leer sin fricción, pero pedir aprobación para crear, editar, borrar o ejecutar acciones de riesgo. OpenCode permite configurar permisos con `allow`, `ask` y `deny`, y además parte de defaults bastante permisivos, así que esta política hay que imponerla explícitamente en la plantilla.
- **Base mínima y reusable**: la plantilla madre solo define lo que aplica a casi cualquier repo del equipo; todo lo que dependa del stack debe vivir en módulos o extensiones por proyecto.
- **Contexto compartido versionable**: las reglas del equipo deben estar en archivos del repo o en capas compartidas, no solo en la home de cada persona.
- **Comportamiento eficiente del agente**: concisión en respuestas, uso disciplinado de herramientas y evitar verbosidad innecesaria para reducir costo de tokens; este tipo de instrucciones encaja bien en reglas de `AGENTS.md`.
- **Modularidad por dominio**: módulos separados para stack, documentación, búsqueda e ingestión/carga de repositorios, aprovechando agentes, comandos y skills según corresponda.
### Separación de responsabilidades:

| Capa                    | Qué debe contener                                                                                                                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Global del usuario      | Preferencias personales, modelo favorito, tema, atajos, reglas privadas de estilo personal.                                                 |
| Compartida del equipo   | Reglas de commits, política de edición, estándares de documentación, estructura de `.env.example`, convenciones de repo y comandos comunes. |
| Específica del proyecto | Stack, arquitectura, comandos de build/test, naming concreto, restricciones del dominio y dependencias reales del repo.                     |
### Entregable de etapa 1:
La salida formal de esta etapa debería ser un “brief de arquitectura” con estas decisiones ya congeladas:
1. La plantilla madre será híbrida: local por usuario + compartida por equipo.
2. La base universal cubrirá reglas de trabajo, seguridad, commits, `.gitignore`, variables de entorno base y comportamiento conciso del agente.
3. El stack, secretos y detalles de UI quedarán fuera de la base común.
4. La política por defecto será `read` permitido y edición/ejecución sensible con aprobación mediante `permission`.
5. La extensibilidad se organizará por módulos: stack, documentación, búsqueda y carga/análisis de repositorios.
***