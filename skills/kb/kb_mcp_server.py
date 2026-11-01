#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["fastmcp>=2.0"]
# ///
"""kb_mcp_server.py —— webrtc_primer 教程知识库的 MCP 柜台.

读 source/（Sphinx + reStructuredText 教程正文），写 draft/（Markdown 草稿）。
路径由脚本位置自动推导，uv run 即起，无需配置：

    uv run tutorial/skills/kb/kb_mcp_server.py

四个工具：kb_catalog / kb_search / kb_read / kb_write。
护栏：路径白名单、后缀限制、大小上限、原子写入、审计流水、不提供删除。
"""

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

from fastmcp import FastMCP

TUTORIAL_DIR = Path(__file__).resolve().parents[2]
SOURCE_ROOT = Path(os.environ.get("KB_SOURCE", TUTORIAL_DIR / "source")).resolve()
DRAFT_ROOT = Path(os.environ.get("KB_DRAFT", TUTORIAL_DIR / "draft")).resolve()
AUDIT_LOG = Path(os.environ.get("KB_AUDIT", TUTORIAL_DIR / "build" / ".kb_audit.jsonl")).resolve()

READ_SUFFIXES = (".rst", ".md", ".ref")
MAX_WRITE_BYTES = 200_000
ADORNMENT = set("=#-~^\"'*+_:;!?<>")

mcp = FastMCP("webrtc-kb")


def read_root_for(rel: str) -> Path:
    """读路径允许落在 source/ 或 draft/，出界拒绝。"""
    for root in (SOURCE_ROOT, DRAFT_ROOT):
        p = (root / rel).resolve()
        if p.is_relative_to(root):
            if p.suffix not in READ_SUFFIXES:
                raise ValueError(f"only {READ_SUFFIXES} readable, got: {rel}")
            return p
    raise ValueError(f"path escapes knowledge base: {rel}")


def safe_draft_path(rel: str) -> Path:
    """写路径只允许落在 draft/ 下，且只能是 .md。"""
    p = (DRAFT_ROOT / rel).resolve()
    if not p.is_relative_to(DRAFT_ROOT):
        raise ValueError(f"write only allowed inside draft/: {rel}")
    if p.suffix != ".md":
        raise ValueError(f"write only .md drafts, got: {rel}")
    return p


def rst_title(text: str) -> str:
    """取 RST 标题：跳过纯符号装饰行，取第一行正文。"""
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        if set(s) <= ADORNMENT and len(s) >= 3:
            continue
        return s
    return ""


def md_title(text: str) -> str:
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("# "):
            return s[2:].strip()
    return ""


def iter_docs():
    """遍历 source/ 的 .rst 和 draft/ 的 .md，产出 (root, path)。"""
    for p in sorted(SOURCE_ROOT.rglob("*.rst")):
        yield SOURCE_ROOT, p
    for p in sorted(DRAFT_ROOT.rglob("*.md")):
        if p.name.startswith("."):
            continue
        yield DRAFT_ROOT, p


def audit(action: str, path: str, extra: dict | None = None) -> None:
    AUDIT_LOG.parent.mkdir(parents=True, exist_ok=True)
    entry = {"ts": datetime.now(timezone.utc).isoformat(), "action": action,
             "path": path, **(extra or {})}
    with open(AUDIT_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


@mcp.tool
def kb_catalog() -> str:
    """列出教程知识库全部文档：source/ 各章节的 .rst + draft/ 的 .md 草稿。
    先看这个，再决定读哪篇。"""
    items = []
    for root, p in iter_docs():
        rel = str(p.relative_to(root))
        if any(part.startswith(("_", ".")) for part in p.relative_to(root).parts):
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        title = md_title(text) if p.suffix == ".md" else rst_title(text)
        items.append({"area": "draft" if root == DRAFT_ROOT else "source",
                      "path": rel, "title": title})
    return json.dumps(items, ensure_ascii=False, indent=1)


@mcp.tool
def kb_search(query: str, limit: int = 10) -> str:
    """按正则搜索教程正文和草稿，返回 "文件:行号: 摘要"。
    教程是 reStructuredText，搜 ICE、SDP、RTP 等关键词很好用。"""
    limit = max(1, min(limit, 50))
    rx = re.compile(query, re.IGNORECASE)
    hits = []
    for root, p in iter_docs():
        rel = str(p.relative_to(root))
        if any(part.startswith(("_", ".")) for part in p.relative_to(root).parts):
            continue
        for n, line in enumerate(
                p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if rx.search(line):
                area = "draft" if root == DRAFT_ROOT else "source"
                hits.append(f"[{area}] {rel}:{n}: {line.strip()[:120]}")
                if len(hits) >= limit:
                    return "\n".join(hits)
    return "\n".join(hits) if hits else "no hits"


@mcp.tool
def kb_read(path: str) -> str:
    """读一篇文档的完整原文。source/ 用章节相对路径（如 4.media/rtp.rst），
    draft/ 直接用文件名。"""
    return read_root_for(path).read_text(encoding="utf-8", errors="replace")


@mcp.tool
def kb_write(path: str, content: str, reason: str) -> str:
    """往 draft/ 新增或更新一篇 Markdown 草稿。
    正文以 '# 标题' 开头；source/ 里的正式教程不归 agent 改，
    从草稿到 rst 的晋升由人来完成。不提供删除。"""
    p = safe_draft_path(path)
    if len(content.encode("utf-8")) > MAX_WRITE_BYTES:
        return f"rejected: content over {MAX_WRITE_BYTES} bytes"
    if not content.lstrip().startswith("# "):
        return "rejected: draft must start with a '# ' title heading"
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_name(p.name + ".tmp")
    tmp.write_text(content, encoding="utf-8")
    os.replace(tmp, p)
    audit("write", str(p.relative_to(DRAFT_ROOT)), {"reason": reason, "bytes": len(content)})
    return f"ok: draft/{p.relative_to(DRAFT_ROOT)} ({len(content)} chars, reason recorded)"


if __name__ == "__main__":
    mcp.run()
