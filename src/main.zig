const std = @import("std");
const Registry = @import("entt").Registry;

const arch = @import("arch.zig");

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

const c = @import("components.zig");
const co = @import("colours.zig");
const Engine = @import("Engine.zig").Engine;
const EventManager = @import("console.zig").EventManager;
const GameMap = @import("GameMap.zig").GameMap;
const input_handlers = @import("input_handlers.zig");
const procgen = @import("procgen.zig");
const Terminal = @import("Terminal.zig").Terminal;

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
    var map = try GameMap.init(allocator, 80, 43);
    var start = c.Position{ .x = 0, .y = 0 };
    try procgen.generate_dungeon(&reg, rand, &map, 10, 6, 30, 2, &start);

    var engine = try Engine.init(allocator, events, map, &reg, term);

    const player = reg.create();
    reg.add(player, start);
    reg.add(player, c.Glyph{
        .ch = '@',
        .colour = co.White,
        .order = c.RenderOrder.Actor,
    });
    reg.add(player, c.Fighter{ .hp = 30, .max_hp = 30, .defense = 2, .power = 5 });
    engine.setPlayer(player);

    try engine.message_log.add("Hello and welcome, adventurer, to yet another dungeon!", co.WelcomeText, false);

    try engine.render();
    return engine;
}

pub export fn tick(engine: *Engine) void {
    engine.tick() catch {};
}
