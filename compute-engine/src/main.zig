const std = @import("std");

const audio_linux = @import("audio_linux.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var audio = try audio_linux.Device.init(allocator);
    defer audio.deinit();
    var stream = try audio.createStream();
    defer stream.deinit();
    stream.play();
    std.debug.print("Time to do some computing!\n", .{});
}
