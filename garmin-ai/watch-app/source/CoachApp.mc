import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class CoachApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new HomeView(), new HomeDelegate()];
    }
}
