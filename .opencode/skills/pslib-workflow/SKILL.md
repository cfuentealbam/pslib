---
name: pslib-workflow
description: Orquesta el ciclo Discovery -> Spec Design -> Planning -> Implementacion -> Testing -> Review -> Documentacion de pslib usando agentes separados. Usar cuando el trabajo deba seguir el flujo formal de pslib o haya que decidir que agente cargar para una etapa.
compatibility: opencode
---

# pslib Workflow

Usa este skill cuando el trabajo deba seguir el flujo formal de pslib o cuando haya que decidir que agente cargar para una etapa.

## Carga

1. Lee `AGENTS.md`.
2. Lee `.opencode/agents/pslib-orchestrator.md`.
3. Lee solo el archivo necesario en `.opencode/agents/`.
4. Usa `.opencode/commands/*.md` como entrypoints de conveniencia.

## Ubicacion del desarrollo

- Bajo la configuracion vigente, todo desarrollo nuevo vive en `tools/{NombreTool}`.
- Antes de crear una carpeta de tool nueva, acuerda explicitamente el nombre con el usuario y usa exactamente ese nombre en el directorio.
- Trata este repo como incubadora exclusiva de scripts PowerShell.
- Los artefactos del flujo viven en `tools/{NombreTool}/plan/`.
- Si el trabajo requiere `modules/` o `mcp/`, deten el flujo y pide primero un cambio explicito de configuracion.

## Routing

- Nuevas funcionalidades o nuevos artefactos -> `discovery-agent`
- Refinamiento funcional fuera de spec -> `spec-design-agent`
- Historia aprobada a plan tecnico -> `planning-agent`
- Dev spec aprobado a codigo -> `dev-agent`
- Codigo implementado a verificacion -> `testing-agent`
- Test aprobado a revision critica -> `review-agent`
- Review aprobado a docs -> `docs-agent`

## Politica de modelos

- `openai/gpt-5.5`: discovery, spec design, planning, review y orquestacion.
- `openai/gpt-5.4-mini`: implementacion, testing y documentacion por historia.

## Reglas

- No avances de etapa sin `APROBADO` previo.
- Si aparece trabajo fuera de spec, vuelve a Spec Design.
- Si cambia una historia aprobada, vuelve a Planning antes de implementar.
- Prioriza un solo agente por vez salvo que el problema sea realmente paralelo y no comparta write-set.
