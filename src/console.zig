const std = @import("std");
const windows = std.os.windows;

// TODO figure out how to make any of this work on non-Windows

pub const ConsoleMode = enum(windows.DWORD) {
    ENABLE_ECHO_INPUT = 0x4,
    ENABLE_INSERT_MODE = 0x20,
    ENABLE_LINE_INPUT = 0x2,
    ENABLE_MOUSE_INPUT = 0x10,
    ENABLE_PROCESSED_INPUT = 0x1,
    ENABLE_QUICK_EDIT_MODE = 0x40,
    ENABLE_WINDOW_INPUT = 0x8,
    ENABLE_VIRTUAL_TERMINAL_INPUT = 0x200,

    // ENABLE_PROCESSED_OUTPUT = 0x1,
    // ENABLE_WRAP_AT_EOL_OUTPUT = 0x2,
    // ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x4,
    // DISABLE_NEWLINE_AUTO_RETURN = 0x8,
    // ENABLE_LVB_GRID_WORLDWIDE = 0x10,
};

extern "kernel32" fn GetConsoleMode(hConsoleHandle: windows.HANDLE, lpMode: *ConsoleMode) callconv(windows.WINAPI) windows.BOOL;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: windows.HANDLE, dwMode: ConsoleMode) callconv(windows.WINAPI) windows.BOOL;

const InputEventType = enum(windows.WORD) {
    Focus = 0x10,
    Key = 0x1,
    Menu = 0x8,
    Mouse = 0x2,
    WindowBufferSize = 0x4,
};

const FOCUS_EVENT_RECORD = extern struct {
    bSetFocus: windows.BOOL,
};

pub const VirtualKey = enum(windows.WORD) {
    LeftMouseButton = 1,
    RightMouseButton,
    Cancel,
    MiddleMouseButton,
    ExtraMouseButton1,
    ExtraMouseButton2,

    Back = 8,
    Tab,

    Clear = 0xc,
    Return,

    Shift = 0x10,
    Control,
    Menu,
    Pause,
    Capital,
    Kana_Hangul,
    IMEOn,
    IMEJunja,
    IMEFinal,
    IMEHanja_Kanji,
    IMEOff,
    Escape,
    IMEConvert,
    IMENonConvert,
    IMEAccept,
    IMEModeChange,
    Space,
    Prior,
    Next,
    End,
    Home,
    Left,
    Up,
    Right,
    Down,
    Select,
    Print,
    Execute,
    Snapshot,
    Insert,
    Delete,
    Help,
    Key0,
    Key1,
    Key2,
    Key3,
    Key4,
    Key5,
    Key6,
    Key7,
    Key8,
    Key9,

    KeyA = 0x41,
    KeyB,
    KeyC,
    KeyD,
    KeyE,
    KeyF,
    KeyG,
    KeyH,
    KeyI,
    KeyJ,
    KeyK,
    KeyL,
    KeyM,
    KeyN,
    KeyO,
    KeyP,
    KeyQ,
    KeyR,
    KeyS,
    KeyT,
    KeyU,
    KeyV,
    KeyW,
    KeyX,
    KeyY,
    KeyZ,
    LeftWindowsKey,
    RightWindowsKey,
    Apps,

    Sleep = 0x5f,
    Numpad0,
    Numpad1,
    Numpad2,
    Numpad3,
    Numpad4,
    Numpad5,
    Numpad6,
    Numpad7,
    Numpad8,
    Numpad9,
    Multiply,
    Add,
    Separator,
    Subtract,
    Decimal,
    Divide,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    F21,
    F22,
    F23,
    F24,

    NumLock = 0x90,
    Scroll,

    LeftShift = 0xa0,
    RightShift,
    LeftControl,
    RightControl,
    LeftMenu,
    RightMenu,
    BrowserBack,
    BrowserForward,
    BrowserRefresh,
    BrowserStop,
    BrowserSearch,
    BrowserFavorites,
    BrowserHome,
    VolumeMute,
    VolumeDown,
    VolumeUp,
    MediaNextTrack,
    MediaPrevTrack,
    MediaStop,
    MediaPlayPause,
    LaunchMail,
    LaunchMediaSelect,
    LaunchApp1,
    LaunchApp2,

    OEM1 = 0xba,
    OEMPlus,
    OEMComma,
    OEMMinus,
    OEMPeriod,
    OEM2,
    OEM3,

    OEM4 = 0xdb,
    OEM5,
    OEM6,
    OEM7,
    OEM8,

    OEM102 = 0xe2,

    IMEProcessKey = 0xe5,

    UnicodePacket = 0xe7,

    Attention = 0xf6,
    CrSel,
    ExSel,
    ErEOF,
    Play,
    Zoom,
    Noname,
    PA1,
    OEMClear,
};

