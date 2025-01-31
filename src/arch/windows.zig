// TODO figure out how to make any of this work on non-Windows

const std = @import("std");
const windows = std.os.windows;

const WINAPI = windows.WINAPI;
const BOOL = windows.BOOL;
const COORD = windows.COORD;
const DWORD = windows.DWORD;
const HANDLE = windows.HANDLE;
const UINT = windows.UINT;
const USHORT = windows.USHORT;
const WCHAR = windows.WCHAR;
const WORD = windows.WORD;

pub const CONSOLE_SCREEN_BUFFER_INFO = windows.CONSOLE_SCREEN_BUFFER_INFO;
pub const GetConsoleScreenBufferInfo = windows.kernel32.GetConsoleScreenBufferInfo;

pub extern "kernel32" fn GetConsoleMode(hConsoleHandle: HANDLE, lpMode: *DWORD) callconv(WINAPI) BOOL;
pub extern "kernel32" fn SetConsoleMode(hConsoleHandle: HANDLE, dwMode: DWORD) callconv(WINAPI) BOOL;

pub const INPUT_RECORD_TYPE = enum(WORD) {
    Focus = 0x10,
    Key = 0x1,
    Menu = 0x8,
    Mouse = 0x2,
    WindowBufferSize = 0x4,
};

pub const FOCUS_EVENT_RECORD = extern struct {
    bSetFocus: BOOL,
};

pub const VIRTUAL_KEY = enum(WORD) {
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

pub const CONTROL_KEY_STATE = struct {
    pub const RIGHT_ALT_PRESSED = 0x1;
    pub const LEFT_ALT_PRESSED = 0x2;
    pub const RIGHT_CTRL_PRESSED = 0x4;
    pub const LEFT_CTRL_PRESSED = 0x8;
    pub const SHIFT_PRESSED = 0x10;
    pub const NUMLOCK_ON = 0x20;
    pub const SCROLLLOCK_ON = 0x40;
    pub const CAPSLOCK_ON = 0x80;
    pub const ENHANCED_KEY = 0x100;
};

pub const KEY_EVENT_RECORD_W = extern struct {
    bKeyDown: BOOL,
    wRepeatCount: WORD,
    wVirtualKeyCode: VIRTUAL_KEY,
    wVirtualScanCode: WORD,
    UnicodeChar: WCHAR,
    dwControlKeyState: DWORD,
};

pub const MENU_EVENT_RECORD = extern struct {
    dwCommandId: UINT,
};

pub const MOUSE_EVENT_BUTTON_STATE = struct {
    pub const FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001;
    pub const FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004;
    pub const FROM_LEFT_3RD_BUTTON_PRESSED = 0x0008;
    pub const FROM_LEFT_4TH_BUTTON_PRESSED = 0x0010;
    pub const RIGHTMOST_BUTTON_PRESSED = 0x0002;
};

pub const MOUSE_EVENT_FLAGS = struct {
    pub const DOUBLE_CLICK = 0x0002;
    pub const MOUSE_HWHEELED = 0x0008;
    pub const MOUSE_MOVED = 0x0001;
    pub const MOUSE_WHEELED = 0x0004;
};

pub const MOUSE_EVENT_RECORD = extern struct {
    dwMousePosition: COORD,
    dwButtonState: DWORD,
    dwControlKeyState: DWORD,
    dwEventFlags: DWORD,
};

pub const WINDOW_BUFFER_SIZE_RECORD = extern struct {
    dwSize: COORD,
};

pub const INPUT_RECORD_W = extern struct {
    EventType: INPUT_RECORD_TYPE,
    Event: extern union {
        KeyEvent: KEY_EVENT_RECORD_W,
        MouseEvent: MOUSE_EVENT_RECORD,
        WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
        MenuEvent: MENU_EVENT_RECORD,
        FocusEvent: FOCUS_EVENT_RECORD,
    },
};

pub extern "kernel32" fn ReadConsoleInputW(hConsoleInput: HANDLE, lpBuffer: [*]INPUT_RECORD_W, nLength: DWORD, lpNumberOfEventsRead: *DWORD) callconv(WINAPI) BOOL;

pub const ConsoleSize = struct {
    width: i16,
    height: i16,
};

pub fn get_console_size(out: std.fs.File) ConsoleSize {
    var info: windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    _ = GetConsoleScreenBufferInfo(out.handle, &info);

    return .{ .width = info.dwSize.X, .height = info.dwSize.Y };
}

pub fn set_console_mode(in: std.fs.File, mode: u32) u32 {
    var oldMode: u32 = undefined;
    _ = GetConsoleMode(in.handle, &oldMode);
    _ = SetConsoleMode(in.handle, mode);

    return oldMode;
}

pub const File = std.fs.File;
pub const get_stderr = std.io.getStdErr;
pub const get_stdin = std.io.getStdIn;
pub const get_stdout = std.io.getStdOut;
pub const get_random = std.posix.getrandom;

pub fn get_console_input_records(f: File, buffer: []INPUT_RECORD_W) u32 {
    var read: u32 = undefined;
    _ = ReadConsoleInputW(
        f.handle,
        buffer.ptr,
        @intCast(buffer.len),
        &read,
    );

    return read;
}

pub const run_forever = true;
