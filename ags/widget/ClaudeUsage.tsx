import { Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { shell } from "../lib/utils"

type ClaudeUsage = {
  available: boolean
  tokens: number
  costUsd: number
}

const usage = createPoll<ClaudeUsage>(
  { available: false, tokens: 0, costUsd: 0 },
  60000,
  shell("bash $HOME/.config/ags/lib/claude-usage.sh"),
  (stdout) => {
    try {
      return JSON.parse(stdout.trim())
    } catch {
      return { available: false, tokens: 0, costUsd: 0 }
    }
  },
)

function formatTokens(tokens: number) {
  if (tokens >= 1000000) return `${(tokens / 1000000).toFixed(2)}M`
  if (tokens >= 1000) return `${(tokens / 1000).toFixed(1)}K`
  return `${tokens}`
}

export function ClaudeUsageCard() {
  return (
    <box class="side-card" vertical spacing={6}>
      <box spacing={8}>
        <label class="side-card-icon" label={""} />
        <label class="side-card-title" label="Claude Code" xalign={0} halign={Gtk.Align.START} hexpand />
      </box>
      <label
        class="side-card-empty"
        label="No admin key set"
        xalign={0}
        halign={Gtk.Align.START}
        visible={usage.as((u) => !u.available)}
      />
      <box vertical spacing={4} visible={usage.as((u) => u.available)}>
        <box spacing={8}>
          <label class="side-card-label" label="Tokens today" xalign={0} halign={Gtk.Align.START} hexpand />
          <label class="side-card-value" label={usage.as((u) => formatTokens(u.tokens))} />
        </box>
        <box spacing={8}>
          <label class="side-card-label" label="Cost today" xalign={0} halign={Gtk.Align.START} hexpand />
          <label class="side-card-value" label={usage.as((u) => `$${u.costUsd.toFixed(2)}`)} />
        </box>
      </box>
    </box>
  )
}
