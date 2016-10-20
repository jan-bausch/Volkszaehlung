package app;

import app.simulation.Simulation;
import app.importing.JsonImport;
import app.rendering.Renderer;
import app.Events;

import js.Browser;

class App {

    public static var simulation: Simulation;
    public static var renderer: Renderer;

    public static var running: Bool = false;
    private static var oldTime: Float = 0;
    private static var weeklyTime: Float = 0;
    private static var SIMULATION_SPEED: Float = 300; //Time in ms a week is long

    public static function initialize() {

        simulation = new Simulation();

        //Import Json
        JsonImport.importJson("data/test.json");

        //Start rendering
        renderer = new Renderer("canvas");

        //Start loop
        App.update(0);
    }

    public static function start() {
        running = true;
    }

    public static function pause() {
        running = false;
    }

    public static function reset() {
        pause();
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