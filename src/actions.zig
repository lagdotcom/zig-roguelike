const Entity = @import("entt").Entity;

const c = @import("components.zig");
const colours = @import("colours.zig");
const combat = @import("combat.zig");
const Engine = @import("Engine.zig").Engine;

pub const Action = union(enum) {
    escape: void,
    wait: void,
    movement: struct { dx: i8, dy: i8 },
    pickup: void,
    use: struct { item: Entity },
};
