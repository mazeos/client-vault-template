#!/usr/bin/env python3
"""Claude Code SessionStart Hook — Carga contexto desde el vault

Corre al inicio de cada sesion de Claude Code.
Inyecta como contexto el contenido clave del vault de Obsidian para que
Claude tenga el estado completo del negocio desde el primer mensaje.

Estructura del vault:
  _Sistema/, 00 Operating System/, 01 Growth Engine/, 02 Fulfillment Engine/,
  03 Credenciales/
"""

import sys
import json
from pathlib import Path
from datetime import datetime, timedelta, timezone

VAULT = "__VAULT_PATH__"
NOMBRE_NEGOCIO = "__BUSINESS_NAME__"
CONVERSACIONES_DIR = f"{VAULT}/00 Operating System/Claude Code/Conversaciones"

# Archivos a leer y exponer como contexto (en orden de prioridad)
ARCHIVOS_CONTEXTO = [
    (f"{VAULT}/_Sistema/REGLAS.md",                          "Reglas del Vault"),
    (f"{VAULT}/_Sistema/MAPA.md",                            "Mapa del Vault"),
    (f"{VAULT}/01 Growth Engine/Growth Engine.md",            "Growth Engine Dashboard"),
    (f"{VAULT}/01 Growth Engine/Marketing/Marketing.md",      "Marketing Dashboard"),
    (f"{VAULT}/01 Growth Engine/Ventas/Ventas.md",            "Ventas Dashboard"),
    (f"{VAULT}/03 Credenciales/Servicios.md",                "Servicios y Credenciales"),
    (f"{VAULT}/02 Fulfillment Engine/Clientes",               "__DIR__"),
]


def leer_archivo(path: str):
    try:
        return Path(path).read_text(encoding="utf-8").strip()
    except Exception:
        return None


def leer_directorio(path: str) -> str:
    """Lee todos los .md de un directorio (1 nivel) y los concatena."""
    partes = []
    carpeta = Path(path)
    if not carpeta.exists():
        return ""
    for archivo in sorted(carpeta.rglob("*.md")):
        if archivo.name.startswith("_"):
            continue
        contenido = leer_archivo(str(archivo))
        if contenido:
            rel = archivo.relative_to(carpeta)
            partes.append(f"### {rel.stem}\n{contenido[:500]}")
    return "\n\n".join(partes)


def cargar_conversaciones_recientes() -> str:
    """Carga las ultimas 3 conversaciones (hoy + ayer) como contexto."""
    hoy = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    ayer = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")

    archivos = []
    for fecha in [hoy, ayer]:
        carpeta = Path(CONVERSACIONES_DIR) / fecha
        if carpeta.exists():
            for md in sorted(carpeta.glob("*.md"), reverse=True):
                archivos.append(md)

    if not archivos:
        return ""

    # Tomar las 3 mas recientes
    archivos = archivos[:3]

    partes = []
    for md in reversed(archivos):  # cronologico
        contenido = leer_archivo(str(md))
        if not contenido:
            continue
        # Truncar a 300 lineas
        lineas = contenido.splitlines()[:300]
        partes.append(f"### {md.stem}\n" + "\n".join(lineas))

    if not partes:
        return ""

    return "## Conversaciones Recientes\n\n" + "\n\n---\n\n".join(partes)


def main():
    secciones = []

    for ruta, etiqueta in ARCHIVOS_CONTEXTO:
        if etiqueta == "__DIR__":
            nombre_dir = Path(ruta).name
            contenido = leer_directorio(ruta)
            if contenido:
                secciones.append(f"## {nombre_dir}\n\n{contenido}")
        else:
            contenido = leer_archivo(ruta)
            if contenido:
                secciones.append(f"## {etiqueta}\n\n{contenido}")

    # Agregar conversaciones recientes
    conv_recientes = cargar_conversaciones_recientes()
    if conv_recientes:
        secciones.append(conv_recientes)

    if not secciones:
        print(json.dumps({}))
        return

    contexto = (
        f"# Contexto cargado desde el vault ({NOMBRE_NEGOCIO})\n\n"
        + "\n\n---\n\n".join(secciones)
    )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": contexto
        }
    }))


if __name__ == "__main__":
    main()
