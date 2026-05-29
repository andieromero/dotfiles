// codu-session-panel: sidebar with plan + tasks + session health,
// commands in palette, and context/git toasts.
//
// IMPORTANT: This file MUST be .tsx (not .ts) for opencode's Bun runtime
// to route it through bun-plugin-solid, which transpiles JSX to
// @opentui/solid calls via the embedded virtual modules.

import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"
import { createSignal, onCleanup, Show, For } from "solid-js"
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

interface PlanData {
  title: string
  done: number
  total: number
  pct: number
  tasks: string[]
}

function parsePlan(slug: string): PlanData | null {
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

interface GitData {
  branch: string
  dirty: number
  unpushed: number
}

function gitInfo(): GitData {
  try {
    const branch = execSync("git branch --show-current 2>/dev/null", { encoding: "utf-8", timeout: 2000 }).trim()
    const dirty = parseInt(execSync("git status --porcelain 2>/dev/null | wc -l", { encoding: "utf-8", timeout: 2000 }).trim()) || 0
    const unpushed = parseInt(execSync("git log --oneline @{upstream}..HEAD 2>/dev/null | wc -l", { encoding: "utf-8", timeout: 2000 }).trim()) || 0
    return { branch: branch.replace(/^feat\//, "").substring(0, 20), dirty, unpushed }
  } catch { return { branch: "", dirty: 0, unpushed: 0 } }
}

// --- Session health helpers ---

interface SessionHealth {
  totalCost: number
  totalInput: number
  totalOutput: number
  msgCount: number
}

function computeHealth(api: any, sessionId: string): SessionHealth {
  const msgs = api.state.session.messages(sessionId) || []
  let totalCost = 0, totalInput = 0, totalOutput = 0, msgCount = msgs.length
  for (const msg of msgs) {
    if (msg.role === "assistant") {
      totalCost += msg.cost || 0
      totalInput += msg.tokens?.input || 0
      totalOutput += msg.tokens?.output || 0
    }
  }
  return { totalCost, totalInput, totalOutput, msgCount }
}

function formatTokens(n: number): string {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + "M"
  if (n >= 1_000) return Math.round(n / 1_000) + "K"
  return String(n)
}

function formatCost(n: number): string {
  if (n < 0.01) return "$0"
  if (n < 1) return "$" + n.toFixed(2)
  return "$" + n.toFixed(1)
}

// Context health: green < 100K input, yellow 100-200K, red > 200K
function contextColor(inputTokens: number, theme: any): any {
  if (inputTokens > 200_000) return theme.error
  if (inputTokens > 100_000) return theme.warning
  return theme.success
}

function contextDot(inputTokens: number): string {
  if (inputTokens > 200_000) return "●"
  if (inputTokens > 100_000) return "●"
  return "●"
}

// --- Plan inference for old sessions ---

function inferPlanFromSessionName(sessionName: string): string | null {
  try {
    // Extract search terms from session name (split on dashes, filter noise)
    const terms = sessionName
      .toLowerCase()
      .split(/[-_]/)
      .filter(t => t.length > 2 && !["codu", "builder", "session"].includes(t))
    
    if (terms.length === 0) return null

    // Search for plans matching ANY of the terms
    const allPlans: string[] = []
    
    // Flat plans
    try {
      const files = readdirSync(PLANS_DIR, { withFileTypes: true })
      for (const f of files) {
        if (f.isFile() && f.name.endsWith("-plan.md")) {
          allPlans.push(f.name.replace(/-plan\.md$/, ""))
        }
      }
    } catch {}
    
    // Subdirectory plans
    try {
      const dirs = readdirSync(PLANS_DIR, { withFileTypes: true })
      for (const d of dirs) {
        if (!d.isDirectory()) continue
        const subpath = join(PLANS_DIR, d.name)
        const subfiles = readdirSync(subpath, { withFileTypes: true })
        for (const f of subfiles) {
          if (f.isFile() && f.name.endsWith("-plan.md")) {
            allPlans.push(`${d.name}/${f.name.replace(/-plan\.md$/, "")}`)
          }
        }
      }
    } catch {}

    // Score each plan by term matches
    const scored = allPlans.map(slug => {
      const slugLower = slug.toLowerCase()
      const matches = terms.filter(t => slugLower.includes(t)).length
      return { slug, matches }
    })
    
    // Return the best match if score > 0
    scored.sort((a, b) => b.matches - a.matches)
    return scored[0]?.matches > 0 ? scored[0].slug : null
  } catch {
    return null
  }
}

function getSessionName(): string {
  try {
    return execSync('tmux display-message -p "#{session_name}"', { encoding: "utf-8", timeout: 1000 }).trim()
  } catch {
    return ""
  }
}

// --- Sidebar component ---

function CoduPanel(props: { theme: any; api: any; sessionId: string }) {
  const t = props.theme
  const [data, setData] = createSignal<{
    ave: string
    plan: PlanData | null
    git: GitData
  }>({
    ave: "", plan: null, git: { branch: "", dirty: 0, unpushed: 0 }
  })
  const [open, setOpen] = createSignal(true)

  function refresh() {
    const ave = readAve()
    const slug = readPlanSlug()
    const plan = slug ? parsePlan(slug) : null
    const git = gitInfo()
    setData({ ave, plan, git })
  }

  refresh()
  const timer = setInterval(refresh, 30000)
  onCleanup(() => clearInterval(timer))

  const barWidth = 16
  function progressBar(pct: number) {
    const filled = Math.round((pct / 100) * barWidth)
    return "█".repeat(filled) + "░".repeat(barWidth - filled)
  }

  return (
    <box>
      {/* Header — click to collapse */}
      <text onMouseUp={() => setOpen((o: boolean) => !o)}>
        <span style={{ fg: t.textMuted }}>{open() ? "▼ " : "▶ "}</span>
        <span style={{ fg: t.primary }}>Codu</span>
        <Show when={data().ave}>
          <span style={{ fg: t.accent }}>{" · " + data().ave}</span>
        </Show>
      </text>

      <Show when={open()}>
        <box>
          {/* Plan section */}
          <Show
            when={data().plan}
            fallback={
              <text><span style={{ fg: t.textMuted }}>  no plan selected</span></text>
            }
          >
            <box>
              <text>
                <span style={{ fg: t.text }}>{"  " + (data().plan?.title || "").substring(0, 35)}</span>
              </text>
              <text>
                <span style={{ fg: t.success }}>{"  " + progressBar(data().plan?.pct || 0)}</span>
                <span style={{ fg: t.text }}>{` ${data().plan?.pct}%`}</span>
                <span style={{ fg: t.textMuted }}>{` (${data().plan?.done}/${data().plan?.total})`}</span>
              </text>
              <text>
                <span style={{ fg: t.borderSubtle }}>{"  ─── tasks ───────────────"}</span>
              </text>
              <For each={data().plan?.tasks || []}>
                {(task: string) => (
                  <text>
                    <span style={{ fg: t.textMuted }}>{"  · "}</span>
                    <span style={{ fg: t.text }}>{task}</span>
                  </text>
                )}
              </For>
              <Show when={(data().plan?.total || 0) - (data().plan?.done || 0) > 8}>
                <text>
                  <span style={{ fg: t.textMuted }}>{`  +${(data().plan?.total || 0) - (data().plan?.done || 0) - 8} more`}</span>
                </text>
              </Show>
            </box>
          </Show>

          {/* Git section */}
          <Show when={data().git.branch}>
            <box>
              <text>
                <span style={{ fg: t.borderSubtle }}>{"  ─── git ─────────────────"}</span>
              </text>
              <text>
                <span style={{ fg: t.textMuted }}>{"  " + data().git.branch}</span>
                <Show when={data().git.dirty > 0}>
                  <span style={{ fg: t.error }}>{` ●${data().git.dirty}`}</span>
                </Show>
                <Show when={data().git.unpushed > 0}>
                  <span style={{ fg: t.success }}>{` ↑${data().git.unpushed}`}</span>
                </Show>
              </text>
            </box>
          </Show>
        </box>
      </Show>
    </box>
  )
}

// --- Sidebar footer: session health ---

function CoduFooter(props: { theme: any; api: any; sessionId: string }) {
  const t = props.theme
  const [health, setHealth] = createSignal<SessionHealth>({
    totalCost: 0, totalInput: 0, totalOutput: 0, msgCount: 0
  })
  const [git, setGit] = createSignal<GitData>({ branch: "", dirty: 0, unpushed: 0 })
  const [ave, setAve] = createSignal("")

  function refresh() {
    setHealth(computeHealth(props.api, props.sessionId))
    setGit(gitInfo())
    setAve(readAve())
  }

  refresh()
  const timer = setInterval(refresh, 15000)
  onCleanup(() => clearInterval(timer))

  // Also refresh on message updates for real-time cost tracking
  props.api.event.on("message.updated", (e: any) => {
    if (e.properties?.sessionID === props.sessionId) {
      setHealth(computeHealth(props.api, props.sessionId))
    }
  })

  return (
    <text>
      <Show when={ave()}>
        <span style={{ fg: t.accent }}>{ave()}</span>
        <span style={{ fg: t.textMuted }}>{" · "}</span>
      </Show>
      <Show when={git().branch}>
        <span style={{ fg: t.textMuted }}>{git().branch}</span>
        <Show when={git().dirty > 0}>
          <span style={{ fg: t.error }}>{` ●${git().dirty}`}</span>
        </Show>
        <Show when={git().unpushed > 0}>
          <span style={{ fg: t.success }}>{` ↑${git().unpushed}`}</span>
        </Show>
        <span style={{ fg: t.textMuted }}>{" · "}</span>
      </Show>
      <span style={{ fg: contextColor(health().totalInput, t) }}>
        {formatTokens(health().totalInput)}
      </span>
      <span style={{ fg: t.textMuted }}>{" · "}</span>
      <span style={{ fg: t.text }}>{formatCost(health().totalCost)}</span>
    </text>
  )
}

// --- Prompt bar right: context health dot ---

function ContextBadge(props: { theme: any; api: any; sessionId: string }) {
  const t = props.theme
  const [health, setHealth] = createSignal<SessionHealth>({
    totalCost: 0, totalInput: 0, totalOutput: 0, msgCount: 0
  })

  function refresh() {
    setHealth(computeHealth(props.api, props.sessionId))
  }

  refresh()
  props.api.event.on("message.updated", (e: any) => {
    if (e.properties?.sessionID === props.sessionId) {
      setHealth(computeHealth(props.api, props.sessionId))
    }
  })

  return (
    <text>
      <span style={{ fg: contextColor(health().totalInput, t) }}>
        {contextDot(health().totalInput)}
      </span>
      <span style={{ fg: t.textMuted }}>
        {" " + formatTokens(health().totalInput)}
      </span>
      <span style={{ fg: t.textMuted }}>
        {" " + formatCost(health().totalCost)}
      </span>
    </text>
  )
}

// --- Home screen: plan status + prompt ---

function CoduHome(props: { theme: any; api: any }) {
  const t = props.theme
  const [state, setState] = createSignal<{
    planSlug: string | null
    inferredSlug: string | null
    plan: PlanData | null
    sessionName: string
  }>({
    planSlug: null,
    inferredSlug: null,
    plan: null,
    sessionName: ""
  })

  function refresh() {
    const sessionName = getSessionName()
    const planSlug = readPlanSlug() || null
    let inferredSlug: string | null = null
    let plan: PlanData | null = null

    if (planSlug) {
      // Plan explicitly set
      plan = parsePlan(planSlug)
    } else {
      // Try to infer from session name
      inferredSlug = inferPlanFromSessionName(sessionName)
      if (inferredSlug) {
        plan = parsePlan(inferredSlug)
      }
    }

    setState({ planSlug, inferredSlug, plan, sessionName })
  }

  refresh()
  const timer = setInterval(refresh, 30000)
  onCleanup(() => clearInterval(timer))

  const hasExplicitPlan = () => state().planSlug !== null
  const hasInferredPlan = () => state().inferredSlug !== null && state().plan !== null
  const hasNoPlan = () => !hasExplicitPlan() && !hasInferredPlan()

  return (
    <box>
      {/* Explicit plan set */}
      <Show when={hasExplicitPlan() && state().plan}>
        <text>
          <span style={{ fg: t.primary }}>Working on: </span>
          <span style={{ fg: t.text }}>{state().plan?.title || state().planSlug}</span>
        </text>
        <Show when={state().plan && state().plan.tasks.length > 0}>
          <text>
            <span style={{ fg: t.textMuted }}>Next: </span>
            <span style={{ fg: t.text }}>{state().plan!.tasks[0]}</span>
          </text>
        </Show>
        <text>
          <span style={{ fg: t.success }}>→ Type </span>
          <span style={{ fg: t.accent }}>/dispatch</span>
          <span style={{ fg: t.success }}> to continue</span>
        </text>
      </Show>

      {/* Inferred plan (session created before @codu-plan was added) */}
      <Show when={hasInferredPlan()}>
        <text>
          <span style={{ fg: t.warning }}>Plan not set for this session</span>
        </text>
        <text>
          <span style={{ fg: t.textMuted }}>Found matching plan: </span>
          <span style={{ fg: t.text }}>{state().plan?.title || state().inferredSlug}</span>
        </text>
        <text>
          <span style={{ fg: t.textMuted }}>To use it, run: </span>
          <span style={{ fg: t.accent }}>tmux set-option "@codu-plan" "{state().inferredSlug}"</span>
        </text>
        <text>
          <span style={{ fg: t.textMuted }}>Or type </span>
          <span style={{ fg: t.accent }}>/plans</span>
          <span style={{ fg: t.textMuted }}> to pick a different plan</span>
        </text>
      </Show>

      {/* No plan (blank session or no match found) */}
      <Show when={hasNoPlan()}>
        <text>
          <span style={{ fg: t.textMuted }}>No plan set for this session</span>
        </text>
        <text>
          <span style={{ fg: t.success }}>→ Type </span>
          <span style={{ fg: t.accent }}>/plans</span>
          <span style={{ fg: t.success }}> to pick a plan, or continue without one</span>
        </text>
      </Show>
    </box>
  )
}

// --- Plugin entry ---

const tui: TuiPlugin = async (api) => {
  const { state, event, kv, ui } = api

  // Sidebar content: plan + tasks + git
  // Sidebar footer: AVE · branch · tokens · cost
  // Prompt right: context health dot + tokens + cost
  // Home bottom: plan status + nudge to /plans or /dispatch
  api.slots.register({
    order: 50,
    slots: {
      sidebar_content(ctx: any, input: { session_id: string }) {
        return <CoduPanel theme={ctx.theme.current} api={api} sessionId={input.session_id} />
      },
      sidebar_footer(ctx: any, input: { session_id: string }) {
        return <CoduFooter theme={ctx.theme.current} api={api} sessionId={input.session_id} />
      },
      session_prompt_right(ctx: any, input: { session_id: string }) {
        return <ContextBadge theme={ctx.theme.current} api={api} sessionId={input.session_id} />
      },
      home_bottom(ctx: any) {
        return <CoduHome theme={ctx.theme.current} api={api} />
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

  // Health toasts on session idle
  let lastGitCheck = 0
  event.on("session.idle", () => {
    const route = api.route.current
    if (route.name !== "session") return
    const sid = route.params.sessionID
    const health = computeHealth(api, sid)

    // Token-based context warnings: yellow at 150K, red at 200K
    if (health.totalInput > 200_000 && !kv.get(`ctx-red-${sid}`)) {
      ui.toast({ variant: "error", title: "Context critical (>200K)", message: "/wrap now — context overflow imminent", duration: 12000 })
      kv.set(`ctx-red-${sid}`, true)
    } else if (health.totalInput > 150_000 && !kv.get(`ctx-yellow-${sid}`)) {
      ui.toast({ variant: "warning", title: "Context getting large (>150K)", message: "/wrap to commit + compact", duration: 8000 })
      kv.set(`ctx-yellow-${sid}`, true)
    }

    const now = Date.now()
    if (now - lastGitCheck < 300_000) return
    lastGitCheck = now
    const { dirty, unpushed } = gitInfo()
    if (dirty > 10 && !kv.get(`dirty-${sid}-${Math.floor(dirty / 10)}`)) {
      ui.toast({ variant: "error", title: `${dirty} uncommitted files`, message: "/wrap to commit", duration: 10000 })
      kv.set(`dirty-${sid}-${Math.floor(dirty / 10)}`, true)
    }
    if (unpushed > 0 && !kv.get(`unpush-${sid}`)) {
      ui.toast({ variant: "warning", title: `${unpushed} unpushed commits`, message: "push before killing session", duration: 8000 })
      kv.set(`unpush-${sid}`, true)
    }
  })
}

const plugin: TuiPluginModule & { id: string } = { id, tui }
export default plugin
