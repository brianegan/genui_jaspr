# Contributing

Issues and pull requests: https://github.com/brianegan/genui_jaspr

## Tests

```sh
dart test                          # the package
dart test -p chrome test/browser   # the browser-only tests, needs Chrome
cd example && dart test            # the example, including a real HTTP round trip
```

The example's round-trip test starts a real server and drives the real route with
a stand-in for the model, so everything between browser and model is covered
without a key. Only the model call itself needs one.

### Why browser tests exist

The browser tests are marked `@TestOn('browser')`, so the plain `dart test` run
skips them. They exist because two hops cannot be reached from the VM: a real
keystroke in a real input element reaching the data model, and a real click on a
generated button. Deleting a field's `onInput` handler passes every VM test and
fails there.

### Example coverage

The example is a separate workspace member, so a root `dart test` does not reach
it. Its `tool/coverage.sh` script runs the VM suite, the browser suite for
`chat.dart`, and merges the two coverage reports. CI holds the merged number at
100%.
