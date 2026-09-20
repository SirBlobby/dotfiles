_blob_completions() {
  local current="${COMP_WORDS[COMP_CWORD]}"
  local typed="${COMP_WORDS[*]:1:COMP_CWORD-1}"
  local prefix="blob"
  [[ -n $typed ]] && prefix="blob-${typed// /-}"

  local candidates=()
  local name suffix
  while IFS= read -r name; do
    suffix="${name#$prefix-}"
    [[ $suffix == "$name" ]] && continue
    candidates+=("${suffix%%-*}")
  done < <(compgen -c -- "$prefix-" | sort -u)

  if (( COMP_CWORD == 1 )); then
    candidates+=(help)
  fi

  COMPREPLY=($(compgen -W "$(printf '%s\n' "${candidates[@]}" | sort -u)" -- "$current"))
}

complete -F _blob_completions blob