pub const KEY_EVENT_RECORD_W = extern struct {
    bKeyDown: windows.BOOL,
    wRepeatCount: windows.WORD,
    wVirtualKeyCode: VirtualKey,
    wVirtualScanCode: windows.WORD,
    UnicodeChar: windows.WCHAR,
    dwControlKeyState: windows.DWORD,
};

const MENU_EVENT_RECORD = extern struct {
    dwCommandId: windows.UINT,
};

const MOUSE_EVENT_RECORD = extern struct {
    dwMousePosition: windows.COORD,
    dwButtonState: windows.DWORD,
    dwControlKeyState: windows.DWORD,
    dwEventFlags: windows.DWORD,
};

const WINDOW_BUFFER_SIZE_RECORD = extern struct {
    dwSize: windows.COORD,
};

pub const INPUT_RECORD_W = extern struct {
    EventType: InputEventType,
    Event: extern union {
        KeyEvent: KEY_EVENT_RECORD_W,
        MouseEvent: MOUSE_EVENT_RECORD,
        WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
        MenuEvent: MENU_EVENT_RECORD,
        FocusEvent: FOCUS_EVENT_RECORD,
    },
};

pub const ConsoleInputEvent = union(enum) {
    key: KEY_EVENT_RECORD_W,
    mouse: MOUSE_EVENT_RECORD,
    size: WINDOW_BUFFER_SIZE_RECORD,
    menu: MENU_EVENT_RECORD,
    focus: FOCUS_EVENT_RECORD,
};

const ReadConsoleExFlags = enum(windows.USHORT) {
    NoRemove = 0x1,
    NoWait = 0x2,
};

extern "kernel32" fn ReadConsoleInputExW(hConsoleInput: windows.HANDLE, lpBuffer: [*]INPUT_RECORD_W, nLength: windows.DWORD, lpNumberOfEventsRead: *windows.DWORD, wFlags: ReadConsoleExFlags) callconv(windows.WINAPI) windows.BOOL;

pub fn setMode(in: std.fs.File, mode: ConsoleMode) ConsoleMode {
    var oldMode: ConsoleMode = undefined;
    _ = GetConsoleMode(in.handle, &oldMode);
    _ = SetConsoleMode(in.handle, mode);

    return oldMode;
}

pub const ConsoleSize = struct {
    width: i16,
    height: i16,
};

pub fn getSize(out: std.fs.File) ConsoleSize {
    var info: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    _ = windows.kernel32.GetConsoleScreenBufferInfo(out.handle, &info);

    return .{ .width = info.dwSize.X, .height = info.dwSize.Y };
}

pub fn getEvents(in: std.fs.File, raw_events: []INPUT_RECORD_W, events: []ConsoleInputEvent) []ConsoleInputEvent {
    var read: windows.DWORD = undefined;
    _ = ReadConsoleInputExW(
        in.handle,
        raw_events.ptr,
        @intCast(raw_events.len),
        &read,
        ReadConsoleExFlags.NoWait,
    );

    for (raw_events[0..read], 0..) |raw, i| {
        events[i] = switch (raw.EventType) {
            InputEventType.Key => ConsoleInputEvent{ .key = raw.Event.KeyEvent },
            InputEventType.Mouse => ConsoleInputEvent{ .mouse = raw.Event.MouseEvent },
            InputEventType.WindowBufferSize => ConsoleInputEvent{ .size = raw.Event.WindowBufferSizeEvent },
            InputEventType.Menu => ConsoleInputEvent{ .menu = raw.Event.MenuEvent },
            InputEventType.Focus => ConsoleInputEvent{ .focus = raw.Event.FocusEvent },
        };
    }

    return events[0..read];
}
