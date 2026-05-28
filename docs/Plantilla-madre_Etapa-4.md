# Desarrollo de la plantilla madre de OpenCode: Etapa 4
***
## Etapa 4:
La etapa 4 consiste en diseñar el opencode.json base, porque ahí se define el comportamiento técnico global o por proyecto: modelo, agente por defecto, instrucciones cargadas y, sobre todo, permisos. 
### Reglas clave
La documentación indica que el campo `permission` acepta tres acciones, `allow`, `ask` y `deny`, y que puede aplicarse globalmente o por herramienta usando reglas granulares donde la última coincidencia gana. También deja claro que `read` es `allow` por defecto, mientras que `external_directory` y `doom_loop` ya tienden a pedir confirmación, pero si quieres una política más estricta conviene declararla explícitamente en el archivo.
### Estructura sugerida para el `opencode.json`:
```text
{
  "$schema": "https://opencode.ai/config.json",

  "model": "opencode/gpt-5.1-codex",
  "small_model": "opencode/gpt-5.1-mini",

  "default_agent": "build",

  "instructions": [
    "./AGENTS.md"
  ],

  "permission": {
    "*": "allow",

    "read": "allow",
    "list": "allow",
    "grep": "allow",
    "glob": "allow",
    "question": "allow",

    "edit": "ask",
    "task": "ask",
    "skill": "ask",
    "webfetch": "ask",
    "websearch": "ask",
    "external_directory": "ask",
    "doom_loop": "deny",

    "bash": {
      "*": "ask",

      "pwd": "allow",
      "ls*": "allow",
      "tree*": "allow",
      "find*": "allow",
      "grep*": "allow",
      "cat*": "allow",
      "head*": "allow",
      "tail*": "allow",

      "git status*": "allow",
      "git diff*": "allow",
      "git log*": "allow",
      "git branch*": "allow",

      "git add*": "ask",
      "git commit*": "ask",
      "git switch*": "ask",
      "git checkout*": "ask",
      "git restore*": "ask",
      "git reset*": "ask",
      "git revert*": "ask",
      "git merge*": "ask",
      "git rebase*": "ask",
      "git pull*": "ask",
      "git push*": "ask",

      "npm *": "ask",
      "pnpm *": "ask",
      "yarn *": "ask",
      "bun *": "ask",
      "pip *": "ask",
      "poetry *": "ask",
      "uv *": "ask",

      "cp*": "ask",
      "mv*": "ask",
      "rm*": "ask",
      "mkdir*": "ask",
      "chmod*": "ask",

      "sudo*": "deny",
      "chown*": "deny"
    }
  }
}
```
#### Ajustes que podrías considerar
Hay tres decisiones que puedes dejar tal como están o ajustar más tarde según cómo prueben el flujo del equipo:
- `websearch` y `webfetch` en `ask`: es seguro para controlar gasto y ruido, pero si el equipo investiga mucho documentación externa, podrías pasar uno de los dos a `allow` más adelante.
- Gestores de paquetes en `ask`: esto evita instalaciones automáticas no deseadas, lo cual suele ser buena política en equipos.
- `mkdir*` en `ask`: es consistente con tu política de “crear/modificar con permiso”, aunque si lo sientes demasiado estricto puedes moverlo luego a `allow`.
***