// codu-session-panel: adds /plans, /tasks, /aves, /dispatch, /wrap commands
// to the opencode command palette, and shows context health toasts.

import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"

const id = "codu.session-panel"

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

  // --- Context health toast ---
  event.on("session.idle", () => {
    const route = api.route.current
    if (route.name !== "session") return

    const sessionID = route.params.sessionID
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
  })
}

const plugin: TuiPluginModule & { id: string } = { id, tui }
export default plugin
