// FirefoxPWA profiles (Work, Personal): navigate the existing tab instead of opening
// another window. Read at profile startup; close the app fully after changing this.
user_pref('firefoxpwa.launchType', 2);

// Out-of-scope links leave the app: the runtime cancels the navigation and hands the URL
// to the xdg https handler (url-open), which routes app links to their PWA/app and the
// rest to a Zen tab. Login hosts stay in-app, else SSO bounces to the browser.
user_pref('firefoxpwa.openOutOfScopeInDefaultBrowser', true);
// _blank links (Meet chat, outbound links) open in a background tab, not the current tab. The
// runtime default (1 = current tab) navigates the app's own tab before the out-of-scope hand-off
// cancels it, and Meet treats that as leaving the call. 2 (new window) left an empty window per
// click (only the http-observer hand-off ran, it cancels but never closes; cf. PWAsForFirefox#677).
// No tab strip without tabs mode: in-app ctrl/middle-click lands in a hidden tab (Ctrl+Tab).
user_pref('firefoxpwa.linksTarget', 3);
user_pref('browser.tabs.loadDivertedInBackground', true);
user_pref('firefoxpwa.allowedDomains', 'accounts.google.com,accounts.youtube.com,consent.google.com,consent.youtube.com,*.youtube.com,twitter.com,*.x.com');

// No Ctrl+W / Ctrl+Shift+W: a habitual close kills a Meet call. Close windows via Hyprland;
// Ctrl+Shift+Q (quit app) stays.
user_pref('firefoxpwa.shortcuts.closeTab', false);
user_pref('firefoxpwa.shortcuts.closeWindow', false);

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
