#!/usr/bin/env python3
"""Claude Code SessionEnd Hook — Sincronizacion con el vault

Corre al final de cada sesion de Claude Code.
Responsabilidades:
1. Sincronizar archivos de memoria → 00 Operating System/Activos/Memoria/
2. Sincronizar MCPs activos → 03 Credenciales/Servicios.md
"""

import sys
import json
import os
from datetime import datetime
from pathlib import Path

VAULT              = "__VAULT_PATH__"
MEMORIA_OBSIDIAN   = f"{VAULT}/00 Operating System/Activos/Memoria"
CREDENCIALES_FILE  = f"{VAULT}/03 Credenciales/Servicios.md"
MEMORY_SOURCE_DIR  = "__MEMORY_DIR__"


def leer_stdin():
    try:
        raw = sys.stdin.read()
        if raw.strip():
            return json.loads(raw)
    except Exception:
        pass
    return {}


def fecha_corta():
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def asegurar_directorio(path):
    Path(path).mkdir(parents=True, exist_ok=True)


# 1. Sincronizar archivos de memoria a Obsidian
def sincronizar_memoria():
    source = Path(MEMORY_SOURCE_DIR)
    if not source.exists():
        return 0

    asegurar_directorio(MEMORIA_OBSIDIAN)

    copiados = 0
    for archivo in source.glob("*.md"):
        destino = Path(MEMORIA_OBSIDIAN) / archivo.name
        contenido_source = archivo.read_text(encoding="utf-8")

        if destino.exists():
            if destino.read_text(encoding="utf-8") == contenido_source:
                continue

        destino.write_text(contenido_source, encoding="utf-8")
        copiados += 1

    return copiados


# 2. Sincronizar MCPs activos → Servicios.md
def sincronizar_mcps():
    import subprocess
    import re

    try:
        result = subprocess.run(
            ["claude", "mcp", "list"],
            capture_output=True, text=True, timeout=30
        )
        output = result.stdout or ""
    except Exception:
        output = ""

    if not output.strip():
        return False

    EXCLUIDOS = {"claude.ai Atlassian", "claude.ai Miro"}

    filas = []
    for linea in output.splitlines():
        linea = linea.strip()
        if not linea or linea.startswith("Checking"):
            continue
        if any(ex in linea for ex in EXCLUIDOS):
            continue

        estado = "✓" if "Connected" in linea else ("⚠️" if "Needs auth" in linea else "✗")

        match = re.match(r'^(.+?):\s+(.+?)\s+-\s+', linea)
        if match:
            nombre = match.group(1).strip()
            ubicacion = match.group(2).strip()
            tipo = "remoto (SSE)" if ubicacion.startswith("http") else "local"
            filas.append(f"| `{nombre}` | {tipo} | `{ubicacion}` | {estado} |")

    if not filas:
        return False

    tabla = "\n".join(filas)
    nueva_seccion = f"""## MCPs Configurados (auto-sync)

> Ultima sincronizacion: {fecha_corta()}

| Nombre | Tipo | Ubicacion / URL | Estado |
|--------|------|-----------------|--------|
{tabla}"""

    cred_path = Path(CREDENCIALES_FILE)
    if not cred_path.exists():
        return False

    contenido = cred_path.read_text(encoding="utf-8")

    MARCA_INICIO = "## MCPs Configurados (auto-sync)"
    if MARCA_INICIO in contenido:
        inicio = contenido.index(MARCA_INICIO)
        resto = contenido[inicio + len(MARCA_INICIO):]
        siguiente_seccion = resto.find("\n## ")
        if siguiente_seccion != -1:
            fin = inicio + len(MARCA_INICIO) + siguiente_seccion
            contenido = contenido[:inicio] + nueva_seccion + contenido[fin + 1:]
        else:
            contenido = contenido[:inicio] + nueva_seccion
    else:
        contenido = contenido.rstrip() + "\n\n" + nueva_seccion

    cred_path.write_text(contenido, encoding="utf-8")
    return True


def main():
    datos = leer_stdin()
    resultados = []

    try:
        copiados = sincronizar_memoria()
        if copiados > 0:
            resultados.append(f"{copiados} archivos de memoria sincronizados")
    except Exception as e:
        resultados.append(f"Error sync memoria: {e}")

    try:
        if sincronizar_mcps():
            resultados.append("MCPs actualizados en Servicios.md")
    except Exception as e:
        resultados.append(f"Error sync MCPs: {e}")

    resumen = " | ".join(resultados) if resultados else "Sin cambios"

    print(json.dumps({
        "systemMessage": f"Obsidian sincronizado — {resumen}"
    }))


if __name__ == "__main__":
    main()
