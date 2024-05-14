# Zig Roguelike

As usual I'm following https://rogueliketutorials.com/tutorials/tcod/v2/ but I won't be using `libtcod`, instead opting to write my own library as I go along. I'm sure that won't be a bad idea.

## Installation

I recommend using [zigup](https://github.com/marler8997/zigup) to get an exact zig version, as development is still very active and things change a _lot_.

- `zigup run 0.12.0-dev.2330+9e684e8d1 build run`

## ECS

I'm using a [zig port of EnTT](https://github.com/prime31/zig-ecs) which doesn't compile under `0.12.0` but does work with `0.12.0-dev.2330+9e684e8d1`. There is a single-line patch that would fix this issue in `src/signals/delegate.zig`.
