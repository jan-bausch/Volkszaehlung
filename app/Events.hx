package app;

import msignal.Signal;

class Events{

    public static var WEEK_START = new Signal1(Int);
    public static var APP_PAUSE = new Signal0();
    public static var APP_START = new Signal0();
    public static var APP_RESET = new Signal0();

    public static var GRAPH_UPDATE = new Signal0();

}