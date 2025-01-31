const Action = @import("actions.zig").Action;
const windows = @import("arch/windows.zig");

pub fn in_dungeon(event: windows.KEY_EVENT_RECORD_W) ?Action {
    // ignore keyup events
    if (event.bKeyDown == 0) return null;

    return switch (event.wVirtualKeyCode) {
        .Left => .{ .movement = .{ .dx = -1, .dy = 0 } },
        .Up => .{ .movement = .{ .dx = 0, .dy = -1 } },
        .Right => .{ .movement = .{ .dx = 1, .dy = 0 } },
        .Down => .{ .movement = .{ .dx = 0, .dy = 1 } },

        .Escape => .escape,

        .Numpad5 => .wait,
        .Clear => .wait,

        .KeyG => .pickup,
        .KeyI => .show_use_inventory,
        .KeyD => .show_drop_inventory,

        else => null,
    };
}

const key_a_value = @intFromEnum(windows.VIRTUAL_KEY.KeyA);

pub fn use_from_inventory(event: windows.KEY_EVENT_RECORD_W) ?Action {
    // ignore keyup events
    if (event.bKeyDown == 0) return null;

    return switch (event.wVirtualKeyCode) {
        .Escape => .cancel_menu,

        .KeyA, .KeyB, .KeyC, .KeyD, .KeyE, .KeyF, .KeyG, .KeyH, .KeyI, .KeyJ, .KeyK, .KeyL, .KeyM, .KeyN, .KeyO, .KeyP, .KeyQ, .KeyR, .KeyS, .KeyT, .KeyU, .KeyV, .KeyW, .KeyX, .KeyY, .KeyZ => .{
            .use_from_inventory = .{ .index = @intFromEnum(event.wVirtualKeyCode) - key_a_value },
        },

        else => null,
    };
}

pub fn drop_from_inventory(event: windows.KEY_EVENT_RECORD_W) ?Action {
    // ignore keyup events
    if (event.bKeyDown == 0) return null;

    return switch (event.wVirtualKeyCode) {
        .Escape => .cancel_menu,

        .KeyA, .KeyB, .KeyC, .KeyD, .KeyE, .KeyF, .KeyG, .KeyH, .KeyI, .KeyJ, .KeyK, .KeyL, .KeyM, .KeyN, .KeyO, .KeyP, .KeyQ, .KeyR, .KeyS, .KeyT, .KeyU, .KeyV, .KeyW, .KeyX, .KeyY, .KeyZ => .{
            .drop_from_inventory = .{ .index = @intFromEnum(event.wVirtualKeyCode) - key_a_value },
        },

        else => null,
    };
}

pub fn show_targeting_key(event: windows.KEY_EVENT_RECORD_W) ?Action {
    // ignore keyup events
    if (event.bKeyDown == 0) return null;

    return switch (event.wVirtualKeyCode) {
        .Escape => .cancel_menu,

        .Left => .{ .cursor_movement = .{ .dx = -1, .dy = 0 } },
        .Up => .{ .cursor_movement = .{ .dx = 0, .dy = -1 } },
        .Right => .{ .cursor_movement = .{ .dx = 1, .dy = 0 } },
        .Down => .{ .cursor_movement = .{ .dx = 0, .dy = 1 } },

        .Return, .Space => .confirm_target,

        else => null,
    };
}

pub fn show_targeting_mouse(event: windows.MOUSE_EVENT_RECORD) ?Action {
    return switch (event.dwButtonState) {
        1 => .confirm_target,
        2 => .cancel_menu,

        else => null,
    };
}
