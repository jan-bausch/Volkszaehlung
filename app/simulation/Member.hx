package app.simulation;

import app.simulation.Node;
import app.simulation.Person;

class Member extends Node {

    public var person: Person;

    public var isCopy: Bool = false;

    public function new(person: Person) {
        super();
        this.person = person;

        this.size = Node.minSize;
    }

}