const std = @import("std");
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const windows = @import("arch/windows.zig");

pub const ConsoleMode = struct {
    pub const ENABLE_ECHO_INPUT = 0x4;
    pub const ENABLE_INSERT_MODE = 0x20;
    pub const ENABLE_LINE_INPUT = 0x2;
    pub const ENABLE_MOUSE_INPUT = 0x10;
    pub const ENABLE_PROCESSED_INPUT = 0x1;
    pub const ENABLE_QUICK_EDIT_MODE = 0x40;
    pub const ENABLE_WINDOW_INPUT = 0x8;
    pub const ENABLE_VIRTUAL_TERMINAL_INPUT = 0x200;

    pub const ENABLE_PROCESSED_OUTPUT = 0x1;
    pub const ENABLE_WRAP_AT_EOL_OUTPUT = 0x2;
    pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x4;
    pub const DISABLE_NEWLINE_AUTO_RETURN = 0x8;
    pub const ENABLE_LVB_GRID_WORLDWIDE = 0x10;
};

pub const ConsoleInputEvent = union(enum) {
    key: windows.KEY_EVENT_RECORD_W,
    mouse: windows.MOUSE_EVENT_RECORD,
    size: windows.WINDOW_BUFFER_SIZE_RECORD,
    menu: windows.MENU_EVENT_RECORD,
    focus: windows.FOCUS_EVENT_RECORD,
};

const ReadConsoleExFlags = struct {
    pub const NoRemove = 0x1;
    pub const NoWait = 0x2;
};

pub fn setMode(in: File, mode: u32) u32 {
    var oldMode: u32 = undefined;
    _ = windows.GetConsoleMode(in.handle, &oldMode);
    _ = windows.SetConsoleMode(in.handle, mode);

    return oldMode;
}

pub const ConsoleSize = struct {
    width: i16,
    height: i16,
};

pub fn getSize(out: File) ConsoleSize {
    var info: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    _ = windows.GetConsoleScreenBufferInfo(out.handle, &info);

    return .{ .width = info.dwSize.X, .height = info.dwSize.Y };
}

pub const EventManager = struct {
    allocator: Allocator,
    raw_events: []windows.INPUT_RECORD_W,
    events: []ConsoleInputEvent,
    file: File,
    old_mode: u32,

    pub fn init(allocator: Allocator, size: usize, file: File) !EventManager {
        const old_mode = setMode(
            file,
            ConsoleMode.ENABLE_WINDOW_INPUT | ConsoleMode.ENABLE_PROCESSED_INPUT,
        );

        return EventManager{
            .allocator = allocator,
            .file = file,
            .old_mode = old_mode,
            .raw_events = try allocator.alloc(windows.INPUT_RECORD_W, size),
            .events = try allocator.alloc(ConsoleInputEvent, size),
        };
    }

    pub fn deinit(self: EventManager) void {
        self.allocator.free(self.raw_events);
        self.allocator.free(self.events);
        _ = setMode(self.file, self.old_mode);
    }

    pub fn wait(self: EventManager) []ConsoleInputEvent {
        var read: u32 = undefined;
        _ = windows.ReadConsoleInputExW(
            self.file.handle,
            self.raw_events.ptr,
            @intCast(self.raw_events.len),
            &read,
            0,
        );

        for (self.raw_events[0..read], 0..) |raw, i| {
            self.events[i] = switch (raw.EventType) {
                windows.INPUT_RECORD_TYPE.Key => ConsoleInputEvent{ .key = raw.Event.KeyEvent },
                windows.INPUT_RECORD_TYPE.Mouse => ConsoleInputEvent{ .mouse = raw.Event.MouseEvent },
                windows.INPUT_RECORD_TYPE.WindowBufferSize => ConsoleInputEvent{ .size = raw.Event.WindowBufferSizeEvent },
                windows.INPUT_RECORD_TYPE.Menu => ConsoleInputEvent{ .menu = raw.Event.MenuEvent },
                windows.INPUT_RECORD_TYPE.Focus => ConsoleInputEvent{ .focus = raw.Event.FocusEvent },
            };
        }

        return self.events[0..read];
    }
};
