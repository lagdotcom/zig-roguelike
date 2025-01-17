const builtin = @import("builtin");
const arch = if (builtin.target.cpu.arch == .wasm32) @import("arch/wasm.zig") else @import("arch/windows.zig");

pub const File = arch.File;
pub const get_random = arch.get_random;
pub const get_console_input_records = arch.get_console_input_records;
pub const get_console_size = arch.get_console_size;
pub const get_stderr = arch.get_stderr;
pub const get_stdin = arch.get_stdin;
pub const get_stdout = arch.get_stdout;
pub const set_console_mode = arch.set_console_mode;

pub const ready = arch.ready;
pub const run_forever = arch.run_forever;
