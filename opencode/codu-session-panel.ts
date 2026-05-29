// codu-session-panel: adds /plans, /tasks, /aves, /dispatch, /wrap commands
// to the opencode command palette, and shows context health toasts.

import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"
import { execSync } from "node:child_process"

const id = "codu.session-panel"

function gitDirtyCount(): number {
  try {
    const out = execSync("git status --porcelain 2>/dev/null | wc -l", {
      encoding: "utf-8",
      timeout: 3000,
    })
    return parseInt(out.trim()) || 0
  } catch {
    return 0
  }
}

function gitUnpushedCount(): number {
  try {
    const out = execSync("git log --oneline @{upstream}..HEAD 2>/dev/null | wc -l", {
      encoding: "utf-8",
      timeout: 3000,
    })
    return parseInt(out.trim()) || 0
  } catch {
    return 0
  }
}

const tui: TuiPlugin = async (api) => {
  const { state, event, kv, ui } = api

  // --- Commands in the palette (ctrl+p) ---
  api.command.register(() => [
    {
      title: "Plans",
      value: "/plans",
      description: "Show active plans with progress",
      category: "Codu",
      slash: { name: "plans" },
    },
    {
      title: "Tasks",
      value: "/tasks",
      description: "Show open tasks across plans",
      category: "Codu",
      slash: { name: "tasks" },
    },
    {
      title: "AVEs",
      value: "/aves",
      description: "List ventures, switch active AVE",
      category: "Codu",
      slash: { name: "aves" },
    },
    {
      title: "Wrap",
      value: "/wrap",
      description: "Commit + push + learn + handoff + compact",
      category: "Codu",
      slash: { name: "wrap" },
    },
    {
      title: "Dispatch",
      value: "/dispatch",
      description: "Pick a plan task and start working",
      category: "Codu",
      slash: { name: "dispatch" },
    },
    {
      title: "Capture",
      value: "/capture",
      description: "Save a note to the brain",
      category: "Codu",
      slash: { name: "capture" },
    },
    {
      title: "Learn",
      value: "/learn",
      description: "Extract patterns from completed work",
      category: "Codu",
      slash: { name: "learn" },
    },
  ])

  // --- Health checks on session idle ---
  let lastGitCheck = 0

  event.on("session.idle", () => {
    const route = api.route.current
    if (route.name !== "session") return
    const sessionID = route.params.sessionID

    // Context health
    const messages = state.session.messages(sessionID)
    if (messages.length > 50) {
      const key = `ctx-warn-${sessionID}`
      if (!kv.get(key)) {
        ui.toast({
          variant: "warning",
          title: "Context getting large",
          message: "Type /wrap to commit + compact, or start fresh",
          duration: 8000,
        })
        kv.set(key, true)
      }
    }

    // Git dirty check — every 5 minutes max
    const now = Date.now()
    if (now - lastGitCheck < 300_000) return
    lastGitCheck = now

    const dirty = gitDirtyCount()
    const unpushed = gitUnpushedCount()

    if (dirty > 10) {
      const key = `git-dirty-warn-${sessionID}-${Math.floor(dirty / 10)}`
      if (!kv.get(key)) {
        ui.toast({
          variant: "error",
          title: `${dirty} uncommitted files`,
          message: "Commit your work before it's lost. /wrap handles this.",
          duration: 10000,
        })
        kv.set(key, true)
      }
    } else if (dirty > 0) {
      const key = `git-dirty-info-${sessionID}`
      if (!kv.get(key)) {
        ui.toast({
          variant: "info",
          title: `${dirty} uncommitted changes`,
          message: "Remember to commit before ending the session",
          duration: 6000,
        })
        kv.set(key, true)
      }
    }

    if (unpushed > 0) {
      const key = `git-unpushed-${sessionID}`
      if (!kv.get(key)) {
        ui.toast({
          variant: "warning",
          title: `${unpushed} unpushed commits`,
          message: "Push to remote before killing this session",
          duration: 8000,
        })
        kv.set(key, true)
      }
    }
  })
}

const plugin: TuiPluginModule & { id: string } = { id, tui }
export default plugin
