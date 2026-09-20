# Put the blob command on PATH for login shells. The graphical session gets the
# same environment from ~/.config/uwsm/env.d/10-blob.

if [ -r "$HOME/.local/share/blob/session/env-bootstrap" ]; then
  . "$HOME/.local/share/blob/session/env-bootstrap"
fi
