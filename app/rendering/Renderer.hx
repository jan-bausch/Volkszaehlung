    package app.rendering;

import app.simulation.Group;
import app.simulation.Person;

import js.Browser;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.MouseEvent;
import js.html.WheelEvent;
import js.html.KeyboardEvent;
import js.html.UListElement;
import js.html.LIElement;
import js.html.Element;

class Renderer{

    private var canvas: CanvasElement;
    private var ctx: CanvasRenderingContext2D;

    private var buffer: CanvasRenderingContext2D;
    private static var BUFFER_SIZE: Int = 3000;

    private var zoom: Float;
    private var dragging: Bool;
    private var offsetX: Int;
    private var offsetY: Int;

    private var mouseStartX: Int;
    private var mouseStartY: Int;
    private var offsetStartX: Int;
    private var offsetStartY: Int;

    private var animation: Float;
    private var animationSpeed: Float = 0.01 / 16;
    public var DISPLAY_RELATIONS: Bool = true;

    private var SCROLL_SPEED: Float = 0.1;

    //Show statistics for the first ... groups
    private var STATISTIC_LEVEL_THRESHOLD: Int = 2;

    public function new(canvasId: String) {

        this.canvas = cast Browser.document.getElementById(canvasId);
        this.ctx = this.canvas.getContext2d();

        this.canvas.onmousemove = this.onMouseMove;
        this.canvas.onmousedown = this.onMouseDown;
        this.canvas.onmouseup = this.onMouseUp;
        this.canvas.onmousewheel = this.onMouseScroll;

        this.zoom = 0.5;
        this.offsetX = 0;
        this.offsetY = 0;
        this.dragging = false;

        //Create virtual buffer
        var bufferCanvas: CanvasElement = cast Browser.document.createElement("canvas");
        bufferCanvas.width = BUFFER_SIZE;
        bufferCanvas.height = BUFFER_SIZE;
        this.buffer = bufferCanvas.getContext2d();

        //Browser.window.setInterval(App.update, 33);
        this.animation = 0;

        //Register events
        Events.WEEK_START.add(this.onWeekStart);
        Events.GRAPH_UPDATE.add(this.onUpdateGraph);
        Events.APP_START.add(onAppStart);
        Events.APP_PAUSE.add(onAppPause);
        Events.APP_RESET.add(onAppReset);
        Events.APP_LOAD.add(onAppLoad);

        Browser.document.getElementById("start").onclick = this.onStartClick;
        Browser.document.getElementById("reset").onclick = this.onResetClick;
        Browser.document.onkeypress = this.onKeyDown;

        //Display constants
        this.displayConstants(App.getConstants());

        this.scale();
    }

    private function renderBuffer() {
        this.buffer.clearRect(0,0,this.buffer.canvas.width, this.buffer.canvas.height);
        this.buffer.translate(BUFFER_SIZE/2, BUFFER_SIZE/2);

        renderRecursive(App.simulation.groups);

        this.buffer.translate(-BUFFER_SIZE/2, -BUFFER_SIZE/2);
    }

    private function renderRecursive(group: Group) {


        for (child in group.children) {

            this.buffer.rotate((child.rotation + this.animation * group.random));
            this.buffer.translate(0, -child.distance);

            this.buffer.beginPath();
            this.buffer.fillStyle = child.color;
            this.buffer.arc(0, 0, child.size, 0, 2*Math.PI, false);
            this.buffer.fill();

            renderRecursive(child);

            this.buffer.translate(0, child.distance);
            this.buffer.rotate(-(child.rotation + this.animation * group.random));
        }


        for (child in group.members) {
            this.buffer.rotate(child.rotation);
            this.buffer.translate(0, -child.distance);

            this.buffer.beginPath();
            this.buffer.fillStyle = this.rankColor(child.person.rank);
            this.buffer.arc(0, 0, child.size, 0, 2*Math.PI, false);
            this.buffer.fill();


            this.buffer.translate(0, child.distance);
            this.buffer.rotate(-child.rotation);
        }

    }

    public function render() {


        //Render vars
        var buffersize: Int = 1000; //Size of buffer image
        //Calculate point of zoom based on translation of the graph and the mouse position
        var _offsetX: Int = this.offsetX-200;
        var _offsetY: Int = this.offsetY;
        this.ctx.clearRect(0,0,this.ctx.canvas.width, this.ctx.canvas.height);

        this.ctx.translate((this.canvas.width - BUFFER_SIZE * this.zoom)  / 2 + _offsetX, (this.canvas.height - BUFFER_SIZE * this.zoom)  / 2  + _offsetY);
        this.ctx.scale(this.zoom, this.zoom);

        this.ctx.drawImage(this.buffer.canvas, 0, 0, BUFFER_SIZE, BUFFER_SIZE);

        this.ctx.scale(1/this.zoom, 1/this.zoom);
        this.ctx.translate(-((this.canvas.width - BUFFER_SIZE * this.zoom)  / 2 + _offsetX), -((this.canvas.height - BUFFER_SIZE * this.zoom)  / 2  + _offsetY));

    }

    public function update(elapsed: Float) {
        if (App.simulation == null) return;
        animation += this.animationSpeed * elapsed;

        this.renderBuffer();
        this.render();
    }


    private function rankColor(rank: Rank) : String {
        switch (rank) {

            case Rank.Neuling: return "IndianRed";
            case Rank.Knappe: return "Khaki";
            case Rank.Spaeher: return "GreenYellow";
            case Rank.Pfadfinder: return "MediumTurquoise";
            case Rank.Kornett: return "DodgerBlue";
            case Rank.Feldmeister: return "MediumBlue";
        }
        return "black";
    }

