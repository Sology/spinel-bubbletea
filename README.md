# spinel-bubbletea

The [bubbletea](https://github.com/marcoroth/bubbletea-ruby) gem (0.1.4) as a
[spin](https://github.com/matz/spinel/blob/master/docs/spin.md) package, so a
Spinel program can `require "bubbletea"` and run a terminal UI compiled to one
native binary.

## How it is built

The gem has three layers, and the package keeps each:

| Gem | Here |
|---|---|
| `go/` (Go over charmbracelet/x, built with cgo) | `go/`, unchanged; `spin.toml`'s `[[build]]` step runs `go build -buildmode=c-archive`, and the archive is linked statically |
| `ext/bubbletea/*.c` (the C extension) | `bubbletea.rb`'s `Native` (`ffi_func` bindings of the Go exports) and `Program`, plus `sp_bubbletea.c` for the calls that answer a Go-allocated string or out-parameters |
| `lib/bubbletea/*.rb` | `bubbletea.rb`, unchanged and in the gem's load order |

Departures from the gem are marked `SIMPLIFIED` in the source.

Building needs the Go toolchain (the `[[build]]` step) and, as any native
build step, consent: `spin build --allow-native-build`, `SPIN_ALLOW_NATIVE_BUILD=1`
or `spin trust bubbletea`.

## Tests

`test/*.rb` run without a terminal. Their `.expected` files are the real gem's
output under CRuby (`bundle exec ruby test/<name>.rb` with the gem installed),
not `spin test --regen`, which would run this port under CRuby, where `ffi_func`
does not exist.

`examples/counter.rb` needs a terminal. Driven under a pseudo-terminal with the
same keys, it prints byte-identical output with the gem under CRuby and as a
Spinel binary.

## License

MIT, as the gem (`LICENSE.txt`, Copyright (c) 2025 Marco Roth).
