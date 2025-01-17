const Entity = @import("entt").Entity;

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
