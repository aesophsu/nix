#!/usr/bin/env python3
"""
Minimal MCP filesystem server over stdio.

Tools:
- list_directory(path: string)
- read_file(path: string, max_bytes?: int)

Root: /Users/sue
ALLOWED_PATHS can be edited to narrow scope later.
"""

import sys
import json
from pathlib import Path
from typing import Any, Dict, List, Optional
from datetime import datetime
import traceback

JSONRPC_VERSION = "2.0"
MCP_PROTOCOL_VERSION = "2024-11-05"

# ---- Security / scope -------------------------------------------------------

def _detect_root() -> Path:
  """
  根据命令行参数或默认值选择根目录：
  - 如果提供了第 1 个参数，则作为根目录（配合 .cursor/mcp.json 里的 args 使用）；
  - 否则退回到 /Users/sue 作为默认。
  """
  if len(sys.argv) >= 2:
    return Path(sys.argv[1]).expanduser().resolve()
  return Path("/Users/sue").resolve()


ROOT = _detect_root()

# 允许访问的白名单目录（最小权限原则）：
# - ~/.openclaw             : OpenClaw 相关配置与工具
# - ~/Code                  : 所有代码与配置仓库（含本 nix 仓库）
# - ~/dev, ~/go             : 其他开发项目
# - ~/Documents/mimic       : MIMIC 分析项目（按 home-layout 规则依旧放在 Documents 下）
# - ~/Documents/PhysioNet   : PhysioNet 相关数据与代码
#
# 如需扩展，请显式在这里添加子目录，而不是放开整个 ~ 或整个 Documents。
ALLOWED_PATHS: List[Path] = [
  ROOT / ".openclaw",
  ROOT / "Code",
  ROOT / "dev",
  ROOT / "go",
  ROOT / "Documents" / "mimic",
  ROOT / "Documents" / "PhysioNet",
]


def is_path_allowed(p: Path) -> bool:
  """
  检查路径是否在 ALLOWED_PATHS 允许的范围内。
  """
  p = p.resolve()
  for allowed in ALLOWED_PATHS:
    allowed = allowed.resolve()
    if p == allowed or allowed in p.parents:
      return True
  return False


def normalize_path(path_str: str) -> Path:
  """
  把用户传入路径转换到绝对路径，并做安全检查。
  - 相对路径：认为是相对于 ROOT。
  - 绝对路径：直接使用。
  """
  p = Path(path_str)
  if not p.is_absolute():
    p = ROOT / p

  p = p.resolve()

  if not is_path_allowed(p):
    raise PermissionError(
      f"path '{p}' is outside allowed roots: "
      + ", ".join(str(a) for a in ALLOWED_PATHS)
    )

  return p


# ---- 工具实现 ---------------------------------------------------------------

def tool_list_directory(path: str) -> str:
  """
  列出指定目录中的文件和子目录（不递归）。
  返回 JSON 文本字符串，方便在 MCP 中展示。
  """
  p = normalize_path(path)

  if not p.exists():
    raise FileNotFoundError(f"directory does not exist: {p}")
  if not p.is_dir():
    raise NotADirectoryError(f"path is not a directory: {p}")

  entries = []
  for entry in sorted(p.iterdir(), key=lambda e: e.name):
    try:
      st = entry.stat()
      entries.append(
        {
          "name": entry.name,
          "path": str(entry),
          "is_dir": entry.is_dir(),
          "size": st.st_size,
          "modified": datetime.fromtimestamp(st.st_mtime).isoformat(),
        }
      )
    except Exception as e:  # 某些文件可能权限不足
      entries.append(
        {
          "name": entry.name,
          "path": str(entry),
          "is_dir": entry.is_dir(),
          "error": str(e),
        }
      )

  return json.dumps(
    {
      "directory": str(p),
      "entries": entries,
    },
    indent=2,
    ensure_ascii=False,
  )


def tool_read_file(path: str, max_bytes: Optional[int] = None) -> str:
  """
  读取文本文件开头内容，UTF‑8 解码（无法解码的字符用 � 替代）。
  max_bytes 为读取的最大字节数（默认 64KB，上限 1MB）。
  """
  DEFAULT_MAX = 64 * 1024
  HARD_CAP = 1 * 1024 * 1024  # 1MB 安全上限

  if max_bytes is None:
    max_bytes = DEFAULT_MAX
  else:
    # 防止恶意传入超大值
    max_bytes = max(0, min(int(max_bytes), HARD_CAP))

  p = normalize_path(path)

  if not p.exists():
    raise FileNotFoundError(f"file does not exist: {p}")
  if not p.is_file():
    raise IsADirectoryError(f"path is not a regular file: {p}")

  with p.open("rb") as f:
    data = f.read(max_bytes + 1)  # +1 用来判断是否被截断

  truncated = len(data) > max_bytes
  if truncated:
    data = data[:max_bytes]

  text = data.decode("utf-8", errors="replace")

  header = [
    f"Path: {p}",
    f"Bytes read: {len(data)}",
    f"Truncated: {truncated}",
    "",
  ]
  return "\n".join(header) + text


# ---- MCP / JSON‑RPC 基础框架 -----------------------------------------------

def make_result(id_: Any, result: Any) -> Dict[str, Any]:
  return {
    "jsonrpc": JSONRPC_VERSION,
    "id": id_,
    "result": result,
  }


