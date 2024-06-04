const builtin = @import("builtin");
const arch = if (builtin.target.cpu.arch == .wasm32) @import("arch/wasm.zig") else @import("arch/windows.zig");

pub const File = arch.File;
pub const getrandom = arch.getrandom;
pub const getConsoleInput = arch.getConsoleInputRecords;
pub const getSize = arch.getSize;
pub const getStdErr = arch.getStdErr;
pub const getStdIn = arch.getStdIn;
pub const getStdOut = arch.getStdOut;
pub const setMode = arch.setMode;

pub const ready = arch.ready;
pub const runForever = arch.runForever;
