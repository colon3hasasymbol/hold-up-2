const std = @import("std");

const audio_linux = @import("audio_linux.zig");

pub fn main() !void {
    var audio = try audio_linux.Device.init();
    defer audio.deinit();
    std.debug.print("Time to do some computing!\n", .{});
}
