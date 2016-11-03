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
        "I" => "rgba(4,127,8,0.8)",
        "Philipp Melanchthon" => "green",
        "Martin Luther" => "blue",
        "Ulrich Zwingli" => "white",

        "II" => "rgba(87, 127, 170,0.8)",
        "Volker" => "blue",
        "Siegfried" => "red",
        "Wulfila" => "brown",

        "III" => "rgba(215, 26, 44, 0.8)",
        "Armin" => "green",     

        "IV" => "rgba(131,80,46,0.8)",
        "Parzival" => "rgba(34,139,34,0.8)",
        "Ulrich von Hutten" => "rgba(161,0,0,0.8)",

        "V" => "rgba(0, 0, 0,0.8)",
        "Hans Scholl" => "green",

        "VI" => "rgba(255,255,255,0.7)",
        "Zinzendorf" => "green",
        "Dietrich Bonhoeffer" => "black",
        "Dietrich von Bern" => "red",

        "VII" => "rgba(255, 104, 0,0.7)",
        "Oranien" => "green",
        "Wilhelmus" => "blue",
        "Paul Schneider" => "red",
        "Albert Schweitzer" => "black",
    ];

    private static var rankMap: Map<String, Int> = [
        "Wö" => 0,
        "Wölfling" => 0,
        "wölfling" => 0,
        "N" => 0,
        "Neuling" => 0,
        "neuling" => 0,
        "Kn" => 1,
        "K" => 1,
        "Knappe" => 1,
        "Sp" => 2,
        "SP" => 2,
        "Späher" => 2,
        "P" => 3,
        "p" => 3,
        "Pf" => 3,
        "Kt" => 4,
        "kt" => 4,
        "Kt (zbV)" => 4,
        "zbV" => 4,
        "aP" => 4,
        "Fm" => 5,
        "fm" => 5,
        "Fm (zbV)" => 5,
        "Fm/Lstf" => 5
    ];

    private static var blacklistGroup: Array<String> = [
        "zbV", "", "ZbV"
    ];

    private static var stammMap: Array<String> = [
        "I", "II", "III", "IV", "V", "VI", "VII"
    ];

    public function runDefault() {
        if (out == null) out = "../build/data/" + Std.string(Date.now().getFullYear())+"-"+Std.string(Date.now().getMonth()+1)+"-"+Std.string(Date.now().getDate())+".json";


        //Write basic json data
        this.data = {
                    year: Date.now().getFullYear(),
                    week: Date.now().getMonth() * 4,
                    groups: new Array<JsonGroup>()
                    };          

        var paths: Array<String> = FileSystem.readDirectory(dir);

        //Go through files
        for (path in paths) {
            if (Path.extension(path) != "csv") continue;
            this.readFile(path);
        }

        //Order by roman notation
        this.data.groups.sort( function(a: JsonGroup, b: JsonGroup) {
            return stammMap.indexOf(a.name) - stammMap.indexOf(b.name);
        });

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
        var lastAge: Int = -1;
        while (i<rows.length) {
            var cells: Array<String> = rows[i].split(";");
            if (cells.length < 2) break;

            //Read cell information of member
            var name: String = cells[0];
            var age: String = cells[1];
            var rank: String = cells[2];
            var groups: Array<String> = StringTools.replace(StringTools.replace(cells[3], " ", ""), "\r", "").split(",");

            var _age: Int = this.getAge(age);
            //If age is not set, copy from last iteration
            if (_age == -1) _age = lastAge;
            lastAge = _age; 


            var personJson: JsonPerson =    {
                                            name: name,
                                            rank: this.getRank(rank),
                                            age: this.getAge(age)
                                            };

            for (gruppeName in groups) {
                if (blacklistGroup.indexOf(gruppeName) != -1) continue;
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
        name = StringTools.trim(name);
        var rank: Null<Int> = Importer.rankMap.get(name);
        if (rank == null) {
            trace("Unknown rank identifier: \"" + name + "\"");
            return -1;
        } else {
            return rank;
        }
    }

    private function getAge(age: String) : Int {
        var year: Int = (age.indexOf(".") == -1) ? Std.parseInt(age) : Std.parseInt(age.split(".")[2]);

        if (year == null) {
            trace("Unknown age identifier: \"" + age + "\", copying age");
            return -1;
        }

        return Date.now().getFullYear() - year;
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
