const actions = @import("actions.zig");
const windows = @import("arch/windows.zig");

const Action = actions.Action;
const VK = windows.VIRTUAL_KEY;

pub fn process(event: windows.KEY_EVENT_RECORD_W) ?Action {
    // ignore keyup events
    if (event.bKeyDown == 0) return null;

    return switch (event.wVirtualKeyCode) {
        VK.Left => Action{ .movement = .{ .dx = -1, .dy = 0 } },
        VK.Up => Action{ .movement = .{ .dx = 0, .dy = -1 } },
        VK.Right => Action{ .movement = .{ .dx = 1, .dy = 0 } },
        VK.Down => Action{ .movement = .{ .dx = 0, .dy = 1 } },

        VK.Escape => Action{ .escape = true },

        else => null,
    };
}
