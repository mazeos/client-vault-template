#!/usr/bin/env python3
"""Stop Hook — Archiva conversaciones en el vault de Obsidian"""

import sys
import json
import os
import re
from pathlib import Path
from datetime import datetime, timezone

# ── Configuración ──────────────────────────────────────────────
VAULT = "__VAULT_PATH__"           # reemplazado por install.sh
NOMBRE_FUNDADOR = "__FOUNDER_NAME__"
CONVERSACIONES_DIR = f"{VAULT}/01 Growth Engine/Operaciones/Infraestructura IA/Claude Code/Conversaciones"
CLAUDE_PROJECTS = os.path.expanduser("~/.claude/projects")
# ───────────────────────────────────────────────────────────────


def leer_stdin():
    try:
        raw = sys.stdin.read()
        return json.loads(raw) if raw.strip() else {}
    except Exception:
        return {}


def encontrar_jsonl(data, session_id):
    tp = data.get("transcript_path")
    if tp:
        p = Path(tp)
        if p.exists():
            return p
    if not session_id:
        return None
    for project_dir in Path(CLAUDE_PROJECTS).iterdir():
        if not project_dir.is_dir():
            continue
        jsonl = project_dir / f"{session_id}.jsonl"
        if jsonl.exists():
            return jsonl
    return None


def extraer_texto(content):
    if isinstance(content, str):
        text = re.sub(r'<[^>]+>[\s\S]*?</[^>]+>', '', content)
        return re.sub(r'<[^>]+/>', '', text).strip()
    elif isinstance(content, list):
        partes = [i.get("text", "").strip() for i in content if isinstance(i, dict) and i.get("type") == "text"]
        return "\n".join(p for p in partes if p)
    return ""


def es_mensaje_real_usuario(linea):
    if linea.get("isMeta"):
        return False
    texto = extraer_texto(linea.get("message", {}).get("content", ""))
    return bool(texto) and not re.match(r'^\s*<', texto)


def parsear_sesion(jsonl_path):
    lineas_raw = []
    with open(jsonl_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    lineas_raw.append(json.loads(line))
                except Exception:
                    continue

    turns = []
    herramientas_globales = set()
    i = 0

    while i < len(lineas_raw):
        linea = lineas_raw[i]
        if linea.get("type") == "user" and es_mensaje_real_usuario(linea):
            texto_user = extraer_texto(linea.get("message", {}).get("content", ""))
            ts_user = linea.get("timestamp", "")
            texto_claude = ""
            tools_turn = []
            j = i + 1
            while j < len(lineas_raw):
                siguiente = lineas_raw[j]
                tipo_sig = siguiente.get("type")
                if tipo_sig == "assistant":
                    content = siguiente.get("message", {}).get("content", [])
                    t = extraer_texto(content)
                    if t and not texto_claude:
                        texto_claude = t
                    if isinstance(content, list):
                        for item in content:
                            if isinstance(item, dict) and item.get("type") == "tool_use":
                                nombre = item.get("name", "")
                                if nombre:
                                    tools_turn.append(nombre)
                                    herramientas_globales.add(nombre)
                    j += 1
                elif tipo_sig == "user" and es_mensaje_real_usuario(siguiente):
                    break
                else:
                    j += 1
            turns.append({"timestamp": ts_user, "user": texto_user, "claude": texto_claude, "tools": tools_turn})
            i = j
        else:
            i += 1

    return turns, sorted(herramientas_globales)


def ts_a_datetime(ts_str):
    try:
        return datetime.fromisoformat(ts_str.replace("Z", "+00:00")).astimezone()
    except Exception:
        return datetime.now().astimezone()


def limpiar_nombre(texto, max_palabras=5):
    texto = re.sub(r'[<>:"/\\|?*\n\r\t]', ' ', texto)
    return " ".join(texto.split()[:max_palabras])[:60].strip() or "Sin titulo"


def construir_markdown(session_id, cwd, turns, herramientas, dt_inicio):
    proyecto = Path(cwd).name if cwd else "desconocido"
    fecha = dt_inicio.strftime("%Y-%m-%d")
    hora = dt_inicio.strftime("%H:%M")

    frontmatter = f"""---
titulo: "Conversación {hora} — {proyecto}"
tipo: conversacion
departamento: operaciones
actualizado: {fecha}
autor: agente
session_id: {session_id}
proyecto: {cwd}
turns: {len(turns)}
herramientas_usadas: [{", ".join(herramientas)}]
---"""

    secciones = []
    for num, turn in enumerate(turns, 1):
        hora_turn = ts_a_datetime(turn["timestamp"]).strftime("%H:%M:%S")
        bloque = f"## Turn {num} — {hora_turn}\n\n**{NOMBRE_FUNDADOR}:** {turn['user']}"
        if turn["claude"]:
            bloque += f"\n\n**Claude:** {turn['claude']}"
        if turn["tools"]:
            bloque += f"\n\n_Herramientas: {', '.join(turn['tools'])}_"
        secciones.append(bloque)

    cuerpo = "\n\n---\n\n".join(secciones) if secciones else "_Sin turns registrados_"
    return frontmatter + "\n\n" + cuerpo + "\n\n---\n\n[[_Sistema/REGLAS]]"


def main():
    data = leer_stdin()
    session_id = data.get("session_id") or os.environ.get("CLAUDE_SESSION_ID", "")
    cwd = data.get("cwd") or os.environ.get("PWD", "")

    if not session_id:
        print(json.dumps({}))
        return

    jsonl_path = encontrar_jsonl(data, session_id)
    if not jsonl_path:
        print(json.dumps({}))
        return

    try:
        turns, herramientas = parsear_sesion(jsonl_path)
    except Exception:
        print(json.dumps({}))
        return

    if not turns:
        print(json.dumps({}))
        return

    dt_inicio = ts_a_datetime(turns[0]["timestamp"])
    nombre_archivo = f"{dt_inicio.strftime('%H-%M')} - {session_id[:6]} - {limpiar_nombre(turns[0]['user'])}.md"
    fecha_str = dt_inicio.strftime("%Y-%m-%d")
    carpeta_dia = Path(CONVERSACIONES_DIR) / fecha_str
    carpeta_dia.mkdir(parents=True, exist_ok=True)

    markdown = construir_markdown(session_id, cwd, turns, herramientas, dt_inicio)
    (carpeta_dia / nombre_archivo).write_text(markdown, encoding="utf-8")
    print(json.dumps({}))


if __name__ == "__main__":
    main()
