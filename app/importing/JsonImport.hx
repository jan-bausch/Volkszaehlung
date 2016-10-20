package app.importing;

import app.App;
import app.simulation.Group;
import app.simulation.Person;
import app.simulation.Member;

import haxe.Http;
import haxe.Json;


typedef JsonPerson= {
    var name: String;
    var age: Int;
    var rank: Int;
}

typedef JsonGroup = {
    var children: Null<Array<JsonGroup>>;
    var members: Null<Array<JsonPerson>>;
    var name: String;
    var color: Null<String>;
}

typedef JsonRoot = {
    var groups: Array<JsonGroup>;
    var year: Int;
    var week: Int;
}

class JsonImport {


    private static var persons: Map<String, Person>;

    public static function importJson(path: String) {
        
        //request data
        var json:JsonRoot = Json.parse(Http.requestUrl(path));
        
        persons = new Map<String, Person>();

        App.simulation.startWeek = json.week;
        App.simulation.startYear = json.year;

        parse(json.groups, App.simulation.groups);
    }

    private static function parse(groups: Array<JsonGroup>, root: Group) {

        for (group in groups) {


            var newgroup = new Group(group.name, group.color);

            if (group.children != null) parse(group.children, newgroup);

            if (group.members != null) {
                for (newmember in group.members) {

                    newgroup.addMember( getPersonReference(newmember.name, newmember.age, newmember.rank) );
                }
            }


            root.addGroup(newgroup);

        }

    }

    private static function getPersonReference(name: String, age: Int, rank: Int) : Member {

        if (persons.exists(name)) {
            var person: Person = persons.get(name);
            var member: Member = new Member(person);
            member.isCopy = true;
            return member;
        } else {
            var person: Person = new Person(name, age, toRank(rank));
            persons.set(name, person);
            return new Member(person);
        }

    }

    private static function toRank(integer: Int) : Rank {
        switch (integer) {
            case 0: return Rank.Neuling;
            case 1: return Rank.Knappe;
            case 2: return Rank.Spaeher;
            case 3: return Rank.Pfadfinder;
            case 4: return Rank.Kornett;
            case 5: return Rank.Feldmeister;
        }
        return Rank.Neuling;
    }

}