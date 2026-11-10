.pragma library

// True when `pattern` (a case-insensitive regular expression) finds a match in `text`; an invalid
// pattern never matches.
function found(pattern, text) {
    try { return new RegExp(pattern, "i").test(text) } catch (e) { return false }
}

// True when every field set on the rule matches the entry: app and appId exactly, appMatch as a
// regular expression over the app name, match as one over the summary and body. A rule with none of
// them set never matches, so a typo cannot silence everything.
function match(rule, entry) {
    const hasApp = !!rule.app, hasId = !!rule.appId, hasAppRe = !!rule.appMatch, hasText = !!rule.match
    if (!hasApp && !hasId && !hasAppRe && !hasText) return false
    if (hasApp && entry.appName !== rule.app) return false
    if (hasId && entry.appId !== rule.appId) return false
    if (hasAppRe && !found(rule.appMatch, entry.appName)) return false
    if (hasText && !found(rule.match, entry.summary + "\n" + entry.body)) return false
    return true
}
