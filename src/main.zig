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

    const stderr = arch.get_stderr().writer();
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

    if (arch.run_forever) {
        defer engine.deinit();
        try engine.run();
    } else {
        arch.ready(&engine);
    }
}

fn setup() !Engine {
    const term = try Terminal.init(arch.get_stdout(), "Ziglike");

    const events = try EventManager.init(allocator, 100, arch.get_stdin());

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try arch.get_random(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    var reg = Registry.init(allocator);
    var map = try GameMap.init(allocator, 80, 43);
    var start = c.Position{ .x = 0, .y = 0 };
    try procgen.generate_dungeon(
        &reg,
        rand,
        &map,
        10,
        6,
        30,
        2,
        2,
        &start,
    );

    var engine = try Engine.init(allocator, events, map, &reg, term);

    const player = reg.create();
    reg.add(player, start);
    reg.add(player, c.Glyph{
        .ch = '@',
        .colour = co.white,
        .order = c.RenderOrder.Actor,
    });
    reg.add(player, c.Fighter{ .hp = 30, .max_hp = 30, .defence = 2, .power = 5 });
    reg.add(player, c.Inventory{ .capacity = 26 });
    engine.set_player(player);

    try engine.message_log.add("Hello and welcome, adventurer, to yet another dungeon!", co.welcome_text, false);

    try engine.render();
    return engine;
}

pub export fn tick(engine: *Engine) void {
    engine.tick() catch {};
}
