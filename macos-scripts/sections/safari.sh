#!/usr/bin/env bash

# Safari -----------------------------------------------------------------------
set_or_audit com.apple.Safari UniversalSearchEnabled bool false
set_or_audit com.apple.Safari SuppressSearchSuggestions bool true
set_or_audit com.apple.Safari WebKitTabToLinksPreferenceKey bool true
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks bool true
set_or_audit com.apple.Safari ShowFullURLInSmartSearchField bool true
set_or_audit com.apple.Safari HomePage string "about:blank"
set_or_audit com.apple.Safari AutoOpenSafeDownloads bool false
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled bool true
set_or_audit com.apple.Safari ShowSidebarInTopSites bool false
set_or_audit com.apple.Safari DebugSnapshotsUpdatePolicy int 2
set_or_audit com.apple.Safari IncludeInternalDebugMenu bool true
set_or_audit com.apple.Safari FindOnPageMatchesWordStartsOnly bool false
set_or_audit com.apple.Safari ProxiesInBookmarksBar string "()"
set_or_audit com.apple.Safari IncludeDevelopMenu bool true
set_or_audit com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey bool true
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled bool true
set_or_audit NSGlobalDomain WebKitDeveloperExtras bool true
set_or_audit com.apple.Safari WebContinuousSpellCheckingEnabled bool true
set_or_audit com.apple.Safari WebAutomaticSpellingCorrectionEnabled bool false
set_or_audit com.apple.Safari AutoFillFromAddressBook bool false
set_or_audit com.apple.Safari AutoFillPasswords bool false
set_or_audit com.apple.Safari AutoFillCreditCardData bool false
set_or_audit com.apple.Safari AutoFillMiscellaneousForms bool false
set_or_audit com.apple.Safari WarnAboutFraudulentWebsites bool true
set_or_audit com.apple.Safari WebKitPluginsEnabled bool false
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled bool false
set_or_audit com.apple.Safari WebKitJavaEnabled bool false
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled bool false
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles bool false
set_or_audit com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically bool false
set_or_audit com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically bool false
set_or_audit com.apple.Safari SendDoNotTrackHTTPHeader bool true
set_or_audit com.apple.Safari InstallExtensionUpdatesAutomatically bool true
