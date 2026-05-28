---
description: Propone un mensaje de commit usando Conventional Commits a partir de los cambios actuales.
agent: git-review
subtask: true
---

Propón un mensaje de commit para los cambios actuales del repositorio usando Conventional Commits.

## Estado Git
### git status --short
!`git status --short`

### git diff --stat
!`git diff --stat`

### git diff --cached --stat
!`git diff --cached --stat`

## Instrucción
Analiza el estado actual del repositorio y propón el mejor mensaje de commit posible.

Entrega tu respuesta con esta estructura:
- Commit principal
- Commit alternativo
- Tipo sugerido
- Alcance sugerido
- ¿Conviene dividir el commit?
- ¿Hay breaking change?

Reglas:
- Usa Conventional Commits.
- Prioriza mensajes cortos, claros y específicos.
- Usa modo imperativo.
- No inventes cambios que no estén respaldados por el estado Git.
- Si no hay suficiente contexto para un mensaje confiable, dilo explícitamente.
- Si los cambios parecen mezclar varias responsabilidades, indícalo y sugiere separación.