add_newline = true
command_timeout = 200
format = "$directory$git_branch$git_status$character"
palette = "blob"

[palettes.blob]
accent = "{{ accent }}"
foreground = "{{ foreground }}"
muted = "{{ muted }}"
success = "{{ green }}"
warning = "{{ yellow }}"
error = "{{ red }}"

[character]
error_symbol = "[✗](bold error)"
success_symbol = "[❯](bold accent)"

[directory]
style = "accent"
truncation_length = 2
truncation_symbol = "…/"
repo_root_style = "bold accent"
repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "

[git_branch]
format = "[$branch]($style) "
style = "italic accent"

[git_status]
format     = '[$all_status ]($style)'
style      = "warning"
ahead      = "⇡${count} "
diverged   = "⇕⇡${ahead_count}⇣${behind_count} "
behind     = "⇣${count} "
conflicted = " "
up_to_date = " "
untracked  = "? "
modified   = " "
stashed    = ""
staged     = ""
renamed    = ""
deleted    = ""
