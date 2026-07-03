import app from "ags/gtk3/app"
import { execAsync } from "ags/process"

export function sh(command: string) {
  return execAsync(["bash", "-c", command]).catch((error) => {
    console.error(error)
    return ""
  })
}

export function shell(command: string): string[] {
  return ["bash", "-c", command]
}

export function toggleWindow(name: string) {
  app.toggle_window(name)
}
