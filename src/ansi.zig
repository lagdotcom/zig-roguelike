const std = @import("std");

// Control Sequence Introducer
pub const cursor_position = "\x1B[{};{}H";
pub const show_cursor = "\x1B[?25h";
pub const hide_cursor = "\x1B[?25l";
pub const erase_in_display_to_end = "\x1B[0J";
pub const soft_reset = "\x1B[!p";

// Operating System Command
pub const set_window_title = "\x1B]\x00;{s}\x1B\x5c";
