package app;

import haxe.Json;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import mcli.CommandLine;
import app.importing.Json;

/**
    Import .csv-Excel files to .json for the volkszaehlung-app
**/
class Importer extends CommandLine {

    /**
        Output file (default: ../build/data/<date>.json)
    **/
    public var out: String;

    /**
        Input directory (default: /)
    **/
    public var dir: String = "";

    private var data: JsonRoot;

    public function runDefault() {
        if (out == null) out = "../build/data/" + Std.string(Date.now().getFullYear())+"-"+Std.string(Date.now().getMonth())+"-"+Std.string(Date.now().getDate())+".json";

        //
        for (path in FileSystem.readDirectory(dir)) {
            if (Path.extension(path) != "csv") continue;
            this.readFile(path);
        }

        //Save json
        Sys.println("------");
        Sys.println("...Exporting to: \"" + FileSystem.absolutePath(out) +"\"");

    }

    //Read content of file
    private function readFile(path: String) {
        var content: String = File.getContent(path);
        //Parse stamm from filename
        var stammRegex: EReg = ~/_([A-Za-z]{1,3})_/;
        stammRegex.match(new Path(path).file);
        var stamm: String = stammRegex.matched(1);

        //Parse cells
        var rows: Array<String> = content.split("\n");

        //Read full name of sippe
        var sippe: String = rows[9].split(";")[1];

        //Read members
        var i: Int = 12;
        while (i<rows.length) {
            var cells: Array<String> = rows[i].split(";");
            if (cells.length < 2) break;
            Sys.println(cells[0]);
            i++;
        }
    }




    public function help() {
        Sys.println(this.showUsage());
    }

    public static function main() {
        new mcli.Dispatch(Sys.args()).dispatch(new Importer());
    }

}
