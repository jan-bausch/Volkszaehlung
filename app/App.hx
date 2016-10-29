package app;

import app.simulation.Simulation;
import app.importing.JsonImport;
import app.rendering.Renderer;
import app.Events;

import js.Browser;

class App {

    public static var simulation: Simulation;
    public static var source: String = "";
    public static var renderer: Renderer;

    public static var running: Bool = false;
    private static var oldTime: Float = 0;
    private static var weeklyTime: Float = 0;

    private static var SIMULATION_SPEED: Float = 300; //Time in ms a week is long

    public static function initialize() {


        //Start rendering
        renderer = new Renderer("canvas");

        //Load available files
        renderer.displayFiles(JsonImport.loadFiles());

        //Start loop
        App.update(0);
    }

    public static function load(path: String) {
        App.pause();
        //Reset simulation
        simulation = new Simulation();

        //Import json
        JsonImport.importJson(path);
        source = path;
    }

    public static function start() {
        if (App.simulation == null) return; 
        running = true;
        Events.APP_START.dispatch();
        Events.GRAPH_UPDATE.dispatch();
    }

    public static function pause() {
        if (App.simulation == null) return; 
        running = false;
        Events.APP_PAUSE.dispatch();
        Events.GRAPH_UPDATE.dispatch();
    }

    public static function reset() {
        if (App.simulation == null) return; 
        //Reload current json file
        App.load(source);
        Events.APP_RESET.dispatch();
    }

    public static function update(time: Float) : Bool {

            var elapsed: Float = time  - App.oldTime;
            App.oldTime = time;

            //Simulate
            if (weeklyTime < SIMULATION_SPEED) {
                weeklyTime += elapsed;
            } else {
                weeklyTime = 0;
                if (running) simulation.simulate();
            }

            //Render
            if (running) {
                renderer.update(elapsed);
            } else {
                renderer.update(0);
            }


        Browser.window.requestAnimationFrame(App.update);
        return true;
    }

}