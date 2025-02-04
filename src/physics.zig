const std = @import("std");
const zmath = @import("zmath");

pub const Cube = struct {
    min: zmath.Vec,
    max: zmath.Vec,

    pub fn cube1x1() @This() {
        return .{
            .min = .{ -0.5, -0.5, -0.5, 1.0 },
            .max = .{ 0.5, 0.5, 0.5, 1.0 },
        };
    }

    pub fn translate(self: @This(), vec: zmath.Vec) @This() {
        return .{
            .min = self.min + vec,
            .max = self.max + vec,
        };
    }

    pub fn overlapping(self: @This(), other: @This()) bool {
        return self.min[0] <= other.max[0] and
            self.max[0] >= other.min[0] and
            self.min[1] <= other.max[1] and
            self.max[1] >= other.min[1] and
            self.min[2] <= other.max[2] and
            self.max[2] >= other.min[2];
    }
};
