pub const Action = union(enum) {
    escape: bool,
    movement: struct { dx: i8, dy: i8 },
};
