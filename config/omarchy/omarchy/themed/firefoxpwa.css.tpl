/* Rendered by omarchy-theme-set-templates → ~/.local/state/omarchy/current/theme/firefoxpwa.css,
 * imported from the Meet PWA profile's chrome/userChrome.css. Applies on next app start. */
#navigator-toolbox {
  --toolbar-bgcolor:        {{ background }} !important;
  --toolbar-color:          {{ foreground }} !important;
  --toolbarbutton-icon-fill: {{ foreground }} !important;
  background-color:         {{ background }} !important;
  color:                    {{ foreground }} !important;
}
#navigator-toolbox > toolbar {
  --toolbar-bgcolor:        {{ background }} !important;
  --toolbar-color:          {{ foreground }} !important;
}
:root {
  --arrowpanel-background:  {{ dark_background }} !important;
  --arrowpanel-color:       {{ foreground }} !important;
}
/* PWAsForFirefox hides favicon+title when browser.tabs.inTitlebar=0 (assumes a native titlebar shows them);
 * we have no titlebar under Hyprland, so show them in the icon bar again. */
html:not([tabsintitlebar]):not([customtitlebar]) .site-info > * {
  display: flex !important;
}
