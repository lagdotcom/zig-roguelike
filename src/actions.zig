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

    cancel_menu: void,
    show_use_inventory: void,
    use_from_inventory: struct { index: usize },
    show_drop_inventory: void,
    drop_from_inventory: struct { index: usize },
};
