/*
 see https://codeberg.org/da157/PotatoFox
*/

// userchrome.css usercontent.css activate
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// fill svg color
// user_pref("svg.context-properties.content.enabled", true);

// enable :has selector
// user_pref("layout.css.has-selector.enabled", true);

// trim url
user_pref("browser.urlbar.trimHttps", true);
user_pref("browser.urlbar.trimURLs", true);

// show profile management in hamburger menu
user_pref("browser.profiles.enabled", true);

// gtk rounded corners
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);

// show compact mode
user_pref("browser.compactmode.show", true);

// fix sidebar tab drag on linux
user_pref("widget.gtk.ignore-bogus-leave-notify", 1);

// uidensity -> compact
user_pref("browser.uidensity", 1);

// don't warn on about:config open
user_pref("browser.aboutConfig.showWarning", false);

// https://rubenerd.com/mozillas-latest-quagmire/
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.chat.menu", false);
user_pref("browser.ml.chat.page", false);
user_pref("extensions.ml.enabled", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);
user_pref("browser.tabs.groups.smart.userEnabled", false);
user_pref("pdfjs.enableAltTextModelDownload", false);
user_pref("pdfjs.enableGuessAltText", false);


// https://github.com/SakuraMeadows/Sakuras-Simple-Sidebar
user_pref("sidebar.revamp", false):
user_pref("sidebar.old-sidebar.has-used", true);
//user_pref("svg.context-properties.content.enabled", true);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
