# Research: AGY MCP Vision Loop Viability

**Date:** July 23, 2026 · **Subject:** Có chạy được loop "generate → nhìn → refine" bằng agy (Antigravity CLI) + MCP + vision cho tạo asset game không?

## Summary

Loop "generate → look → refine" dùng **agy + MCP** cho tạo asset game **KHÔNG khả thi hôm nay**. agy có discovery MCP nhưng **bug nghiêm trọng chặn việc invoke tool lúc runtime** (`tool <name> is not enabled for server`), nên agy không điều khiển được Blender/Godot qua MCP. Kết hợp với bug poison session khi route agy qua Pi (#2993/#3108) → agy phải chạy **standalone**, chỉ làm vai trò native (research/web/testing, không cần MCP).

## Findings (tất cả đã verify main-agent)

1. **agy có phải MCP client?** — Có config MCP (stdio/sse/http qua `.gemini/antigravity-cli/mcp_config.json`) NHƯNG **bị hỏng lúc invoke**. [#71](https://github.com/google-antigravity/antigravity-cli/issues/71) + [#39](https://github.com/google-antigravity/antigravity-cli/issues/39): discover+caching tool OK, nhưng `call_mcp_tool` luôn trả `tool <name> is not enabled for server`. **Quan trọng:** #71 tự ghi *"works correctly in Gemini CLI(v0.42.0) and OpenAI Codex(v0.130.0) with the same server and config"* → Gemini CLI & Codex là MCP client chạy được.

2. **agy có vision/multimodal?** — Model nền (Gemini) support image. Drag-and-drop ảnh OK; paste clipboard (Ctrl+V) KHÔNG hoạt động trong TUI. [#343](https://github.com/google-antigravity/antigravity-cli/issues/343).

3. **MCP server nào chạy được với agy?** — `hi-godot/godot-ai` README liệt kê Antigravity là client được hỗ trợ, NHƯNG vì agy không invoke được (#71/#39) nên thực tế không dùng được. `ahujasid/blender-mcp` target Claude/Cursor. `vinh-le/aseprite-mcp` 404.

4. **Verdict loop:** Không khả thi với agy. Loop cần (a) invoke MCP tin cậy để "generate/refine" + (b) vision để "look". agy fail (a) hoàn toàn.

5. **Routing:** Chạy **standalone** (herdr/tmux pane). Đừng route qua Pi (cliproxy → poison session #2993/#3108).

## ADDENDUM — Verification (main agent, gh CLI trực tiếp)

**⚠️ Model:** `gemini-3.6-flash-high` KHÔNG tồn tại ("Model not found") → researcher tự fallback `cliproxy/gemini-3.1-pro-low:medium`. Cần user xác nhận lại tên model đúng.

**Verified — mọi claim load-bearing THẬT + đang OPEN (chưa fix):**

- **agy #71** — OPEN. "Custom MCP Server Tools Discovered but Not Invocable". `call_mcp_tool` → `tool <name> is not enabled for server`. Tự xác nhận Gemini CLI + Codex chạy được cùng server.
- **agy #39** — OPEN (closed=None). "MCP tools blocked at runtime (not enabled) despite explicit IAM". Deadlock trong MCP daemon.
- **agy #343** — OPEN. Clipboard paste ảnh TUI không hoạt động; drag-drop OK.
- **godot-ai README** — ĐÚNG: liệt kê Antigravity nhưng vô dụng với agy do #71/#39.

**Khoảng trống researcher bỏ sót:** #71 xác nhận **Gemini CLI & Codex chạy được cùng MCP server**. Vậy loop driver THỰC TẾ (MCP client + vision):

1. **Pi** — đang chạy, có tool `mcp` + subagent image-reader → không cần thêm quota nếu đã có model
2. **Gemini CLI** — confirm chạy MCP, khớp quota Gemini bạn đang có
3. **Claude Code** — recommend của blender-mcp/godot-ai; cần quota Claude
4. **Codex** — confirm chạy MCP
5. Đợi agy fix #71/#39

## Hệ quả kiến trúc

Quyết định "agy-centric vision loop" ở **§6 HARNESS file KHÔNG khả thi hôm nay** (agy MCP hỏng).

- **agy** → chỉ giữ vai trò native (research/web/mobile testing, không cần MCP), chạy standalone qua herdr. Đúng quyết định cô lập.
- **Loop tạo asset** → do 1 MCP-client khác lái: **Pi** (đã sẵn sàng) hoặc **Gemini CLI** (khớp quota). Claude Code nếu có quota.

## Sources

- agy: [#71](https://github.com/google-antigravity/antigravity-cli/issues/71), [#39](https://github.com/google-antigravity/antigravity-cli/issues/39), [#343](https://github.com/google-antigravity/antigravity-cli/issues/343)
- [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai) · [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- Pi poison session: [#2993](https://github.com/earendil-works/pi/issues/2993), [#3108](https://github.com/earendil-works/pi/issues/3108) (xem `FIND_TOOL_SPAM_LOOP_RESEARCH.md`)
