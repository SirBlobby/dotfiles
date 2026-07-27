import { Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { shell } from "../lib/utils"
import { CardHeader, StatRow } from "./WidgetCard"

type ClaudeUsage = {
  available: boolean
  tokens: number
  messages: number
  cacheHitPercent: number
}

const usage = createPoll<ClaudeUsage>(
  { available: false, tokens: 0, messages: 0, cacheHitPercent: 0 },
  60000,
  shell("bash $HOME/.config/ags/lib/claude-usage.sh"),
  (stdout) => {
    try {
      return JSON.parse(stdout.trim())
    } catch {
      return { available: false, tokens: 0, messages: 0, cacheHitPercent: 0 }
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
    <box class="panel widget-card" vertical spacing={10}>
      <CardHeader icon={""} title="Claude Code" />
      <label
        class="widget-card-empty"
        label="No usage logs found"
        xalign={0}
        halign={Gtk.Align.START}
        visible={usage.as((u) => !u.available)}
      />
      <box vertical spacing={8} visible={usage.as((u) => u.available)}>
        <StatRow icon={""} label="Tokens today" value={usage.as((u) => formatTokens(u.tokens))} />
        <StatRow icon={""} label="Messages today" value={usage.as((u) => `${u.messages}`)} />
        <box vertical spacing={4}>
          <box spacing={8}>
            <label class="widget-card-label" label="Cache hit rate" xalign={0} halign={Gtk.Align.START} hexpand />
            <label class="widget-card-value" label={usage.as((u) => `${Math.round(u.cacheHitPercent)}%`)} />
          </box>
          <levelbar class="widget-level-bar" value={usage.as((u) => u.cacheHitPercent / 100)} />
        </box>
      </box>
    </box>
  )
}
