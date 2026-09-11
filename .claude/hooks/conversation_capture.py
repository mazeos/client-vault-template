#!/usr/bin/env python3
"""Claude Code Stop Hook — Captura conversaciones al vault

Se ejecuta despues de cada respuesta de Claude (evento Stop).
Escribe/sobreescribe el .md de la sesion actual en:
  vault / 00 Operating System / Claude Code / Conversaciones / {fecha} /
"""

import sys
import json
import os
import re
import time
from pathlib import Path
from datetime import datetime, timezone

VAULT = "__VAULT_PATH__"
CONVERSACIONES_DIR = f"{VAULT}/00 Operating System/Claude Code/Conversaciones"
CLAUDE_PROJECTS = os.path.expanduser("~/.claude/projects")


def leer_stdin():
    try:
        raw = sys.stdin.read()
        if raw.strip():
            return json.loads(raw)
        return {}
    except Exception:
        return {}


def encontrar_jsonl(data, session_id):
    """Encuentra el archivo JSONL de la sesion en cualquier proyecto."""
    # Opcion 1: transcript_path en stdin
    tp = data.get("transcript_path")
    if tp:
        p = Path(tp)
        if p.exists():
            return p

    if not session_id:
        return None

    # Opcion 2: buscar en todos los directorios de proyecto
    for project_dir in Path(CLAUDE_PROJECTS).iterdir():
        if not project_dir.is_dir():
            continue
        jsonl = project_dir / f"{session_id}.jsonl"
        if jsonl.exists():
            return jsonl

    return None


def extraer_texto(content):
    """Extrae texto plano de message.content (string o array)."""
    if isinstance(content, str):
        # Eliminar bloques de tags XML del sistema
        text = re.sub(r'<[^>]+>[\s\S]*?</[^>]+>', '', content)
        text = re.sub(r'<[^>]+/>', '', text)
        return text.strip()
    elif isinstance(content, list):
        partes = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                partes.append(item.get("text", "").strip())
        return "\n".join(p for p in partes if p)
    return ""


def es_mensaje_real_usuario(linea):
    """True si es un mensaje genuino del usuario (no sistema ni meta)."""
    if linea.get("isMeta"):
        return False
    content = linea.get("message", {}).get("content", "")
    texto = extraer_texto(content)
    if not texto:
        return False
    # Descartar mensajes que son puramente tags de sistema
    if re.match(r'^\s*<', texto):
        return False
    return True


