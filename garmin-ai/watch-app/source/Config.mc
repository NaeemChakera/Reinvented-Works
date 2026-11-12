// Edit these two values before you build.
//
// PROXY_URL:   the address of your deployed proxy (see ../proxy/README in the
//              main README). It must be https.
// WATCH_TOKEN: any long random string. Use the same value for the proxy's
//              WATCH_TOKEN secret, so only your watch can use your proxy.
module Config {
    const PROXY_URL = "https://garmin-ai-coach.YOUR-SUBDOMAIN.workers.dev/ask";
    const WATCH_TOKEN = "change-me-to-a-long-random-string";
}
