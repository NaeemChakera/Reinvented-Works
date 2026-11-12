import Toybox.Lang;
import Toybox.WatchUi;

// The preset questions. The id is sent to the proxy, which maps it to the
// full question, so the proxy only ever answers these.
// To add one: add a line here and a matching entry in proxy/src/index.ts.
module Prompts {

    const ITEMS = [
        ["recovery", "Recovery check", "How ready am I?"],
        ["today",     "Plan today",     "What run today?"],
        ["lastrun",   "Last run",       "Review it"],
        ["pacing",    "Pacing tip",     "For my next run"],
        ["motivate", "Motivate me",    "Quick boost"]
    ];

    function showMenu() as Void {
        var menu = new WatchUi.Menu2({:title => "Ask"});
        for (var i = 0; i < ITEMS.size(); i++) {
            var item = ITEMS[i];
            menu.addItem(new WatchUi.MenuItem(item[1], item[2], item[0], null));
        }
        WatchUi.pushView(menu, new PromptMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

class PromptMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        var loading = new LoadingView();
        WatchUi.pushView(loading, new LoadingDelegate(loading), WatchUi.SLIDE_LEFT);
        new CoachRequest(id, loading).send();
    }
}
