package app.simulation;

import app.simulation.Person;
import app.simulation.Node;
import app.simulation.Member;
import app.simulation.Helpers;
import app.simulation.Probability;

class Group extends Node{

    public var parent: Null<Group>;
    public var children: Array<Group>;
    public var members: Array<Member>;
    public var level: Int;

    public var totalCount(get, never): Int;
    public var count(get, never): Int;
    public var startCount: Int;

    public var name: String;
    public var color: String;
    public var random: Float;
    //As long as this number is above 0, this group attracts new members
    public var youngness: Int = 0;

    public function new(name: String, color: Null<String> = "rgba(230,240,242, 0.1)") {
        super();
        this.name = name;
        this.color = (color == null) ? "rgba(230,240,242, 0.1)" : color;
        this.parent = null;
        this.level = 0;

        this.calculateRandom();


        this.children = new Array<Group>();
        this.members = new Array<Member>();
    }

    public function addGroup(group: Group) {
        group.parent = this;
        group.level = this.level + 1;
        this.children.push(group);

        this.calculatePosition();
    }

    public function removeGroup(group: Group) {
        this.children.remove(group);
        group.parent = null;
        group.level = -1;

        if (this.members.length == 0 &&  this.children.length == 0 && this.parent != null)
            this.parent.removeGroup(this);

        this.calculatePosition();
    }

    public function addMember(member: Member) {
        this.members.push(member);
        member.person.groups.push(this);
        this.calculatePosition();
    }

    public function removeMember(person: Person) {

        for (member in this.members) {
            if (member.person == person) {
                this.members.remove(member);
                person.groups.remove(this);

                if (this.members.length == 0 &&  this.children.length == 0 && this.parent != null)
                    this.parent.removeGroup(this);

                this.calculatePosition();

            }
        }

    }  

    private function get_count() : Int {
        var i: Int = 0;

        for (member in this.members) {
            if (!member.isCopy) i++;
        }
        for (child in this.children) {
            i += child.get_count();
        }

        return i;
    }

    private function get_totalCount() : Int {
        var i: Int = this.members.length;

        for (child in this.children) {
            i += child.get_totalCount();
        }

        return i;
    }

    public function simulate() {

        //Simulate startphase of group
        if (this.youngness > 0) {
            for (i in 0...this.youngness) {
                if (Probability.probability(Probability.GRUPPE_EINSTIEG)) {
                    Person.create().enterGroup(this);
                }
            }
            this.youngness--;
        }

        for (member in this.members) {
            if (!member.isCopy) member.person.simulate();
        }
        for (child in this.children) {
            child.simulate();
        }
    }

    private function calculatePosition() {

        //Calculate angle (circe divided in equal parts)
        var _count: Float = (this.members.length  + this.children.length);
        //No members and children
        if (_count == 0) {
            this.size = 100;
            //Bubble up
            if (this.parent != null) parent.calculatePosition();
        }

        //Find largest member
        var _size: Float = Node.minSize;
        for (child in this.children) {
            if (_size < child.size) _size = child.size;
        }
        
        //Calculate radius
        var _radius: Float = _size * (_count - 1) / (Math.pow(_count, 0.25) * Node.radius);
        if (_count == 2) _radius = _size  + Node.margin;
        if (_count == 3) _radius = _size * 1.5  + Node.margin;

        this.size = (_radius + _size) * Node.margin;

        //Inform children
        var n: Int = 0;

        for (child in this.children) {
            child.distance = _radius;
            child.rotation = 2 * Math.PI / _count * n;
            n++;
        }

        for (member in this.members) {
            member.distance = _radius;
            member.rotation = 2 * Math.PI / _count * n;
            n++;
        }


        //Bubble up
        if (this.parent != null) parent.calculatePosition();
    }

    public function getRankCount(rank: Rank, excludeMembersOf2Groups = false) : Int {
        var count: Int = 0;
        for (member in this.members) {
            if (excludeMembersOf2Groups && member.person.groups.length > 2) continue;
            if (member.person.rank == rank)count++;
        }
        return count;
    }

    public function findPartners(person: Person) : Array<Person> {
        var partners: Array<Person> = new Array<Person>();
        var count: Int = 0; //Minimal optimal count of Gruppenführer
        var potential: Int = this.getRankCount(Rank.Feldmeister, true) + this.getRankCount(Rank.Kornett, true); //Potential list of Gruppenführer

        if (potential <= 2) {
            count = 1;
        } else if (potential <= 4) {
            count = 2;
        } else {
            count = 3;
        }

        for (member in this.members) {
            //Skip if person is original person or if not a Gruppenführer
            if ( !(member.person.rank == Rank.Feldmeister || member.person.rank == Rank.Kornett)|| member.person == person) continue;
            if (count > 0) {
                partners.push(member.person);
                count--;
            }
        }
        return partners;
    }

    private function calculateRandom() {

        //TODO: add better seed
        var seed: Float = Helpers.seed(this.name);

        if (seed < 0.5)
            seed = -1 + seed;

        this.random = seed;
    }

}