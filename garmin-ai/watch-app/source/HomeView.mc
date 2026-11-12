import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// First screen: app name and a hint. START (or a tap) opens the question menu.
class HomeView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(0xFF6A00, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.35, Graphics.FONT_MEDIUM, "AI Coach",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.58, Graphics.FONT_XTINY, "Press START",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 0.68, Graphics.FONT_XTINY, "to ask a question",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        Prompts.showMenu();
        return true;
    }

    function onMenu() as Boolean {
        Prompts.showMenu();
        return true;
    }
}
