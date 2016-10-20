package app.simulation;

import app.simulation.Helpers;

class Probability {

    public static var AUSTRITT_NEULING: Float = Helpers.toWeeklyRate(0.42, 2);
    public static var AUSTRITT_KNAPPE: Float = Helpers.toWeeklyRate(0.43, 2);
    public static var AUSTRITT_SPAEHER: Float = Helpers.toWeeklyRate(0.41, 2);
    public static var AUSTRITT_PFADFINDER: Float = Helpers.toWeeklyRate(0.19, 2);
    public static var AUSTRITT_KORNETT: Float = Helpers.toWeeklyRate(0.33, 2);
    public static var AUSTRITT_FELDMEISTER: Float = Helpers.toWeeklyRate(0.2, 2);

    public static var GRUPPE_WERBEPHASE: Int = 5; //Time in weeks new members can be attracted
    public static var GRUPPE_EINSTIEG: Float = 0.5;
    public static var GRUPPE_EINSTIEGSALTER: Int = 10;
    public static var GRUPPE_GRUENDEN: Float = 0.005;

    public static function AUFSTIEG_NEULING(week: Int, groupCount: Int) : Float {
        //Set probability if week threshold is reached
        var prob: Float = groupCount * 0.05;
        if (week > Helpers.toWeek(10, 6)) return 0.5 + prob;
        return prob;
    }

    public static function AUFSTIEG_KNAPPE(week: Int, groupCount: Int) : Float {
        //Set probability if week threshold is reached
        var prob: Float = groupCount * 0.05;
        if (week > Helpers.toWeek(12, 4)) return 0.5 + prob;
        return prob;
    }

    public static function AUFSTIEG_SPAEHER(week: Int, groupCount: Int) : Float {
        //Set probability if week threshold is reached
        var prob: Float = groupCount * 0.05;
        if (week > Helpers.toWeek(14, 5)) return 0.5 + prob;
        return prob;
    }

    public static function AUFSTIEG_PFADFINDER(week: Int) : Float {
        //Set probability if week threshold is reached
        if (week > Helpers.toWeek(16, 7)) return 0.5;
        return 0;
    }

    public static function AUFSTIEG_KORNETT(week: Int) : Float {
        //Set probability if week threshold is reached
        if (week > Helpers.toWeek(19, 3)) return 0.5;
        return 0;
    }

    public static function probability(value: Float) : Bool {
        return (value == 0) ? false : Math.random() < value;
    }

}