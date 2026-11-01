---
name: webrtc-primer-kb
description: Search, read, and write the webrtc_primer tutorial knowledge base through a local FastMCP server (uv run, stdio). Use when the user asks to 查教程 / 搜知识库 / 找 WebRTC 概念出处 / 读某篇教程 / 记 draft 草稿 / 补充知识点, or mentions webrtc primer tutorial, kb_catalog, kb_search, kb_read, kb_write.
---

# webrtc_primer 教程知识库柜台

把 `tutorial/source/`（Sphinx + reStructuredText 教程正文，254 篇）和
`tutorial/draft/`（Markdown 草稿）包成四个 MCP 工具，给 Codex、Cursor、
Claude Code 等agent 一个受控的读写口：**读 source，写 draft，引用带路径，不删东西。**

## 启动

服务器路径自动推导，零配置，uv 直接跑（PEP 723 内联依赖）：

```console
$ uv run tutorial/skills/kb/kb_mcp_server.py
```

stdio 传输，供 MCP client 拉起；一般不手动运行。

## 接到各家 agent

**Codex**（`~/.codex/config.toml`）：

```toml
[mcp_servers.webrtc-kb]
command = "uv"
args = ["run", "/Users/walterfan/workspace/walter/webrtc_primer/tutorial/skills/kb/kb_mcp_server.py"]
```

**Cursor**（`~/.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "webrtc-kb": {
      "command": "uv",
      "args": ["run", "/Users/walterfan/workspace/walter/webrtc_primer/tutorial/skills/kb/kb_mcp_server.py"]
    }
  }
}
```

**Claude Code**：

```console
$ claude mcp add webrtc-kb -- uv run /Users/walterfan/workspace/walter/webrtc_primer/tutorial/skills/kb/kb_mcp_server.py
```

## 工具契约

| 工具 | 输入 | 输出 | 边界 |
|---|---|---|---|
| `kb_catalog` | 无 | source 各章节 .rst 标题 + draft 草稿清单 | 只读 |
| `kb_search` | 正则、条数上限 | `[source|draft] 文件:行号: 摘要` | 只读，上限 50 条 |
| `kb_read` | 相对路径 | 整篇原文 | source/ 或 draft/ 白名单，.rst/.md/.ref |
| `kb_write` | 文件名、内容、事由 | ok 或明确的拒绝理由 | 只写 draft/ 的 .md，须以 `# 标题` 开头 |

规则：

1. 回答教程相关问题，先 `kb_catalog` 再 `kb_search`/`kb_read`，**引用结论必须给出文件路径**。
2. 新知识、笔记、补充材料写进 `draft/`（`kb_write`，带 reason）；**source/ 的正式教程不通过本工具修改**，草稿晋升为 rst 由人完成。
3. 删除不走本柜台，提给人类，走 git。
4. 每笔写入落在 `tutorial/build/.kb_audit.jsonl`（时间、路径、事由、字节数）。
5. 写入护栏是防呆不防贼；agent 仍应优先走柜台，别用通用文件工具直改 draft。

## 验收（golden questions）

- 问 "ICE candidate 有哪几种类型"，应命中 `2.transport/` 或 `3.signaling/` 下的原文并给路径。
- 问 "教程里哪里讲了 BWE"，`kb_search` 应返回具体文件和行号。
- `kb_write` 一篇 `# 测试` 开头的草稿，应成功且审计流水落盘；不带 `#` 开头应被拒绝。

## 边界

- source/ 正文是 reStructuredText，标题靠装饰行，写入侧不做 rst 生成（交给人和 Sphinx）。
- 搜索是正则扫描，个人教程规模足够；不需要向量库。
- `tutorial/build/` 是构建产物目录，审计日志放那里，不进版本库。
