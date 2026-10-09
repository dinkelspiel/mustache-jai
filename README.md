# mustach-jai

Jai bindings for [mustach](https://gitlab.com/jobol/mustach) 1.2.9, a small C implementation of the [Mustache](https://mustache.github.io) template language. The source of the mustach core is vendored in `src` and built as a static library.

## Generate

From this directory:

    jai-linux generate.jai

## Use

Load `module.jai`, then render a template against any Jai value:

    html, ok := mustache_render_file("templates", "page.html", page);

Names are looked up as struct members (including `using` members), pointers are followed and arrays are iterated by sections. Values are HTML escaped unless written with `{{{triple}}}` or `{{&ampersand}}` tags. `mustache_render_file` loads partials relative to the same directory, `mustache_render` takes a template string and an optional partial loader.
