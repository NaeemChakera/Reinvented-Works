import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shows the answer, word-wrapped, and scrolls with UP/DOWN or swipes.
class ResponseView extends WatchUi.View {

    private var _text as String;
    private var _lines as Array<String>?;
    private var _top as Number = 0;     // index of the first visible line
    private var _visible as Number = 1; // how many lines fit on screen
    const FONT = Graphics.FONT_XTINY;

    function initialize(text as String) {
        View.initialize();
        _text = text;
    }

    function scroll(delta as Number) as Void {
        if (_lines == null) {
            return;
        }
        var maxTop = _lines.size() - _visible;
        if (maxTop < 0) {
            maxTop = 0;
        }
        _top += delta;
        if (_top < 0) {
            _top = 0;
        }
        if (_top > maxTop) {
            _top = maxTop;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        // Keep text inside the middle of the round screen.
        var textWidth = (w * 0.78).toNumber();
        var topY = (h * 0.16).toNumber();
        var bottomY = (h * 0.84).toNumber();
        var lineH = dc.getFontHeight(FONT);

        if (_lines == null) {
            _lines = wrap(dc, _text, textWidth);
        }
        _visible = (bottomY - topY) / lineH;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var lines = _lines as Array<String>;
        for (var i = 0; i < _visible && _top + i < lines.size(); i++) {
            dc.drawText(w / 2, topY + i * lineH, FONT, lines[_top + i], Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Small arrows when there is more text above or below.
        dc.setColor(0xFF6A00, Graphics.COLOR_TRANSPARENT);
        if (_top > 0) {
            dc.fillPolygon([[w / 2 - 8, topY - 6], [w / 2 + 8, topY - 6], [w / 2, topY - 14]]);
        }
        if (_top + _visible < lines.size()) {
            dc.fillPolygon([[w / 2 - 8, bottomY + 6], [w / 2 + 8, bottomY + 6], [w / 2, bottomY + 14]]);
        }
    }

    // Greedy word wrap. Paragraph breaks ("\n") in the reply are kept.
    private function wrap(dc as Graphics.Dc, text as String, maxWidth as Number) as Array<String> {
        var out = [] as Array<String>;
        var paragraphs = split(text, "\n");
        for (var p = 0; p < paragraphs.size(); p++) {
            var words = split(paragraphs[p], " ");
            var line = "";
            for (var i = 0; i < words.size(); i++) {
                var word = words[i];
                if (word.length() == 0) {
                    continue;
                }
                var candidate = line.length() == 0 ? word : line + " " + word;
                if (dc.getTextWidthInPixels(candidate, FONT) <= maxWidth || line.length() == 0) {
                    line = candidate;
                } else {
                    out.add(line);
                    line = word;
                }
            }
            if (line.length() > 0) {
                out.add(line);
            }
        }
        return out;
    }

    private function split(s as String, sep as String) as Array<String> {
        var parts = [] as Array<String>;
        var rest = s;
        var idx = rest.find(sep);
        while (idx != null) {
            parts.add(rest.substring(0, idx) as String);
            rest = rest.substring(idx + sep.length(), rest.length()) as String;
            idx = rest.find(sep);
        }
        parts.add(rest);
        return parts;
    }
}

class ResponseDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ResponseView;

    function initialize(view as ResponseView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // DOWN button / swipe up
    function onNextPage() as Boolean {
        _view.scroll(3);
        return true;
    }

    // UP button / swipe down
    function onPreviousPage() as Boolean {
        _view.scroll(-3);
        return true;
    }

    // START goes back to the question list for another one.
    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
