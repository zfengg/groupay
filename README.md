# groupay

A simple interactive solution to group payment.

Why this script?

It solves the frequent but annoying payment issues in our life, especially after a trip with friends favoring a (partial) AA payment plan.

[![asciicast](https://asciinema.org/a/427746.svg)](https://asciinema.org/a/427746?t=7)

> Try it out @ [Repl.it](https://replit.com/@zfengg/groupay). It's fun!

## Usage
### Online by [Repl.it](https://replit.com/@zfengg/groupay)

https://user-images.githubusercontent.com/42152221/127734458-e71469d5-460f-4622-a779-f35235a76e64.mov

### Locally with [Julia](https://julialang.org/downloads/)

Clone this repo or download [groupay.jl](groupay.jl)

```bash
git clone https://github.com/zfengg/groupay.git
cd groupay
julia -iq groupay.jl
```

The local usage provides `save_paygrp()` and `load_paygrp()` to save and load workspace via [JLD2.jl](https://github.com/JuliaIO/JLD2.jl).
