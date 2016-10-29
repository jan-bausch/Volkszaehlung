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
    public var dir: String = "../import/";

    private var data: JsonRoot;

    private static var colorMap: Map<String, String> = [
        "IV" => "rgba(131,80,46,0.8)",
        "Parzival" => "rgba(34,139,34,0.8)",
        "Ulrich von Hutten" => "rgba(161,0,0,0.8)",
        "I" => "rgba(24,48,216,0.8)",
        "Philipp Melanchthon" => "rgba(131,80,46,0.8)",
        "Martin Luther" => "rgba(131,80,46,0.8)",
        "Ulrich Zwingli" => "rgba(131,80,46,0.8)",
    ];

    private static var rankMap: Map<String, Int> = [
        "Wö" => 0,
        "N" => 0,
        "Kn" => 1,
        "Knappe" => 1,
        "Sp" => 2,
        "SP" => 2,
        "Späher" => 2,
        "P" => 3,
        "Pf" => 3,
        "aP" => 3,
        "Kt" => 4,
        "Fm" => 5
    ];

    public function runDefault() {
        if (out == null) out = "../build/data/" + Std.string(Date.now().getFullYear())+"-"+Std.string(Date.now().getMonth()+1)+"-"+Std.string(Date.now().getDate())+".json";


        //Write basic json data
        this.data = {
                    year: Date.now().getFullYear(),
                    week: Date.now().getMonth() * 4,
                    groups: new Array<JsonGroup>()
                    };          

        //Go through files
        for (path in FileSystem.readDirectory(dir)) {
            if (Path.extension(path) != "csv") continue;
            this.readFile(path);
        }

        //Save json
        Sys.println("------");
        Sys.println("...Exporting to: \"" + out +"\"");
        //Stringfy json with indentation
        var jsonString: String = Json.stringify(this.data, null, "\t");
        //Saving
        File.saveContent(out, jsonString);
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

        Sys.println("Reading Stamm " + stamm + ", Sippe " + sippe);

        //Get stamm reference
        var stammJson: JsonGroup = this.addStamm(stamm);

        //Add sippe
        var sippeJson: JsonGroup =  {
                                    name: sippe,
                                    color: this.getColor(sippe),
                                    children: new Array<JsonGroup>(),
                                    members: new Array<JsonPerson>()
                                    };
        stammJson.children.push(sippeJson);

        //Read members
        var i: Int = 12;
        while (i<rows.length) {
            var cells: Array<String> = rows[i].split(";");
            if (cells.length < 2) break;

            //Read cell information of member
            var name: String = cells[0];
            var age: Int = Std.parseInt(cells[1]);
            var rank: String = cells[2];
            var groups: Array<String> = StringTools.replace(StringTools.replace(cells[3], " ", ""), "\r", "").split(",");

            var personJson: JsonPerson =    {
                                            name: name,
                                            rank: this.getRank(rank),
                                            age: 12
                                            };

            for (gruppeName in groups) {
                var gruppeJson: JsonGroup = this.addGruppe(gruppeName, sippeJson);
                gruppeJson.members.push(personJson);
            }

            i++;
        }
    }

    //Returns reference of json-data of stamm. Adds stamm, if it doesn't exist yet
    private function addStamm(name: String) : JsonGroup {
        var reference: JsonGroup = null;
        for (stamm in this.data.groups) if (stamm.name == name) reference = stamm;

        //If it doesn't exist yet, create
        if (reference == null) {
            reference = {
                        name: name,
                        color: this.getColor(name),
                        children: new Array<JsonGroup>(),
                        members: new Array<JsonPerson>()
                        };
            this.data.groups.push(reference);
        }

        return reference;
    }


    //Returns reference of json-data of gruppe. Adds gruppe to sippe, if it doesn't exist yet
    private function addGruppe(name: String, sippe: JsonGroup) : JsonGroup {
        var reference: JsonGroup = null;
        for (group in sippe.children) if (group.name == name) reference = group;

        //If it doesn't exist yet, create
        if (reference == null) {
            reference = {
                        name: name,
                        members: new Array<JsonPerson>()
                        };
            sippe.children.push(reference);
        }

        return reference;
    }

    private function getRank(name: String) : Int {
        var rank: Null<Int> = Importer.rankMap.get(name);
        if (rank == null) {
            trace("Unknown rank identifier: \"" + name + "\"");
            return -1;
        } else {
            return rank;
        }
    }

    //Returns color-code of group
    private function getColor(name: String) : String {
        var color: Null<String> = Importer.colorMap.get(name);
        if (color == null) {
            trace("Unknown color identifier: \"" + name + "\"");
            return "null";
        } else {
            return color;
        }
    }

    public function help() {
        Sys.println(this.showUsage());
    }

    public static function main() {
        new mcli.Dispatch(Sys.args()).dispatch(new Importer());
    }

}
