#!/usr/bin/env python3
"""SessionStart Hook — Carga contexto desde el vault de Obsidian"""

import sys
import json
from pathlib import Path
from datetime import datetime, timedelta, timezone

# ── Configuración ──────────────────────────────────────────────
VAULT = "__VAULT_PATH__"           # reemplazado por install.sh
NOMBRE_NEGOCIO = "__BUSINESS_NAME__"
CONVERSACIONES_DIR = f"{VAULT}/01 Growth Engine/Operaciones/Infraestructura IA/Claude Code/Conversaciones"

ARCHIVOS_CONTEXTO = [
    (f"{VAULT}/_Sistema/REGLAS.md",                     "Reglas del Vault"),
    (f"{VAULT}/_Sistema/MAPA.md",                       "Mapa del Vault"),
    (f"{VAULT}/00 Agentes/F.A.T.E/Identidad.md",        "Agente Principal"),
    (f"{VAULT}/01 Growth Engine",                        "__DIR_1LEVEL__"),
    (f"{VAULT}/04 Credenciales/Servicios.md",           "Servicios"),
    (f"{VAULT}/02 Fulfillment Engine/Consultoria",       "__DIR__"),
]
# ───────────────────────────────────────────────────────────────


def leer_archivo(path):
    try:
        return Path(path).read_text(encoding="utf-8").strip()
    except Exception:
        return None


def leer_directorio(path, nivel=None):
    partes = []
    carpeta = Path(path)
    if not carpeta.exists():
        return ""
    patron = "*.md" if nivel == 1 else "**/*.md"
    for archivo in sorted(carpeta.glob(patron)):
        if archivo.name.startswith("_") or "Conversaciones" in str(archivo):
            continue
        contenido = leer_archivo(str(archivo))
        if contenido:
            partes.append(f"### {archivo.stem}\n{contenido[:400]}")
    return "\n\n".join(partes)


def cargar_conversaciones_recientes():
    hoy = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    ayer = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")
    archivos = []
    for fecha in [hoy, ayer]:
        carpeta = Path(CONVERSACIONES_DIR) / fecha
        if carpeta.exists():
            archivos.extend(sorted(carpeta.glob("*.md"), reverse=True))
    if not archivos:
        return ""
    partes = []
    for md in reversed(archivos[:3]):
        contenido = leer_archivo(str(md))
        if contenido:
            partes.append(f"### {md.stem}\n" + "\n".join(contenido.splitlines()[:200]))
    return "## Conversaciones Recientes\n\n" + "\n\n---\n\n".join(partes) if partes else ""


def main():
    secciones = []
    for ruta, etiqueta in ARCHIVOS_CONTEXTO:
        if etiqueta == "__DIR__":
            contenido = leer_directorio(ruta)
            if contenido:
                secciones.append(f"## {Path(ruta).name}\n\n{contenido}")
        elif etiqueta == "__DIR_1LEVEL__":
            contenido = leer_directorio(ruta, nivel=1)
            if contenido:
                secciones.append(f"## {Path(ruta).name}\n\n{contenido}")
        else:
            contenido = leer_archivo(ruta)
            if contenido:
                secciones.append(f"## {etiqueta}\n\n{contenido}")

    conv = cargar_conversaciones_recientes()
    if conv:
        secciones.append(conv)

    if not secciones:
        print(json.dumps({}))
        return

    contexto = f"# Contexto cargado desde vault ({NOMBRE_NEGOCIO})\n\n" + "\n\n---\n\n".join(secciones)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": contexto
        }
    }))


if __name__ == "__main__":
    main()