def make_error(id_: Any, code: int, message: str, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
  err: Dict[str, Any] = {
    "jsonrpc": JSONRPC_VERSION,
    "id": id_,
    "error": {
      "code": code,
      "message": message,
    },
  }
  if data is not None:
    err["error"]["data"] = data
  return err


def send(msg: Dict[str, Any]) -> None:
  sys.stdout.write(json.dumps(msg, ensure_ascii=False) + "\n")
  sys.stdout.flush()


def handle_initialize(req: Dict[str, Any]) -> None:
  id_ = req.get("id")

  tools = [
    {
      "name": "list_directory",
      "description": "List files and subdirectories under a given path.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "path": {
            "type": "string",
            "description": "Directory path (absolute or relative to /Users/sue).",
          }
        },
        "required": ["path"],
      },
    },
    {
      "name": "read_file",
      "description": "Read the beginning of a text file as UTF-8.",
      "inputSchema": {
        "type": "object",
        "properties": {
          "path": {
            "type": "string",
            "description": "File path (absolute or relative to /Users/sue).",
          },
          "max_bytes": {
            "type": "integer",
            "description": "Maximum bytes to read (default ~64KB, hard cap 1MB).",
          },
        },
        "required": ["path"],
      },
    },
  ]

  result = {
    "protocolVersion": MCP_PROTOCOL_VERSION,
    "serverInfo": {
      "name": "filesystem-mcp-python",
      "version": "0.1.0",
    },
    "capabilities": {
      "tools": {},
    },
    "tools": tools,
  }

  send(make_result(id_, result))


def handle_tools_list(req: Dict[str, Any]) -> None:
  id_ = req.get("id")
  # 返回的 tools 列表结构与 initialize 里的相同
  tools_result = {
    "tools": [
      {
        "name": "list_directory",
        "description": "List files and subdirectories under a given path.",
        "inputSchema": {
          "type": "object",
          "properties": {
            "path": {"type": "string"},
          },
          "required": ["path"],
        },
      },
      {
        "name": "read_file",
        "description": "Read the beginning of a text file as UTF-8.",
        "inputSchema": {
          "type": "object",
          "properties": {
            "path": {"type": "string"},
            "max_bytes": {"type": "integer"},
          },
          "required": ["path"],
        },
      },
    ]
  }
  send(make_result(id_, tools_result))


def handle_tools_call(req: Dict[str, Any]) -> None:
  id_ = req.get("id")
  params = req.get("params") or {}
  name = params.get("name")
  arguments = params.get("arguments") or {}

  try:
    if name == "list_directory":
      path = arguments.get("path")
      if not isinstance(path, str):
        raise ValueError("list_directory: 'path' must be a string")
      text = tool_list_directory(path)
    elif name == "read_file":
      path = arguments.get("path")
      if not isinstance(path, str):
        raise ValueError("read_file: 'path' must be a string")
      max_bytes = arguments.get("max_bytes")
      if max_bytes is not None and not isinstance(max_bytes, int):
        raise ValueError("read_file: 'max_bytes' must be an integer if provided")
      text = tool_read_file(path, max_bytes)
    else:
      send(
        make_error(
          id_,
          code=-32601,
          message=f"Unknown tool: {name}",
        )
      )
      return

    # MCP 工具返回格式：result.content 是一个 content 数组
    result = {
      "content": [
        {
          "type": "text",
          "text": text,
        }
      ]
    }
    send(make_result(id_, result))

  except PermissionError as e:
    send(
      make_error(
        id_,
        code=-32001,
        message="Permission denied",
        data={"detail": str(e)},
      )
    )
  except FileNotFoundError as e:
    send(
      make_error(
        id_,
        code=-32002,
        message="File or directory not found",
        data={"detail": str(e)},
      )
    )
  except (NotADirectoryError, IsADirectoryError) as e:
    send(
      make_error(
        id_,
        code=-32003,
        message="Invalid path type",
        data={"detail": str(e)},
      )
    )
  except Exception as e:
    # 返回堆栈方便调试
    send(
      make_error(
        id_,
        code=-32099,
        message=str(e),
        data={"traceback": traceback.format_exc()},
      )
    )


def main() -> None:
  """
  简单的行分隔 JSON‑RPC 循环：
  - 每行一个 JSON 对象；
  - MCP 客户端（例如 Cursor）通常按这一方式发送消息。
  """
  for line in sys.stdin:
    line = line.strip()
    if not line:
      continue

    try:
      req = json.loads(line)
    except json.JSONDecodeError as e:
      # 无法解析的行，直接忽略或记录错误
      send(
        make_error(
          None,
          code=-32700,
          message=f"Parse error: {e}",
        )
      )
      continue

    if not isinstance(req, dict):
      continue

    method = req.get("method")

    # notifications/initialized 之类的通知可以忽略
    if method == "initialize":
      handle_initialize(req)
    elif method == "tools/list":
      handle_tools_list(req)
    elif method == "tools/call":
      handle_tools_call(req)
    else:
      # 其它方法目前不支持
      if "id" in req:
        send(
          make_error(
            req.get("id"),
            code=-32601,
            message=f"Unknown method: {method}",
          )
        )
      # 通知类（无 id）就静默忽略


if __name__ == "__main__":
  main()

