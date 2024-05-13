const actions = @import("actions.zig");
const console = @import("console.zig");

pub fn process(event: console.KEY_EVENT_RECORD_W) ?actions.Action {
    // ignore keyup events
    if (event.bKeyDown == 0) return null;

    return switch (event.wVirtualKeyCode) {
        console.VirtualKey.Left => actions.Action{ .movement = .{ .dx = -1, .dy = 0 } },
        console.VirtualKey.Up => actions.Action{ .movement = .{ .dx = 0, .dy = -1 } },
        console.VirtualKey.Right => actions.Action{ .movement = .{ .dx = 1, .dy = 0 } },
        console.VirtualKey.Down => actions.Action{ .movement = .{ .dx = 0, .dy = 1 } },

        console.VirtualKey.Escape => actions.Action{ .escape = true },

        else => null,
    };
}
