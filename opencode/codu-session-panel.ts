// codu-session-panel: sidebar with plan + tasks + session health,
// commands in palette, and context/git toasts.

import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"
// @ts-ignore — opentui is bundled inside opencode's runtime
import { jsx as _jsx, jsxs as _jsxs } from "@opentui/solid/jsx-runtime"
// @ts-ignore
import { createSignal, createEffect, onCleanup, Show } from "solid-js"
import { execSync } from "node:child_process"
import { readFileSync, existsSync, readdirSync } from "node:fs"
import { join } from "node:path"

const id = "codu.session-panel"
const BRAIN = process.env.FLOWEN_BRAIN || join(process.env.HOME || "", "Flowen/twin-andie")
const STATE_FILE = join(process.env.HOME || "", ".flowen/state.toml")
const PLANS_DIR = join(BRAIN, "experiences/plans")

// --- Data helpers ---

function readAve(): string {
  try {
    const m = readFileSync(STATE_FILE, "utf-8").match(/active_ave\s*=\s*"([^"]+)"/)
    return m ? m[1].toUpperCase() : ""
  } catch { return "" }
}

function readPlanSlug(): string {
  try {
    return execSync('tmux show-options -v "@codu-plan" 2>/dev/null', { encoding: "utf-8", timeout: 2000 }).trim()
  } catch { return "" }
}

function findPlanFile(slug: string): string | null {
  const candidates = [join(PLANS_DIR, `${slug}-plan.md`)]
  try {
    for (const d of readdirSync(PLANS_DIR, { withFileTypes: true })) {
      if (d.isDirectory()) candidates.push(join(PLANS_DIR, d.name, `${slug}-plan.md`))
    }
  } catch {}
  for (const f of candidates) if (existsSync(f)) return f
  return null
}

