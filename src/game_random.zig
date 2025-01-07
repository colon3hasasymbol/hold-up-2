const std = @import("std");

internal_generator: std.rand.DefaultPrng,

pub fn init(seed: []const u8) @This() {
    return .{
        .internal_generator = std.rand.DefaultPrng.init(std.hash.Wyhash.hash(0, seed)),
    };
}

pub fn genFloat(self: *@This(), comptime T: type) T {
    return self.internal_generator.random().float(T);
}

pub fn genFloatRange(self: *@This(), comptime T: type, min: T, max: T) !T {
    if (max < min) return error.MaxLesserThanMin;

    return (self.gen_float(T) * (max - min)) + min;
}
