"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCookieUrlFromDomain = getCookieUrlFromDomain;
// Fixed: the original implementation used tldts to parse out an eTLD+1
// (e.g. "railway.app") and set the cookie's Domain to that, on the
// assumption every hosting platform's wildcard subdomain is registered on
// the public suffix list. Railway's *.up.railway.app is not recognized as
// a public suffix by tldts's bundled data, so the original code computed
// Domain=.railway.app - a real, well-known browser security boundary
// (the actual Public Suffix List) then silently rejects that cookie
// entirely, since a page can never set a cookie for a whole public suffix.
// The result: registration/login succeed server-side, but the session
// cookie never lands in the browser, and the user gets bounced back to
// the login screen. Always using the exact hostname (no leading dot) is
// the standard fix - it's the most specific scope, and every browser
// accepts it unconditionally, regardless of whether the platform's
// wildcard domain is on the public suffix list or not.
function getCookieUrlFromDomain(domain) {
    try {
        return new URL(domain).hostname;
    } catch (e) {
        return domain;
    }
}
