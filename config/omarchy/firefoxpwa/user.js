// Meet's dedicated PWA profile: navigate the existing tab instead of opening
// another window. Read at profile startup; close Meet fully after changing this.
user_pref('firefoxpwa.launchType', 2);

// Allow hiding the PWA's Icon Bar through its toolbar menu (experimental).
user_pref('firefoxpwa.enableHidingIconBar', true);

// Match Zen under Hyprland: let the compositor own window decorations.
// Override FirefoxPWA's defaults for both Firefox titlebar preference variants.
user_pref('browser.tabs.inTitlebar', 0);
user_pref('browser.tabs.drawInTitlebar', false);

// Omarchy palette instead of the manifest/page theme_color (#1a73e8 Google blue).
// Toolbar colors come from chrome/userChrome.css (hooks/theme-set.d/firefoxpwa).
user_pref('firefoxpwa.sitesSetThemeColor', false);
user_pref('firefoxpwa.dynamicThemeColor', false);
user_pref('toolkit.legacyUserProfileCustomizations.stylesheets', true);
