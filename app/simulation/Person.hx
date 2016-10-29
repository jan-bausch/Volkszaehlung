package app.simulation;

import app.simulation.Group;
import app.simulation.Member;
import app.simulation.Probability;
import app.simulation.Helpers;

enum Rank{
    Neuling;
    Knappe;
    Spaeher;
    Pfadfinder;
    Kornett;
    Feldmeister;
}

class Person {

    public var name: String;
    public var age: Int; //Detailled age in weeks for simulation
    public var groups: Array<Group>;
    public var rank: Rank;
    
    public function new(name: String, age: Int, rank: Rank) {
        this.name = name;
        //Calculate week age with random week modifier
        this.age = age * 52 + Std.int(52 * Helpers.seed(name)) - 26;
        this.rank = rank;
        this.groups = new Array<Group>();
    }

    /*
     * Returns a new instance of a person
     */
    public static function create() : Person {
        return new Person("Unnamed", Probability.GRUPPE_EINSTIEGSALTER, Rank.Neuling);
    }

    public function simulate() {

        switch (this.rank) {

            case Rank.Neuling:

                if (Probability.probability(Probability.AUSTRITT_NEULING)) {
                    this.remove();
                    return;
                }
                if (Probability.probability(Probability.AUFSTIEG_NEULING(this.age, this.groups[0].getRankCount(Rank.Knappe) ))) {
                    this.rank = Rank.Knappe;
                }

            case Rank.Knappe:

                if (Probability.probability(Probability.AUSTRITT_KNAPPE)) {
                    this.remove();
                    return;
                }
                if (Probability.probability(Probability.AUFSTIEG_KNAPPE(this.age, this.groups[0].getRankCount(Rank.Spaeher) ))) {
                    this.rank = Rank.Spaeher;
                }

            case Rank.Spaeher:

                if (Probability.probability(Probability.AUSTRITT_SPAEHER)) {
                    this.remove();
                    return;
                }
                if (Probability.probability(Probability.AUFSTIEG_SPAEHER(this.age, this.groups[0].getRankCount(Rank.Pfadfinder) ))) {
                    this.rank = Rank.Pfadfinder;
                }

            case Rank.Pfadfinder:

                if (Probability.probability(Probability.AUSTRITT_PFADFINDER)) {
                    this.remove();
                    return;
                }
                if (Probability.probability(Probability.AUFSTIEG_PFADFINDER(this.age))) {
                    this.rank = Rank.Kornett;
                }

            case Rank.Kornett:

                if (Probability.probability(Probability.AUSTRITT_KORNETT)) {
                    this.remove();
                    return;
                }
                if (Probability.probability(Probability.AUFSTIEG_KORNETT(this.age))) {
                    this.rank = Rank.Feldmeister;
                }

                //Person wands to found group
                if (Probability.probability(Probability.GRUPPE_GRUENDEN)) {
                    trace("grup");
                    //Search for partners and found group
                    this.foundGroup(this.groups[0].findPartners(this));
                }

            case Rank.Feldmeister:

                if (Probability.probability(Probability.AUSTRITT_FELDMEISTER)) {
                    this.remove();
                    return;
                }

        }

        this.age++;
    }

    public function foundGroup(partners: Array<Person>) {
        //Add new group in Sippe
        var newGroup: Group = new Group("Unnamed");
        this.groups[0].parent.addGroup(newGroup);

        //Add partners to the group
        this.enterGroup(newGroup);
        for (partner in partners) partner.enterGroup(newGroup);

        //Declare group as "young" so that it attracts new members
        newGroup.youngness = Probability.GRUPPE_WERBEPHASE;

    }

    public function enterGroup(group: Group) {
        var newMember: Member = new Member(this);
        if (this.groups.length > 0) newMember.isCopy = true;
        group.addMember(newMember);
    }

    public function remove() {
        for (group in this.groups) {
            group.removeMember(this);
        }
    }

}