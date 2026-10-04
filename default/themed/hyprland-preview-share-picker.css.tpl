@define-color foreground {{ foreground }};
@define-color background {{ background }};
@define-color accent {{ accent }};
@define-color muted {{ muted }};
@define-color card_bg {{ lighter_background }};
@define-color text_dark {{ background }};
@define-color accent_hover {{ bright_blue }};
@define-color selected_tab {{ accent }};
@define-color text {{ foreground }};

* {
  all: unset;
  font-family: monospace;
  color: @foreground;
  font-weight: bold;
  font-size: 16px;
}

.window {
  background: @background;
  border: solid 2px @accent;
  margin: 4px;
  padding: 18px;
}

tabs {
    padding: 0.5rem 1rem;
}

tabs > tab {
    margin-right: 1rem;
}

.tab-label {
    color: alpha(@text, 0.6);
    transition: all 0.2s ease;
}

tabs > tab:checked > .tab-label, tabs > tab:active > .tab-label {
    color: @selected_tab;
}

tabs > tab:focus > .tab-label {
    color: @foreground;
}

.page {
    padding: 1rem;
}

.image-label {
    font-size: 12px;
    padding: 0.25rem;
}

flowboxchild > .card, button > .card {
    transition: all 0.2s ease;
    border: solid 2px alpha(@accent, 0.5);
    border-radius: 0;
    background-color: alpha(@card_bg, 0.6);
    padding: 5px;
}

flowboxchild:hover > .card, button:hover > .card, flowboxchild:active > .card, flowboxchild:selected > .card, button:active > .card, button:selected > .card, button:focus > .card {
    border: solid 2px @accent;
    background-color: @card_bg;
}

.image {
    border-radius: 0;
}

.region-button {
    padding: 0.5rem 1rem;
    border-radius: 0;
    background-color: @accent;
    color: @text_dark;
    transition: all 0.2s ease;
}

.region-button > label {
    color: @text_dark;
}

.region-button:not(:disabled):hover, .region-button:not(:disabled):focus {
    background-color: @accent_hover;
    color: @text_dark;
}

.region-button:disabled {
    background-color: @muted;
    color: @background;
}

.restore-button {
    padding: 0.35rem 0.75rem;
    border: solid 2px alpha(@accent, 0.5);
    background-color: alpha(@card_bg, 0.6);
    transition: all 0.2s ease;
}

.restore-button:hover, .restore-button:focus {
    border-color: @accent;
    background-color: @card_bg;
}

.restore-button label {
    font-size: 12px;
    color: alpha(@text, 0.6);
    margin-left: 0.5rem;
}

.restore-button:hover label, .restore-button:focus label {
    color: @foreground;
}

.restore-button check {
    min-width: 10px;
    min-height: 10px;
    border: solid 2px alpha(@accent, 0.5);
    -gtk-icon-source: none;
    transition: all 0.2s ease;
}

.restore-button check:checked {
    border-color: @accent;
    background-color: @accent;
}
