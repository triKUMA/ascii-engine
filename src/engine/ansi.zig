/// ANSI escape sequences for terminal control and styling
pub const AnsiCodes = struct {
    pub const Cursor = struct {
        pub const home = "\x1b[H";
        pub const hide = "\x1b[?25l";
        pub const show = "\x1b[?25h";
    };

    pub const Screen = struct {
        pub const clear = "\x1b[2J";
        pub const enterAlt = "\x1b[?1049h";
        pub const exitAlt = "\x1b[?1049l";
    };

    pub const Text = struct {
        pub const Style = struct {
            pub const reset = "\x1b[0m";
            pub const bold = "\x1b[1m";
            pub const dim = "\x1b[2m";
            pub const italic = "\x1b[3m";
            pub const underline = "\x1b[4m";
            pub const blink = "\x1b[5m";
            pub const reverse = "\x1b[7m";
            pub const hidden = "\x1b[8m";
            pub const strikethrough = "\x1b[9m";
        };

        pub const Colour = struct {
            pub const Foreground = struct {
                pub const black = "\x1b[30m";
                pub const red = "\x1b[31m";
                pub const green = "\x1b[32m";
                pub const yellow = "\x1b[33m";
                pub const blue = "\x1b[34m";
                pub const magenta = "\x1b[35m";
                pub const cyan = "\x1b[36m";
                pub const white = "\x1b[37m";

                pub const Bright = struct {
                    pub const black = "\x1b[90m";
                    pub const red = "\x1b[91m";
                    pub const green = "\x1b[92m";
                    pub const yellow = "\x1b[93m";
                    pub const blue = "\x1b[94m";
                    pub const magenta = "\x1b[95m";
                    pub const cyan = "\x1b[96m";
                    pub const white = "\x1b[97m";
                };
            };

            pub const Background = struct {
                pub const black = "\x1b[40m";
                pub const red = "\x1b[41m";
                pub const green = "\x1b[42m";
                pub const yellow = "\x1b[43m";
                pub const blue = "\x1b[44m";
                pub const magenta = "\x1b[45m";
                pub const cyan = "\x1b[46m";
                pub const white = "\x1b[47m";

                pub const Bright = struct {
                    pub const black = "\x1b[100m";
                    pub const red = "\x1b[101m";
                    pub const green = "\x1b[102m";
                    pub const yellow = "\x1b[103m";
                    pub const blue = "\x1b[104m";
                    pub const magenta = "\x1b[105m";
                    pub const cyan = "\x1b[106m";
                    pub const white = "\x1b[107m";
                };
            };
        };
    };
};
