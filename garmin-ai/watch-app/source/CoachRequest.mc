import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

// Sends one question plus your current stats to the proxy (through the phone),
// then replaces the "Thinking..." screen with the answer or an error.
class CoachRequest {

    private var _promptId as String;
    private var _loading as LoadingView;

    function initialize(promptId as String, loading as LoadingView) {
        _promptId = promptId;
        _loading = loading;
    }

    function send() as Void {
        var body = {
            "prompt" => _promptId,
            "data" => HealthData.collect()
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "X-Watch-Token" => Config.WATCH_TOKEN
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(Config.PROXY_URL, body, options, method(:onResponse));
    }

    function onResponse(code as Number, data as Dictionary or String or Null) as Void {
        // The user backed out of the loading screen; don't pop up an answer.
        if (_loading.cancelled) {
            return;
        }

        var text;
        if (code == 200 && data instanceof Dictionary && data["reply"] != null) {
            text = data["reply"].toString();
        } else if (data instanceof Dictionary && data["error"] != null) {
            text = "Error: " + data["error"].toString();
        } else {
            text = describeError(code);
        }

        var view = new ResponseView(text);
        WatchUi.switchToView(view, new ResponseDelegate(view), WatchUi.SLIDE_LEFT);
    }

    private function describeError(code as Number) as String {
        if (code == -104 || code == -2) {
            return "Phone not connected. Open Garmin Connect on your phone and try again.";
        }
        if (code == -300) {
            return "Timed out. Check your phone has internet and try again.";
        }
        if (code == 401) {
            return "Token rejected. WATCH_TOKEN in Config.mc must match the proxy.";
        }
        if (code == 404) {
            return "Proxy URL not found. Check PROXY_URL in Config.mc.";
        }
        return "Request failed (code " + code + ").";
    }
}
