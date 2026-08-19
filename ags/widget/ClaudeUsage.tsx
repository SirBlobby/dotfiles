import { Gtk } from "ags/gtk3"
import { createPoll } from "ags/time"
import { For } from "ags"
import { shell } from "../lib/utils"

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
  limits: [],
  days: [],
  models: [],
}

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

const MARK_PATH = "/usr/share/omarchy/shell/plugins/agents/assets/claude.svg"

function formatTokens(tokens: number) {
  if (tokens >= 1000000000) return `${(tokens / 1000000000).toFixed(1)}B`
  if (tokens >= 1000000) return `${(tokens / 1000000).toFixed(1)}M`
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

  if (days > 0) return `Resets in ${days}d ${hours}h`
  if (hours > 0) return `Resets in ${hours}h ${minutes}m`
  return `Resets in ${minutes}m`
}

function formatModelName(model: string) {
  return model
    .replace(/^claude-/, "")
    .replace(/-/g, " ")
    .replace(/(^| )(\w)/g, (_match, space, letter) => `${space}${letter.toUpperCase()}`)
}

function formatPercent(usedFraction: number) {
  if (usedFraction > 0 && usedFraction < 0.01) return "<1%"
  return `${Math.round(usedFraction * 100)}%`
}

function parseLimits(record: any): Limit[] {
  if (!Array.isArray(record.limits)) return []

  return record.limits.map((limit: any) => {
    const usedFraction = Number(limit.percent) || 0
    return {
      label: String(limit.label ?? "").replace(/\s*\(.*\)$/, ""),
      percent: usedFraction,
      fraction: Math.min(1, Math.max(0, usedFraction)),
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
    const shortDate = `${parsedDate.getMonth() + 1}/${parsedDate.getDate()}`
    const detail = `${weekday} ${shortDate} - ${formatTokens(tokens)} tokens`

    return {
      key: date,
      label: isToday ? "Today" : weekday,
      tokens: formatTokens(tokens),
      fraction: tokens / busiestDay,
      isToday,
      detail: isToday
        ? `${detail} - ${record.todayPrompts ?? 0} prompts, ${record.todaySessions ?? 0} sessions`
        : detail,
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
    <box vertical spacing={4}>
      <box spacing={8}>
        <label class="agent-limit-name" label={limit.label} xalign={0} halign={Gtk.Align.START} hexpand />
        <label class="agent-limit-percent" label={formatPercent(limit.percent)} />
      </box>
      <levelbar class="agent-limit-bar" value={limit.fraction} />
      <label class="agent-limit-reset" label={limit.resetsIn} xalign={0} halign={Gtk.Align.START} />
    </box>
  )
}

function DayRow({ day }: { day: DayUsage }) {
  return (
    <box class="agent-day-row" spacing={8} tooltipText={day.detail}>
      <label
        class={day.isToday ? "agent-day-label emphasized" : "agent-day-label"}
        label={day.label}
        xalign={0}
        halign={Gtk.Align.START}
      />
      <levelbar class="agent-day-bar" value={day.fraction} hexpand />
      <label
        class={day.isToday ? "agent-day-value emphasized" : "agent-day-value"}
        label={day.tokens}
        xalign={1}
        halign={Gtk.Align.END}
      />
    </box>
  )
}

function ModelRow({ model }: { model: ModelUsage }) {
  return (
    <overlay
      tooltipText={model.detail}
      overlays={[
        <box class="agent-model-text" spacing={8}>
          <label class="agent-model-label" label={model.label} xalign={0} halign={Gtk.Align.START} hexpand />
          <label class="agent-model-value" label={model.tokens} xalign={1} halign={Gtk.Align.END} />
        </box>,
      ]}
    >
      <levelbar class="agent-model-bar" value={model.fraction} />
    </overlay>
  )
}

export function ClaudeUsageCard() {
  return (
    <box class="panel widget-card" vertical spacing={10}>
      <box spacing={10}>
        <box class="agent-mark" valign={Gtk.Align.CENTER} css={`background-image: url('${MARK_PATH}');`} />
        <box vertical valign={Gtk.Align.CENTER}>
          <label
            class="agent-name"
            label={usage.as((u) => u.name)}
            xalign={0}
            halign={Gtk.Align.START}
          />
          <label
            class="agent-plan"
            label={usage.as((u) => u.plan.toUpperCase())}
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

      <box vertical spacing={10} visible={usage.as((u) => u.limits.length > 0)}>
        <SectionTitle title="LIMITS" />
        <For each={usage.as((u) => u.limits)} id={(limit: Limit) => limit.label}>
          {(limit: Limit) => <LimitRow limit={limit} />}
        </For>
      </box>

      <box vertical spacing={6} visible={usage.as((u) => u.days.length > 0)}>
        <SectionTitle title="TOKENS BY DAY" />
        <For each={usage.as((u) => u.days)} id={(day: DayUsage) => day.key}>
          {(day: DayUsage) => <DayRow day={day} />}
        </For>
      </box>

      <box vertical spacing={4} visible={usage.as((u) => u.models.length > 0)}>
        <SectionTitle title="TOKENS BY MODEL" />
        <For each={usage.as((u) => u.models)} id={(model: ModelUsage) => model.key}>
          {(model: ModelUsage) => <ModelRow model={model} />}
        </For>
      </box>
    </box>
  )
}
