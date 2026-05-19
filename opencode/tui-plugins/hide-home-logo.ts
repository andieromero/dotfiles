// Hides opencode's home-screen ASCII logo by registering an empty renderer
// against the `home_logo` slot (replace mode). The Home route renders the
// slot as `<Slot name="home_logo" mode="replace"><Logo /></Slot>` — a plugin
// contribution wins over the default child.
//
// Auto-discovered by opencode from ~/.config/opencode/plugin/*.ts.

import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"

const id = "flowen.hide-home-logo"

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    slots: {
      home_logo: () => null,
    },
  })
}

const plugin: TuiPluginModule & { id: string } = { id, tui }

export default plugin
