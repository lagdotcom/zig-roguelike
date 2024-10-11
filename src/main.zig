const arch = @import("arch.zig");
const std = @import("std");

pub const std_options = .{
    .log_level = .info,
    .logFn = myLogFn,
};

pub fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;

    const stderr = arch.getStdErr().writer();
    stderr.print(format, args) catch {};
}

const Registry = @import("entt").Registry;

const EventManager = @import("console.zig").EventManager;

const input_handlers = @import("input_handlers.zig");
const Terminal = @import("Terminal.zig").Terminal;

const colours = @import("colours.zig");

const components = @import("components.zig");
const Glyph = components.Glyph;
const Position = components.Position;

const Engine = @import("Engine.zig").Engine;

const GameMap = @import("GameMap.zig").GameMap;
const procgen = @import("procgen.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

pub fn main() !void {
    var engine = try setup();

    if (arch.runForever) {
        defer engine.deinit();
        try engine.run();
    } else {
        arch.ready(&engine);
    }
}

fn setup() !Engine {
    const term = try Terminal.init(arch.getStdOut(), "Ziglike");

    const events = try EventManager.init(allocator, 100, arch.getStdIn());

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try arch.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var reg = Registry.init(allocator);
    var map = try GameMap.init(allocator, 80, 45);
    var start = Position{ .x = 0, .y = 0 };
    try procgen.generate_dungeon(&reg, rand, &map, 10, 6, 30, 2, &start);

    var engine = Engine.init(events, map, &reg, term);

    const player = reg.create();
    reg.add(player, start);
    reg.add(player, Glyph{ .ch = '@', .colour = colours.White });
    engine.setPlayer(player);

    try engine.render();
    return engine;
}

pub export fn tick(engine: *Engine) void {
    engine.tick() catch {};
}
