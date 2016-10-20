package app.simulation;

class Helpers {


    public static function toWeeklyRate(probability: Float, years: Int) {
        return Math.pow(1 + probability, 1 / (years * 52)) - 1; 
    }

    public static function toWeek(year: Int, month: Int) : Int {
        return year * 52 + month * 4;
    }

    public static function seed(s: String) : Float {
        var seed: Float = (s.charCodeAt(6) == null) ? s.charCodeAt(2) : s.charCodeAt(6);
        var seed = (seed * 9301 + 49297) % 233280;
        seed = seed / 233280.0;
        return seed;
    }

}