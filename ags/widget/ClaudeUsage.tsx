import { Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { For } from "ags"
import { shell } from "../lib/utils"
import { StatRow } from "./WidgetCard"

type Limit = {
  label: string
  percent: number
  fraction: number
  resetsIn: string
}

type DayUsage = {
  key: string
  label: string
  tokens: string
  fraction: number
  isToday: boolean
  detail: string
}

type ModelUsage = {
  key: string
  label: string
  tokens: string
  fraction: number
  detail: string
}

type AgentUsage = {
  ready: boolean
  name: string
  plan: string
  statusText: string
  helpText: string
  todayPrompts: number
  todaySessions: number
  todayTokens: string
  limits: Limit[]
  days: DayUsage[]
  models: ModelUsage[]
}

const EMPTY_USAGE: AgentUsage = {
  ready: false,
  name: "Claude Code",
  plan: "",
  statusText: "",
  helpText: "",
  todayPrompts: 0,
  todaySessions: 0,
  todayTokens: "0",
  limits: [],
  days: [],
  models: [],
}

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

function formatTokens(tokens: number) {
  if (tokens >= 1000000000) return `${(tokens / 1000000000).toFixed(2)}B`
  if (tokens >= 1000000) return `${(tokens / 1000000).toFixed(2)}M`
  if (tokens >= 1000) return `${(tokens / 1000).toFixed(1)}K`
  return `${Math.round(tokens)}`
}

function localDateKey(date: Date) {
  const month = `${date.getMonth() + 1}`.padStart(2, "0")
  const day = `${date.getDate()}`.padStart(2, "0")
  return `${date.getFullYear()}-${month}-${day}`
}

function formatResetsIn(resetsAt: string) {
  const resetTime = Date.parse(resetsAt)
  if (!resetTime) return ""

  const minutesLeft = Math.round((resetTime - Date.now()) / 60000)
  if (minutesLeft <= 0) return "resetting"

  const days = Math.floor(minutesLeft / 1440)
  const hours = Math.floor((minutesLeft % 1440) / 60)
  const minutes = minutesLeft % 60

  if (days > 0) return `resets in ${days}d ${hours}h`
  if (hours > 0) return `resets in ${hours}h ${minutes}m`
  return `resets in ${minutes}m`
}

function formatModelName(model: string) {
  return model
    .replace(/^claude-/, "")
    .replace(/-/g, " ")
    .replace(/(^| )(\w)/g, (_match, space, letter) => `${space}${letter.toUpperCase()}`)
}

function parseLimits(record: any): Limit[] {
  if (!Array.isArray(record.limits)) return []

  return record.limits.map((limit: any) => {
    const percent = Number(limit.percent) || 0
    return {
      label: String(limit.label ?? ""),
      percent,
      fraction: Math.min(1, Math.max(0, percent / 100)),
      resetsIn: formatResetsIn(String(limit.resetsAt ?? "")),
    }
  })
}

function parseDays(record: any): DayUsage[] {
  if (!Array.isArray(record.recentDays)) return []

  const todayKey = localDateKey(new Date())
  const dayTokens = record.recentDays.map((day: any) => Number(day.messageCount) || 0)
  const busiestDay = Math.max(...dayTokens, 1)

  return record.recentDays.map((day: any, index: number) => {
    const date = String(day.date ?? "")
    const tokens = dayTokens[index]
    const isToday = date === todayKey
    const parsedDate = new Date(`${date}T00:00:00`)
    const weekday = WEEKDAYS[parsedDate.getDay()] ?? date

    return {
      key: date,
      label: isToday ? "Today" : weekday,
      tokens: formatTokens(tokens),
      fraction: tokens / busiestDay,
      isToday,
      detail: isToday
        ? `${record.todayPrompts ?? 0} prompts across ${record.todaySessions ?? 0} sessions`
        : date,
    }
  })
}

function parseModels(record: any): ModelUsage[] {
  const usageByModel = record.modelUsage
  if (!usageByModel || typeof usageByModel !== "object") return []

  const models = Object.keys(usageByModel).map((model) => {
    const usage = usageByModel[model] ?? {}
    const input = Number(usage.inputTokens) || 0
    const output = Number(usage.outputTokens) || 0
    const cacheCreation = Number(usage.cacheCreationInputTokens) || 0
    const cacheRead = Number(usage.cacheReadInputTokens) || 0

    return {
      key: model,
      label: formatModelName(model),
      total: input + output + cacheCreation + cacheRead,
      detail:
        `in ${formatTokens(input)} - out ${formatTokens(output)} - ` +
        `cache write ${formatTokens(cacheCreation)} - cache read ${formatTokens(cacheRead)}`,
    }
  })

  const heaviestModel = Math.max(...models.map((model) => model.total), 1)

  return models
    .sort((left, right) => right.total - left.total)
    .map((model) => ({
      key: model.key,
      label: model.label,
      tokens: formatTokens(model.total),
      fraction: model.total / heaviestModel,
      detail: model.detail,
    }))
}

function parseUsage(stdout: string): AgentUsage {
  try {
    const record = JSON.parse(stdout.trim())
    if (!record.ready) return EMPTY_USAGE

    return {
      ready: true,
      name: String(record.name ?? "Claude Code"),
      plan: String(record.tierLabel ?? ""),
      statusText: String(record.usageStatusText ?? ""),
      helpText: String(record.authHelpText ?? ""),
      todayPrompts: Number(record.todayPrompts) || 0,
      todaySessions: Number(record.todaySessions) || 0,
      todayTokens: formatTokens(Number(record.todayTotalTokens) || 0),
      limits: parseLimits(record),
      days: parseDays(record),
      models: parseModels(record),
    }
  } catch {
    return EMPTY_USAGE
  }
}

const usage = createPoll<AgentUsage>(
  EMPTY_USAGE,
  60000,
  shell("bash $HOME/.config/ags/lib/claude-usage.sh"),
  (stdout) => parseUsage(stdout),
)

function SectionTitle({ title }: { title: string }) {
  return <label class="widget-section-title" label={title} xalign={0} halign={Gtk.Align.START} />
}

function LimitRow({ limit }: { limit: Limit }) {
  return (
    <box class="agent-limit" vertical spacing={4}>
      <box spacing={8}>
        <label class="widget-card-label" label={limit.label} xalign={0} halign={Gtk.Align.START} hexpand />
        <label class="widget-card-value" label={`${limit.percent.toFixed(1)}%`} />
      </box>
      <levelbar class="widget-level-bar" value={limit.fraction} />
      <label class="agent-limit-reset" label={limit.resetsIn} xalign={0} halign={Gtk.Align.START} />
    </box>
  )
}

function BarRow({ label, tokens, fraction, detail, emphasized }: {
  label: string
  tokens: string
  fraction: number
  detail: string
  emphasized: boolean
}) {
  return (
    <box class="agent-bar-row" spacing={8} tooltipText={detail}>
      <label
        class={emphasized ? "agent-bar-label emphasized" : "agent-bar-label"}
        label={label}
        xalign={0}
        halign={Gtk.Align.START}
      />
      <levelbar class="widget-level-bar agent-bar" value={fraction} hexpand />
      <label
        class={emphasized ? "agent-bar-value emphasized" : "agent-bar-value"}
        label={tokens}
        xalign={1}
        halign={Gtk.Align.END}
      />
    </box>
  )
}

export function ClaudeUsageCard() {
  return (
    <box class="panel widget-card" vertical spacing={10}>
      <box class="widget-card-header" spacing={10}>
        <box class="widget-icon-badge">
          <label label={""} hexpand vexpand halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />
        </box>
        <box vertical hexpand>
          <label
            class="widget-card-title"
            label={usage.as((u) => u.name)}
            xalign={0}
            halign={Gtk.Align.START}
          />
          <label
            class="agent-plan"
            label={usage.as((u) => u.plan)}
            visible={usage.as((u) => u.plan.length > 0)}
            xalign={0}
            halign={Gtk.Align.START}
          />
        </box>
      </box>

      <label
        class="widget-card-empty"
        label="No agent usage recorded yet"
        xalign={0}
        halign={Gtk.Align.START}
        visible={usage.as((u) => !u.ready)}
      />

      <box vertical spacing={4} visible={usage.as((u) => u.statusText.length > 0)}>
        <label class="agent-status" label={usage.as((u) => u.statusText)} xalign={0} halign={Gtk.Align.START} />
        <label
          class="agent-help"
          label={usage.as((u) => u.helpText)}
          xalign={0}
          halign={Gtk.Align.START}
          wrap
          maxWidthChars={30}
        />
      </box>

      <box vertical spacing={8} visible={usage.as((u) => u.limits.length > 0)}>
        <SectionTitle title="Limits" />
        <For each={usage.as((u) => u.limits)} id={(limit: Limit) => limit.label}>
          {(limit: Limit) => <LimitRow limit={limit} />}
        </For>
      </box>

      <box vertical spacing={8} visible={usage.as((u) => u.ready)}>
        <SectionTitle title="Today" />
        <StatRow icon={""} label="Tokens" value={usage.as((u) => u.todayTokens)} />
        <StatRow icon={""} label="Prompts" value={usage.as((u) => `${u.todayPrompts}`)} />
        <StatRow icon={""} label="Sessions" value={usage.as((u) => `${u.todaySessions}`)} />
      </box>

      <box vertical spacing={6} visible={usage.as((u) => u.days.length > 0)}>
        <SectionTitle title="Tokens by day" />
        <For each={usage.as((u) => u.days)} id={(day: DayUsage) => day.key}>
          {(day: DayUsage) => (
            <BarRow
              label={day.label}
              tokens={day.tokens}
              fraction={day.fraction}
              detail={day.detail}
              emphasized={day.isToday}
            />
          )}
        </For>
      </box>

      <box vertical spacing={6} visible={usage.as((u) => u.models.length > 0)}>
        <SectionTitle title="Tokens by model" />
        <For each={usage.as((u) => u.models)} id={(model: ModelUsage) => model.key}>
          {(model: ModelUsage) => (
            <BarRow
              label={model.label}
              tokens={model.tokens}
              fraction={model.fraction}
              detail={model.detail}
              emphasized={false}
            />
          )}
        </For>
      </box>
    </box>
  )
}
