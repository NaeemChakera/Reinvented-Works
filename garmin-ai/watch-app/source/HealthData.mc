import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;

// Collects what the watch knows about you right now, as a small dictionary
// that gets sent to the proxy as JSON. Every field is optional: anything the
// watch doesn't have (or this firmware doesn't expose) is simply left out.
module HealthData {

    function collect() as Dictionary {
        var d = {} as Dictionary<String, Object>;

        var clock = System.getClockTime();
        d.put("localTime", clock.hour.format("%02d") + ":" + clock.min.format("%02d"));

        addActivityMonitor(d);
        addProfile(d);
        addSensorHistory(d);
        addRecentActivities(d);
        return d;
    }

    function addActivityMonitor(d as Dictionary) as Void {
        var info = ActivityMonitor.getInfo();
        if (info == null) {
            return;
        }
        putIf(d, "stepsToday", info.steps);
        putIf(d, "stepGoal", info.stepGoal);
        putIf(d, "caloriesToday", info.calories);
        if (info.distance != null) {
            d.put("distanceTodayKm", (info.distance / 100000.0).format("%.2f"));
        }
        if (info.activeMinutesWeek != null) {
            putIf(d, "intensityMinutesThisWeek", info.activeMinutesWeek.total);
        }
        if (info has :timeToRecovery) {
            putIf(d, "recoveryTimeHours", info.timeToRecovery);
        }
    }

    function addProfile(d as Dictionary) as Void {
        var p = UserProfile.getProfile();
        if (p == null) {
            return;
        }
        putIf(d, "restingHeartRate", p.restingHeartRate);
        if (p has :vo2maxRunning) {
            putIf(d, "vo2maxRunning", p.vo2maxRunning);
        }
        if (p.birthYear != null) {
            var year = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year;
            d.put("age", year - p.birthYear);
        }
    }

    function addSensorHistory(d as Dictionary) as Void {
        if (SensorHistory has :getBodyBatteryHistory) {
            putIf(d, "bodyBattery", latest(SensorHistory.getBodyBatteryHistory({:period => 1})));
        }
        if (SensorHistory has :getStressHistory) {
            putIf(d, "stress", latest(SensorHistory.getStressHistory({:period => 1})));
        }
        if (SensorHistory has :getHeartRateHistory) {
            putIf(d, "currentHeartRate", latest(SensorHistory.getHeartRateHistory({:period => 1})));
        }
    }

    // Up to the 5 most recent activities, newest first.
    function addRecentActivities(d as Dictionary) as Void {
        if (!(UserProfile has :getUserActivityHistory)) {
            return;
        }
        var it = UserProfile.getUserActivityHistory();
        if (it == null) {
            return;
        }
        var all = [];
        var a = it.next();
        while (a != null) {
            if (a.startTime != null) {
                all.add(a);
            }
            a = it.next();
        }

        // Sort by start time, newest first (simple selection sort; the list is small).
        for (var i = 0; i < all.size(); i++) {
            for (var j = i + 1; j < all.size(); j++) {
                if (all[j].startTime.value() > all[i].startTime.value()) {
                    var tmp = all[i];
                    all[i] = all[j];
                    all[j] = tmp;
                }
            }
        }

        var now = Time.now().value();
        var out = [];
        for (var k = 0; k < all.size() && k < 5; k++) {
            var act = all[k];
            var entry = {} as Dictionary<String, Object>;
            entry.put("daysAgo", ((now - act.startTime.value()) / 86400).toNumber());
            entry.put("sport", sportName(act.type));
            if (act.distance != null) {
                entry.put("distanceKm", (act.distance / 1000.0).format("%.2f"));
            }
            if (act.duration != null) {
                var secs = act.duration.value();
                entry.put("durationMin", (secs / 60).toNumber());
                if (act.distance != null && act.distance > 0) {
                    var paceSecPerKm = (secs / (act.distance / 1000.0)).toNumber();
                    entry.put("pacePerKm", (paceSecPerKm / 60).format("%d") + ":" + (paceSecPerKm % 60).format("%02d"));
                }
            }
            out.add(entry);
        }
        if (out.size() > 0) {
            d.put("recentActivities", out);
        }
    }

    function sportName(sport) as String {
        if (sport == null) { return "unknown"; }
        if (sport == Activity.SPORT_RUNNING) { return "running"; }
        if (sport == Activity.SPORT_CYCLING) { return "cycling"; }
        if (sport == Activity.SPORT_WALKING) { return "walking"; }
        if (sport == Activity.SPORT_SWIMMING) { return "swimming"; }
        if (sport == Activity.SPORT_HIKING) { return "hiking"; }
        if (sport == Activity.SPORT_TRAINING) { return "strength/training"; }
        return "other";
    }

    function latest(iter) {
        if (iter == null) {
            return null;
        }
        var sample = iter.next();
        if (sample == null || sample.data == null) {
            return null;
        }
        return sample.data.toNumber();
    }

    function putIf(d as Dictionary, key as String, value) as Void {
        if (value != null) {
            d.put(key, value);
        }
    }
}
