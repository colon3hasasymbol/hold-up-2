const std = @import("std");
const GameRandom = @import("game_random.zig");

pub const Planet = struct {
    stat_values: []f32,
};

gr: *GameRandom,
allocator: std.mem.Allocator,
planet_stats: [][]u8,

pub fn init(generator_data: []const u8, allocator: std.mem.Allocator, gr: *GameRandom) !@This() {
    const ParseStruct = struct {
        planet_stats: [][]u8,
    };

    const parsed = try std.json.parseFromSliceLeaky(ParseStruct, allocator, generator_data, .{ .allocate = .alloc_always });

    return .{
        .gr = gr,
        .allocator = allocator,
        .planet_stats = parsed.planet_stats,
    };
}

pub fn deinit(self: *@This()) void {
    for (self.planet_stats) |string| {
        self.allocator.free(string);
    }
    self.allocator.free(self.planet_stats);
}

pub fn generatePlanet(self: *@This()) !Planet {
    var stat_values = try self.allocator.alloc(f32, self.planet_stats.len);

    for (0..stat_values.len - 1) |i| {
        stat_values[i] = self.gr.genFloat(f32);
    }

    return .{
        .stat_values = stat_values,
    };
}

pub fn freePlanet(self: @This(), planet: *Planet) void {
    self.allocator.free(planet.stat_values);
}
