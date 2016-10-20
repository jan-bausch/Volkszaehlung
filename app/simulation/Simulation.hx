package app.simulation;

import app.simulation.Group;
import app.Events;

class Simulation {

    public var groups: Group;

    public var week: Int = 0;
    public var startWeek: Int;
    public var startYear: Int; 

    private static var GRAPH_UPDATE_THRESHOLD: Int = 5; //Update graphs every x weeks
    private var graphUpdateCounter = 0;

    public function new() {
        groups = new Group("HP", "transparent");
    }

    public function simulate() {
        groups.simulate();
        Events.WEEK_START.dispatch(this.week);

        //Update numbers
        this.week++;
        if (graphUpdateCounter == 0) {
            Events.GRAPH_UPDATE.dispatch();
            graphUpdateCounter = GRAPH_UPDATE_THRESHOLD;
        } else {
            graphUpdateCounter--;
        }
    }

}