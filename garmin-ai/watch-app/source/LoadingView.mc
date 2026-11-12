import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// "Thinking..." screen with animated dots while the answer comes back.
class LoadingView extends WatchUi.View {

    var cancelled as Boolean = false;
    private var _dots as Number = 0;
    private var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _timer = new Timer.Timer();
        _timer.start(method(:tick), 400, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function tick() as Void {
        _dots = (_dots + 1) % 4;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var label = "Thinking";
        for (var i = 0; i < _dots; i++) {
            label += ".";
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class LoadingDelegate extends WatchUi.BehaviorDelegate {

    private var _view as LoadingView;

    function initialize(view as LoadingView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onBack() as Boolean {
        _view.cancelled = true;
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
