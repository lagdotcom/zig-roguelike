const Action = @import("actions.zig").Action;
const windows = @import("arch/windows.zig");

pub fn process(event: windows.KEY_EVENT_RECORD_W) ?Action {
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

        else => null,
    };
}