def parsear_sesion(jsonl_path):
    """
    Parsea el JSONL y devuelve lista de turns + herramientas usadas.
    Cada turn = dict con role, timestamp, texto, tools_usadas.
    """
    lineas_raw = []
    with open(jsonl_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                lineas_raw.append(json.loads(line))
            except Exception:
                continue

    # Agrupar en turns: un turn = mensaje user + respuesta(s) assistant
    turns = []
    herramientas_globales = set()
    i = 0

    while i < len(lineas_raw):
        linea = lineas_raw[i]

        if linea.get("type") == "user" and es_mensaje_real_usuario(linea):
            texto_user = extraer_texto(linea.get("message", {}).get("content", ""))
            ts_user = linea.get("timestamp", "")

            # Recopilar respuesta(s) de assistant a continuacion.
            # Importante: los tool_result tambien tienen type="user" en el JSONL,
            # solo romper cuando es un mensaje real del usuario.
            bloques_claude = []
            tools_turn = []
            j = i + 1

            while j < len(lineas_raw):
                siguiente = lineas_raw[j]
                tipo_sig = siguiente.get("type")

                if tipo_sig == "assistant":
                    content = siguiente.get("message", {}).get("content", [])
                    t = extraer_texto(content)
                    if t:
                        bloques_claude.append(t)
                    # Extraer herramientas usadas en este turn
                    if isinstance(content, list):
                        for item in content:
                            if isinstance(item, dict) and item.get("type") == "tool_use":
                                nombre_tool = item.get("name", "")
                                if nombre_tool:
                                    tools_turn.append(nombre_tool)
                                    herramientas_globales.add(nombre_tool)
                    j += 1
                elif tipo_sig == "user" and es_mensaje_real_usuario(siguiente):
                    # Solo romper si es un mensaje genuino del usuario (no tool_result)
                    break
                else:
                    j += 1

            texto_claude = "\n\n".join(bloques_claude)

            turns.append({
                "timestamp": ts_user,
                "user": texto_user,
                "claude": texto_claude,
                "tools": tools_turn,
            })
            i = j

        else:
            i += 1

    return turns, sorted(herramientas_globales)


def limpiar_nombre_archivo(texto, max_palabras=5):
    """Primeras N palabras del texto, limpias para nombre de archivo."""
    # Quitar caracteres no permitidos en nombres de archivo
    texto = re.sub(r'[<>:"/\\|?*\n\r\t]', ' ', texto)
    palabras = texto.split()[:max_palabras]
    nombre = " ".join(palabras)
    return nombre[:60].strip() if nombre else "Sin titulo"


def sanear_titulo(texto):
    """Limpia un titulo para usarlo como nombre de archivo."""
    texto = re.sub(r'[<>:"/\\|?*\n\r\t]', ' ', texto or "")
    texto = " ".join(texto.split())
    return texto[:70].strip()


def extraer_titulo_sesion(jsonl_path):
    """Titulo que Claude Code muestra en la lista de sesiones.

    Prioridad: custom-title (puesto a mano) > ultimo ai-title > None.
    """
    custom = None
    ai = None
    try:
        for linea in jsonl_path.open(encoding="utf-8"):
            if '"custom-title"' not in linea and '"ai-title"' not in linea:
                continue
            try:
                obj = json.loads(linea)
            except Exception:
                continue
            if obj.get("type") == "custom-title" and obj.get("customTitle"):
                custom = obj["customTitle"]
            elif obj.get("type") == "ai-title" and obj.get("aiTitle"):
                ai = obj["aiTitle"]
    except Exception:
        return None
    return sanear_titulo(custom or ai) or None


def limpiar_versiones_previas(carpeta, session_id, archivo_destino):
    """Borra .md anteriores de la misma sesion (el titulo cambia al renombrar)."""
    for md in carpeta.glob("*.md"):
        if md == archivo_destino:
            continue
        try:
            cabecera = md.read_text(encoding="utf-8")[:600]
        except Exception:
            continue
        if f"session_id: {session_id}" in cabecera:
            try:
                md.unlink()
            except Exception:
                pass


def ts_a_datetime(ts_str):
    """Convierte timestamp ISO a datetime en hora local del sistema."""
    try:
        dt_utc = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt_utc.astimezone()  # Convierte a timezone local (zona horaria del sistema)
    except Exception:
        return datetime.now().astimezone()


def construir_markdown(session_id, cwd, turns, herramientas, dt_inicio, titulo=None):
    """Construye el markdown completo de la conversacion."""
    proyecto = Path(cwd).name if cwd else "desconocido"
    fecha = dt_inicio.strftime("%Y-%m-%d")
    hora = dt_inicio.strftime("%H:%M")
    titulo_fm = (titulo or f"Conversación {hora} — {proyecto}").replace('"', "'")

    frontmatter = f"""---
titulo: "{titulo_fm}"
tipo: conversacion
departamento: operating-system
actualizado: {fecha}
autor: agente
session_id: {session_id}
proyecto: {cwd}
turns: {len(turns)}
herramientas_usadas: [{", ".join(herramientas)}]
---"""

    secciones = []
    for num, turn in enumerate(turns, 1):
        dt = ts_a_datetime(turn["timestamp"])
        hora_turn = dt.strftime("%H:%M:%S")

        bloque = f"## Turn {num} — {hora_turn}\n\n**__FOUNDER_NAME__:** {turn['user']}"

        if turn["claude"]:
            bloque += f"\n\n**Claude:** {turn['claude']}"

        if turn["tools"]:
            bloque += f"\n\n_Herramientas: {', '.join(turn['tools'])}_"

        secciones.append(bloque)

    cuerpo = "\n\n---\n\n".join(secciones) if secciones else "_Sin turns registrados_"
    link = "\n\n---\n\n[[_Sistema/REGLAS]]"
    return frontmatter + "\n\n" + cuerpo + link


def main():
    data = leer_stdin()

    # Obtener session_id y cwd
    session_id = (
        data.get("session_id")
        or os.environ.get("CLAUDE_SESSION_ID", "")
    )
    cwd = (
        data.get("cwd")
        or os.environ.get("PWD", "")
    )

    if not session_id:
        print(json.dumps({}))
        return

    # Encontrar archivo JSONL
    jsonl_path = encontrar_jsonl(data, session_id)
    if not jsonl_path:
        print(json.dumps({}))
        return

    # Esperar a que el JSONL deje de crecer antes de leerlo
    prev_size = -1
    for _ in range(10):
        time.sleep(0.5)
        curr_size = jsonl_path.stat().st_size
        if curr_size == prev_size:
            break
        prev_size = curr_size

    # Parsear sesion
    try:
        turns, herramientas = parsear_sesion(jsonl_path)
    except Exception:
        print(json.dumps({}))
        return

    # Necesita al menos un turn real
    if not turns:
        print(json.dumps({}))
        return

    # Timestamp de inicio (primer turn del usuario)
    dt_inicio = ts_a_datetime(turns[0]["timestamp"])

    # Titulo: el mismo que muestra Claude Code; si no hay, primeras 5 palabras
    titulo = extraer_titulo_sesion(jsonl_path)
    nombre_corto = titulo or limpiar_nombre_archivo(turns[0]["user"], max_palabras=5)

    # Nombre final del archivo
    hora_str = dt_inicio.strftime("%H-%M")
    nombre_archivo = f"{hora_str} - {nombre_corto}.md"

    # Crear carpeta por fecha
    fecha_str = dt_inicio.strftime("%Y-%m-%d")
    carpeta_dia = Path(CONVERSACIONES_DIR) / fecha_str
    carpeta_dia.mkdir(parents=True, exist_ok=True)

    # Colision: mismo horario y titulo que OTRA sesion -> desambiguar con el id
    archivo_destino = carpeta_dia / nombre_archivo
    if archivo_destino.exists():
        try:
            cabecera = archivo_destino.read_text(encoding="utf-8")[:600]
        except Exception:
            cabecera = ""
        if f"session_id: {session_id}" not in cabecera:
            archivo_destino = carpeta_dia / f"{hora_str} - {nombre_corto} ({session_id[:6]}).md"

    # Escribir (sobreescribir) el archivo
    markdown = construir_markdown(session_id, cwd, turns, herramientas, dt_inicio, titulo)
    archivo_destino.write_text(markdown, encoding="utf-8")

    # El titulo cambia cuando Claude Code lo genera: borrar el .md viejo
    limpiar_versiones_previas(carpeta_dia, session_id, archivo_destino)

    print(json.dumps({}))


if __name__ == "__main__":
    main()