function parsePlan(slug: string) {
  const file = findPlanFile(slug)
  if (!file) return null
  try {
    const content = readFileSync(file, "utf-8")
    const lines = content.split("\n")
    const titleLine = lines.find((l: string) => l.startsWith("# "))
    const title = titleLine ? titleLine.replace(/^#+ */, "").replace(/^Plan: */, "") : slug
    const done = (content.match(/- \[x\]/gi) || []).length
    const open = (content.match(/- \[ \]/g) || []).length
    const total = done + open
    const pct = total > 0 ? Math.round((done / total) * 100) : 0
    const tasks: string[] = []
    for (const line of lines) {
      if (/^\s*- \[ \]/.test(line) && tasks.length < 8) {
        tasks.push(line.replace(/^\s*- \[ \]\s*/, "").replace(/\*\*/g, "").replace(/`/g, "").substring(0, 45))
      }
    }
    return { title, done, total, pct, tasks }
  } catch { return null }
}

function gitInfo() {
  try {
    const branch = execSync("git branch --show-current 2>/dev/null", { encoding: "utf-8", timeout: 2000 }).trim()
    const dirty = parseInt(execSync("git status --porcelain 2>/dev/null | wc -l", { encoding: "utf-8", timeout: 2000 }).trim()) || 0
    const unpushed = parseInt(execSync("git log --oneline @{upstream}..HEAD 2>/dev/null | wc -l", { encoding: "utf-8", timeout: 2000 }).trim()) || 0
    return { branch: branch.replace(/^feat\//, "").substring(0, 20), dirty, unpushed }
  } catch { return { branch: "", dirty: 0, unpushed: 0 } }
}

// --- Sidebar component ---

function CoduPanel(props: { theme: any; api: any; sessionId: string }) {
  const t = props.theme
  const [data, setData] = createSignal({
    ave: "", plan: null as any, git: { branch: "", dirty: 0, unpushed: 0 }
  })
  const [open, setOpen] = createSignal(true)

  function refresh() {
    const ave = readAve()
    const slug = readPlanSlug()
    const plan = slug ? parsePlan(slug) : null
    const git = gitInfo()
    setData({ ave, plan, git })
  }

  // Refresh on mount + every 30s
  refresh()
  const timer = setInterval(refresh, 30000)
  onCleanup(() => clearInterval(timer))

  const barWidth = 16
  function progressBar(pct: number) {
    const filled = Math.round((pct / 100) * barWidth)
    return "█".repeat(filled) + "░".repeat(barWidth - filled)
  }

  return _jsxs("box", { children: [
    // Header
    _jsxs("text", {
      onMouseUp: () => setOpen((o: boolean) => !o),
      children: [
        _jsx("span", { style: { fg: t.textMuted }, children: open() ? "▼ " : "▶ " }),
        _jsx("span", { style: { fg: t.primary }, children: _jsx("b", { children: "Codu" }) }),
        // AVE badge
        _jsx(Show, { when: data().ave, children:
          _jsxs("span", { style: { fg: t.accent }, children: [" · ", data().ave] })
        }),
      ]
    }),

    _jsx(Show, { when: open(), children: _jsxs("box", { children: [
      // Plan section
      _jsx(Show, {
        when: data().plan,
        fallback: _jsx("text", { children:
          _jsx("span", { style: { fg: t.textMuted }, children: "  no plan selected" })
        }),
        children: _jsxs("box", { children: [
          // Plan title
          _jsx("text", { children:
            _jsx("span", { style: { fg: t.text }, children: "  " + (data().plan?.title || "").substring(0, 35) })
          }),
          // Progress bar
          _jsxs("text", { children: [
            _jsx("span", { style: { fg: t.success }, children: "  " + progressBar(data().plan?.pct || 0) }),
            _jsx("span", { style: { fg: t.text }, children: ` ${data().plan?.pct}%` }),
            _jsx("span", { style: { fg: t.textMuted }, children: ` (${data().plan?.done}/${data().plan?.total})` }),
          ]}),
          // Separator
          _jsx("text", { children:
            _jsx("span", { style: { fg: t.borderSubtle }, children: "  ─── tasks ───────────────" })
          }),
          // Task list
          ...(data().plan?.tasks || []).map((task: string) =>
            _jsx("text", { children:
              _jsxs("span", { children: [
                _jsx("span", { style: { fg: t.textMuted }, children: "  · " }),
                _jsx("span", { style: { fg: t.text }, children: task }),
              ]})
            })
          ),
          _jsx(Show, {
            when: (data().plan?.total || 0) - (data().plan?.done || 0) > 8,
            children: _jsx("text", { children:
              _jsx("span", { style: { fg: t.textMuted }, children: `  +${(data().plan?.total || 0) - (data().plan?.done || 0) - 8} more` })
            })
          }),
        ]}),
      }),

      // Git section
      _jsx(Show, { when: data().git.branch, children: _jsxs("box", { children: [
        _jsx("text", { children:
          _jsx("span", { style: { fg: t.borderSubtle }, children: "  ─── git ─────────────────" })
        }),
        _jsxs("text", { children: [
          _jsx("span", { style: { fg: t.textMuted }, children: "  " + data().git.branch }),
          _jsx(Show, { when: data().git.dirty > 0, children:
            _jsx("span", { style: { fg: t.error }, children: ` ●${data().git.dirty}` })
          }),
          _jsx(Show, { when: data().git.unpushed > 0, children:
            _jsx("span", { style: { fg: t.success }, children: ` ↑${data().git.unpushed}` })
          }),
        ]}),
      ]})})
    ]}) }),
  ]})
}

// --- Plugin entry ---

const tui: TuiPlugin = async (api) => {
  const { state, event, kv, ui } = api

  // Sidebar: plan + tasks + git
  api.slots.register({
    order: 50,
    slots: {
      sidebar_content(ctx: any, input: { session_id: string }) {
        return _jsx(CoduPanel, {
          theme: ctx.theme.current,
          api: api,
          sessionId: input.session_id,
        })
      },
    },
  })

  // Commands in palette
  api.command.register(() => [
    { title: "Plans", value: "/plans", description: "Show active plans", category: "Codu", slash: { name: "plans" } },
    { title: "Tasks", value: "/tasks", description: "Show open tasks", category: "Codu", slash: { name: "tasks" } },
    { title: "AVEs", value: "/aves", description: "Switch venture", category: "Codu", slash: { name: "aves" } },
    { title: "Wrap", value: "/wrap", description: "Commit + learn + handoff", category: "Codu", slash: { name: "wrap" } },
    { title: "Dispatch", value: "/dispatch", description: "Pick a task", category: "Codu", slash: { name: "dispatch" } },
    { title: "Capture", value: "/capture", description: "Save a note", category: "Codu", slash: { name: "capture" } },
    { title: "Learn", value: "/learn", description: "Extract patterns", category: "Codu", slash: { name: "learn" } },
  ])

  // Health toasts
  let lastGitCheck = 0
  event.on("session.idle", () => {
    const route = api.route.current
    if (route.name !== "session") return
    const sid = route.params.sessionID
    const msgs = state.session.messages(sid)

    if (msgs.length > 50 && !kv.get(`ctx-${sid}`)) {
      ui.toast({ variant: "warning", title: "Context getting large", message: "/wrap to commit + compact", duration: 8000 })
      kv.set(`ctx-${sid}`, true)
    }

    const now = Date.now()
    if (now - lastGitCheck < 300_000) return
    lastGitCheck = now
    const { dirty, unpushed } = gitInfo()
    if (dirty > 10 && !kv.get(`dirty-${sid}-${Math.floor(dirty/10)}`)) {
      ui.toast({ variant: "error", title: `${dirty} uncommitted files`, message: "/wrap to commit", duration: 10000 })
      kv.set(`dirty-${sid}-${Math.floor(dirty/10)}`, true)
    }
    if (unpushed > 0 && !kv.get(`unpush-${sid}`)) {
      ui.toast({ variant: "warning", title: `${unpushed} unpushed commits`, message: "push before killing session", duration: 8000 })
      kv.set(`unpush-${sid}`, true)
    }
  })
}

const plugin: TuiPluginModule & { id: string } = { id, tui }
export default plugin
