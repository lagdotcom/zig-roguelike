const std = @import("std");

// Control Sequence Introducer
pub const cursor_position = "\x1B[{};{}H";
pub const show_cursor = "\x1B[?25h";
pub const hide_cursor = "\x1B[?25l";
pub const erase_in_display_to_end = "\x1B[0J";
pub const soft_reset = "\x1B[!p";

// Operating System Command
pub const set_window_title = "\x1B]\x00;{s}\x1B\x5c";

// Select Graphics Rendition
pub const sgr = "\x1B[{d}m";
pub const sgr_foreground_rgb = "\x1B[38;2;{d};{d};{d}m";
pub const sgr_background_rgb = "\x1B[48;2;{d};{d};{d}m";

pub const sgr_type = enum(u8) {
    reset = 0,
    bold,
    faint,
    italic,
    underline,
    blink_slow,
    blink_rapid,
    inverse,
    conceal,
    crossed_out,
    font_default,
    font_1,
    font_2,
    font_3,
    font_4,
    font_5,
    font_6,
    font_7,
    font_8,
    font_9,
    fraktur,
    double_underline,
    bold_faint_off,
    italic_fraktur_off,
    underline_off,
    blink_off,
    inverse_off,
    conceal_off,
    crossed_out_off,

    foreground_black = 30,
    foreground_red,
    foreground_green,
    foreground_yellow,
    foreground_blue,
    foreground_magenta,
    foreground_cyan,
    foreground_white,
    foreground_default = 39,

    background_black = 40,
    background_red,
    background_green,
    background_yellow,
    background_blue,
    background_magenta,
    background_cyan,
    background_white,
    background_default = 49,

    framed = 51,
    encircled,
    overlined,
    framed_encircled_off,
    overlined_off,
    ideogram_underline,
    ideogram_double_underline,
    ideogram_overline,
    ideogram_double_overline,
    ideogram_stress_marking,
    ideogram_off,

    foreground_black_bright = 90,
    foreground_red_bright,
    foreground_green_bright,
    foreground_yellow_bright,
    foreground_blue_bright,
    foreground_magenta_bright,
    foreground_cyan_bright,
    foreground_white_bright,

    background_black_bright = 100,
    background_red_bright,
    background_green_bright,
    background_yellow_bright,
    background_blue_bright,
    background_magenta_bright,
    background_cyan_bright,
    background_white_bright,
    background_special_bright,
    background_default_bright,
};
