{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "~/.config/blob/branding/about.txt",
    "padding": {
      "top": 2,
      "left": 2,
      "right": 6
    }
  },
  "display": {
    "separator": "  ",
    "key": {
      "width": 9
    },
    "color": {
      "title": "{{ accent_ansi }}",
      "keys": "{{ accent_ansi }}",
      "output": "{{ foreground_ansi }}"
    }
  },
  "modules": [
    {
      "type": "title",
      "format": "{user-name}@{host-name}"
    },
    "break",
    { "type": "os",       "key": "os" },
    { "type": "kernel",   "key": "kernel" },
    { "type": "uptime",   "key": "uptime" },
    { "type": "packages", "key": "packages" },
    { "type": "shell",    "key": "shell" },
    "break",
    { "type": "wm",       "key": "wm" },
    { "type": "terminal", "key": "term" },
    { "type": "display",  "key": "display" },
    "break",
    { "type": "cpu",      "key": "cpu" },
    { "type": "gpu",      "key": "gpu" },
    { "type": "memory",   "key": "memory" },
    { "type": "disk",     "key": "disk" },
    "break",
    {
      "type": "colors",
      "symbol": "circle",
      "paddingLeft": 9
    }
  ]
}
