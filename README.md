# TodoMVC in Elm - [Try It!](https://tzemanovic.github.io/elm-ui-todomvc)

This is a fork of the original [TodoMVC][upstream-TodoMVC] that instead of [elm/html][html] and CSS relies on the [mdgriffith/elm-ui][elm-ui] package. All of the Elm code lives in `src/Main.elm`.

[upstream-TodoMVC]: https://github.com/evancz/elm-todomvc
[html]: https://package.elm-lang.org/packages/elm/html/latest
[elm-ui]: https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/

There also is a port handler set up in `index.html` to store the Elm application's state in `localStorage` on every update.


## Build Instructions

Run the following command from the root of this project to build optimized output and compress using [uglifyjs](https://www.npmjs.com/package/uglify-js):

```bash
elm make src/Main.elm --optimize --output=elm.js
uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=elm.min.js
```

Then open `index.html` in your browser!


## Hacking

Install [elm-live](https://github.com/wking-io/elm-live) and run:

```bash
elm-live src/Main.elm --open -- --output=elm.min.js
```