    private function onMouseScroll(e: WheelEvent) {
        if (e.wheelDelta < 0) {
            this.zoom *= 1 - this.SCROLL_SPEED;
        } else {
            this.zoom *= 1 + this.SCROLL_SPEED;
        }
    }

    private function onMouseMove(e: MouseEvent) {
        if (this.dragging) {
            this.offsetX = this.offsetStartX + (e.clientX - this.mouseStartX);
            this.offsetY = this.offsetStartY + (e.clientY - this.mouseStartY);

            this.render();
        }
    }
    private function onMouseUp(e: MouseEvent) {
        this.dragging = false;
    }    
    private function onMouseDown(e: MouseEvent) {
        this.dragging = true;

        this.mouseStartX = e.clientX;
        this.mouseStartY = e.clientY;
        this.offsetStartX = this.offsetX;
        this.offsetStartY = this.offsetY;
    }


    private function scale() {
        this.canvas.width = Browser.window.innerWidth;
        this.canvas.height = Browser.window.innerHeight;
    }

    //Display available json files, that can be loaded
    public function displayFiles(files: Array<String>) {
        var list: Element = Browser.document.getElementById("button-load-list");
        list.innerHTML = ""; //Empty list

        for (file in files) {
            var li: LIElement = Browser.document.createLIElement();
            li.onclick = function (e: MouseEvent) {this.onLoadListClick(file);};
            li.innerHTML =  "<a href='#'>"+file+"</a>";
            list.appendChild(li);
        }
    }

    public function displayConstants(fields: Map<String, Float>) {
                
        var ul: UListElement = Browser.document.createUListElement();

        for (field in fields.keys()) {
            var li: LIElement = Browser.document.createLIElement();
            li.innerHTML = "<label for=\"constant-"+field+"\">"+field+":</label>";

            var button: js.html.InputElement = Browser.document.createInputElement();
            button.className = "form-control";
            button.setAttribute("value", Std.string(fields.get(field)));
            button.id = "constant-"+field;
            button.onchange = function (e: js.html.EventListener) {
                App.setConstant(field, Std.parseFloat(button.value));
            };

            li.appendChild(button);
            ul.appendChild(li);
        }        
    
        Browser.document.getElementById("constants").appendChild(ul);
    }

    private function onLoadListClick(file: String) {
        App.load("data/" + file);
    }

    /* DOM-specific events */
    private function onWeekStart(week: Int) {
        //Update week display
        Browser.document.getElementById("now-week").innerHTML = Std.string((week + App.simulation.startWeek) % 52 + 1);
        Browser.document.getElementById("now-year").innerHTML = Std.string(Math.floor((week + App.simulation.startWeek) / 52) + App.simulation.startYear);
        var rounded: String = Std.string(Math.fround(week / 52 * 10));
        Browser.document.getElementById("delta-week").innerHTML = (rounded.charAt(1) == null ? "0" : rounded.charAt(0)) + "," + (rounded.charAt(rounded.length - 1))  + "j";
    }


    private function onUpdateGraph() {
        this.updateListGraph();
    }

    private function updateListGraph() {
        var list: UListElement = Browser.document.createUListElement();
        Browser.document.getElementById("graph-list").innerHTML = "";
        if (App.simulation != null ) {
            this.recursiveUpdateList(App.simulation.groups, list, this.STATISTIC_LEVEL_THRESHOLD);
            Browser.document.getElementById("graph-list").appendChild(list);
        }
    }
    private function recursiveUpdateList(group: Group, ul: UListElement, deepness: Int) {

        for (child in group.children) {
            var li: LIElement = Browser.document.createLIElement();
            li.innerHTML = child.name + "<span class=\"list-count\">" + child.count + "</span>";

            //Call children recursivly
            if (child.children.length != 0 && deepness > 1) {
                var newUL: UListElement = Browser.document.createUListElement();
                recursiveUpdateList(child, newUL, deepness-1);
                li.appendChild(newUL);
            }

            ul.appendChild(li);
        }

    }

    private function onKeyDown(e: KeyboardEvent) {
        if (e.keyCode == 32) {
            if (App.running) {
                App.pause();
            } else {
                App.start();
            }
            e.preventDefault();
        }
    }

    private function onStartClick(e: MouseEvent) {
        if (App.running) {
            App.pause();
        } else {
            App.start();
        }
        Browser.document.getElementById("start").blur();
    }

    private function onAppStart() {
        Browser.document.getElementById("start").className += " active";
        Browser.document.getElementById("start").innerHTML = "Pausieren";

        //Set start week display
        Browser.document.getElementById("start-week").innerHTML = Std.string(App.simulation.startWeek);
        Browser.document.getElementById("start-year").innerHTML = Std.string(App.simulation.startYear);
    }

    private function onAppPause() {
        Browser.document.getElementById("start").className = StringTools.replace(Browser.document.getElementById("start").className, " active","");
        Browser.document.getElementById("start").innerHTML = "Starten";
    }

    private function onAppLoad() {
        //Enable buttons
        Browser.document.getElementById("start").removeAttribute("disabled");
        Browser.document.getElementById("reset").removeAttribute("disabled");
    }

    private function onAppReset() {
        //Reset week displays
        Browser.document.getElementById("now-week").innerHTML = "-";
        Browser.document.getElementById("now-year").innerHTML = "-";
        Browser.document.getElementById("start-week").innerHTML = "-";
        Browser.document.getElementById("start-year").innerHTML = "-";
    }


    private function onResetClick(e: MouseEvent) {
        App.reset();
    }

}