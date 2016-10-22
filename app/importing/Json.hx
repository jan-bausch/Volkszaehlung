package app.importing;

typedef JsonPerson= {
    var name: String;
    var age: Int;
    var rank: Int;
}

typedef JsonGroup = {
    @:optional var children: Null<Array<JsonGroup>>;
    var members: Null<Array<JsonPerson>>;
    var name: String;
    @:optional var color: Null<String>;
}

typedef JsonRoot = {
    var groups: Array<JsonGroup>;
    var year: Int;
    var week: Int;
}