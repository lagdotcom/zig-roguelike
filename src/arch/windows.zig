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

pub extern "kernel32" fn ReadConsoleInputExW(hConsoleInput: HANDLE, lpBuffer: [*]INPUT_RECORD_W, nLength: DWORD, lpNumberOfEventsRead: *DWORD, wFlags: USHORT) callconv(WINAPI) BOOL;
