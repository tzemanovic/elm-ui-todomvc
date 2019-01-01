# TodoMVC in Elm - [Try It!](TODO)

This is a fork of the original [TodoMVC][upstream-TodoMVC] that instead of [elm/html][html] and CSS relies on the [mdgriffith/elm-ui][elm-ui] package. All of the Elm code lives in `src/Main.elm`.

[upstream-TodoMVC]: https://github.com/evancz/elm-todomvc
[html]: https://package.elm-lang.org/packages/elm/html/latest
[elm-ui]: https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/

There also is a port handler set up in `index.html` to store the Elm application's state in `localStorage` on every update.


## Build Instructions

Run the following command from the root of this project:

```bash
elm make src/Main.elm --output=elm.js
```

Then open `index.html` in your browser!


## Hacking

Install [elm-live](https://github.com/wking-io/elm-live) and run:

```bash
elm-live src/Main.elm --open -- --output=elm.js
```
