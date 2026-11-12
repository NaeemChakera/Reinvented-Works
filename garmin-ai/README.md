# AI Coach for Garmin Forerunner 165

A watch app that sends your current stats (Body Battery, stress, resting HR,
VO2 max, steps, recent activities) plus a preset question to Claude, and
shows the answer on your wrist.

```
Watch app ──Bluetooth──► Garmin Connect (phone) ──HTTPS──► proxy (Cloudflare Worker) ──► Claude API
```

- `watch-app/`: the Connect IQ app (Monkey C), built for `fr165` and `fr165m`.
- `proxy/`: a small Cloudflare Worker. It keeps your API key off the watch,
  only answers the preset questions, and trims replies to fit the screen.

You need: an Anthropic API key (console.anthropic.com), a free Cloudflare
account, Node.js, and the Garmin Connect IQ SDK.

## 1. Deploy the proxy

```bash
cd garmin-ai/proxy
npm install
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY   # paste your Anthropic key
npx wrangler secret put WATCH_TOKEN         # paste a long random string, keep it
npx wrangler deploy
```

`deploy` prints a URL like `https://garmin-ai-coach.<you>.workers.dev`.
Test it:

```bash
curl -X POST https://garmin-ai-coach.<you>.workers.dev/ask \
  -H "X-Watch-Token: <your token>" -H "Content-Type: application/json" \
  -d '{"prompt":"recovery","data":{"bodyBattery":60,"restingHeartRate":52}}'
```

You should get `{"reply":"..."}` back.

## 2. Configure the watch app

Edit `watch-app/source/Config.mc`:

- `PROXY_URL`: your worker URL with `/ask` on the end.
- `WATCH_TOKEN`: the same string you used for the `WATCH_TOKEN` secret.

## 3. Build the watch app

1. Install the Connect IQ SDK Manager from
   https://developer.garmin.com/connect-iq/sdk/, sign in, and download the
   latest SDK and the **Forerunner 165** device.
2. Install VS Code and the **Monkey C** extension (by Garmin).
3. In VS Code run **Monkey C: Generate a Developer Key** (one time).
4. Open the `garmin-ai/watch-app` folder and run
   **Monkey C: Build for Device**, pick `fr165` (or `fr165m` if yours is the
   Music model). This writes `AI-Coach.prg` (the name may vary).

Optional: **Monkey C: Run** opens the simulator, which makes real requests
to your proxy, so you can try it before copying it to the watch.

## 4. Put it on the watch

1. Plug the watch into your computer with its USB cable.
2. Copy the `.prg` file into the watch's `GARMIN/APPS` folder.
   (On a Mac, use the free *OpenMTP* app to see the watch's files.)
3. Unplug. The app appears in the watch's app list as **AI Coach**.

## Using it

Open **AI Coach**, press **START**, pick a question. "Thinking..." shows
while the request goes through your phone; it usually takes a few seconds.
Scroll the answer with **UP/DOWN** (or swipe). **START** goes back to the
questions, **BACK** exits.

Your phone needs Bluetooth on, the Garmin Connect app running, and internet.

## Changing the questions

Questions live in two places so the proxy can't be used for anything else:

- `watch-app/source/Prompts.mc`: the id and the label shown on the watch.
- `proxy/src/index.ts`: the `PROMPTS` map, from id to the full question.

Add the same id to both, then redeploy the proxy and rebuild the app.

## Cost

Each question is one short Claude request, a fraction of a cent. The
Cloudflare free tier covers 100,000 requests a day.
