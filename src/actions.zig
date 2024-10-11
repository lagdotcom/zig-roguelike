pub const Action = union(enum) {
    escape: void,
    wait: void,
    movement: struct { dx: i8, dy: i8 },
};
