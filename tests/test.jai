#import "Basic";
#import,file "../module.jai";

Track :: struct {
    name: string;
    stars: float;
}

Album :: struct {
    title: string;
    artist: *Artist;
    tracks: [] Track;
    explicit: bool;
}

Artist :: struct {
    name: string;
}

main :: () {
    artist := Artist.{name = "Chopin & Liszt"};
    tracks := Track.[.{"Nocturne", 2.5}, .{"Étude", 4}];
    album := Album.{title = "<Piano>", artist = *artist, tracks = tracks};

    result, ok := mustache_render("{{title}} by {{artist.name}}{{#tracks}} [{{name}} {{stars}} {{title}}]{{/tracks}}{{^explicit}} clean{{/explicit}}{{#missing}}x{{/missing}}", album);
    assert(ok);
    assert(result == "&lt;Piano&gt; by Chopin &amp; Liszt [Nocturne 2.5 &lt;Piano&gt;] [Étude 4 &lt;Piano&gt;] clean", "%", result);

    result, ok = mustache_render("{{{title}}}{{> part}}", album, (name: string, data: *void) -> string, bool {
        return copy_string(tprint("<%>", name)), true;
    });
    assert(ok);
    assert(result == "<Piano><part>", "%", result);

    result, ok = mustache_render("{{#tracks}}", album);
    assert(!ok);
}
