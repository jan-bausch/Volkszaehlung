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

    public function new(canvasId: String) {

        this.canvas = cast Browser.document.getElementById(canvasId);
        this.ctx = this.canvas.getContext2d();

        this.canvas.onmousemove = this.onMouseMove;
        this.canvas.onmousedown = this.onMouseDown;
        this.canvas.onmouseup = this.onMouseUp;
        this.canvas.onmousewheel = this.onMouseScroll;

        this.zoom = 0.5;
        this.offsetX = -200;
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

        Browser.document.getElementById("start").onclick = this.onStartClick;
        Browser.document.getElementById("reset").onclick = this.onStopClick;
        Browser.document.onkeypress = this.onKeyDown;

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


        //Render buffer
        var buffersize: Int = 1000;
        this.ctx.clearRect(0,0,this.ctx.canvas.width, this.ctx.canvas.height);

        this.ctx.translate((this.canvas.width - BUFFER_SIZE * this.zoom)  / 2 + this.offsetX, (this.canvas.height - BUFFER_SIZE * this.zoom)  / 2  + this.offsetY);
        this.ctx.scale(this.zoom, this.zoom);

        this.ctx.drawImage(this.buffer.canvas, 0, 0, BUFFER_SIZE, BUFFER_SIZE);

        this.ctx.scale(1/this.zoom, 1/this.zoom);
        this.ctx.translate(-((this.canvas.width - BUFFER_SIZE * this.zoom)  / 2 + this.offsetX), -((this.canvas.height - BUFFER_SIZE * this.zoom)  / 2  + this.offsetY));

    }

    public function update(elapsed: Float) {
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

    /* DOM-specific events */
    private function onWeekStart(week: Int) {
        Browser.document.getElementById("now-week").innerHTML = Std.string(week % 52 + App.simulation.startWeek);
        Browser.document.getElementById("now-year").innerHTML = Std.string(Math.floor(week / 52) + App.simulation.startYear);
    }


    private function onUpdateGraph() {
        this.updateListGraph();
    }

    private function updateListGraph() {
        var list: UListElement = Browser.document.createUListElement();
        this.recursiveUpdateList(App.simulation.groups, list);
        Browser.document.getElementById("graph-list").innerHTML = "";
        Browser.document.getElementById("graph-list").appendChild(list);
    }
    private function recursiveUpdateList(group: Group, ul: UListElement) {

        for (child in group.children) {
            var li: LIElement = Browser.document.createLIElement();
            li.innerHTML = child.name + "<span class=\"list-count\">" + child.count + "</span>";

            //Call children recursivly
            if (child.children.length != 0) {
                var newUL: UListElement = Browser.document.createUListElement();
                recursiveUpdateList(child, newUL);
                li.appendChild(newUL);
            }

            ul.appendChild(li);
        }

    }

    private function onKeyDown(e: KeyboardEvent) {
        if (e.keyCode == 32) {
            if (App.running) {
                App.pause();
                Browser.document.getElementById("start").className = StringTools.replace(Browser.document.getElementById("start").className, " active","");
                Browser.document.getElementById("start").innerHTML = "Starten";
            } else {
                App.start();
                Browser.document.getElementById("start").className += " active";
                Browser.document.getElementById("start").innerHTML = "Pausieren";
            }
        }
    }

    private function onStartClick(e: MouseEvent) {
        if (App.running) {
            App.pause();
            Browser.document.getElementById("start").className = StringTools.replace(Browser.document.getElementById("start").className, " active","");
            Browser.document.getElementById("start").innerHTML = "Starten";
        } else {
            App.start();
            Browser.document.getElementById("start").className += " active";
            Browser.document.getElementById("start").innerHTML = "Pausieren";
        }
        Browser.document.getElementById("start").blur();
    }

    private function onStopClick(e: MouseEvent) {

    }

}