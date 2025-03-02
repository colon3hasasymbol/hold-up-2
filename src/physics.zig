const std = @import("std");
const zmath = @import("zmath");

const gx = @import("graphics.zig");

pub const BoundingBox = struct {
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

    pub fn vertices(self: @This()) [36]gx.Model.Vertex {
        return [_]gx.Model.Vertex{
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.max[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.min[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.min[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
            gx.Model.Vertex{ .position = .{ self.max[0], self.max[1], self.min[2] }, .uv = .{ 0.0, 0.0 } },
        };
    }
};

pub const ShapeType = enum { box, sphere };

pub const Shape = union(ShapeType) {
    pub const Box = struct {
        bounds: BoundingBox,

        pub fn support(self: *const @This(), dir: zmath.Vec, pos: zmath.Vec, rot: zmath.Quat, bias: f32) zmath.Vec {
            const points = [_]zmath.Vec{
                .{ self.bounds.min[0], self.bounds.min[1], self.bounds.min[2], 1.0 },
                .{ self.bounds.max[0], self.bounds.min[1], self.bounds.min[2], 1.0 },
                .{ self.bounds.min[0], self.bounds.max[1], self.bounds.min[2], 1.0 },
                .{ self.bounds.min[0], self.bounds.min[1], self.bounds.max[2], 1.0 },
                .{ self.bounds.max[0], self.bounds.max[1], self.bounds.max[2], 1.0 },
                .{ self.bounds.min[0], self.bounds.max[1], self.bounds.max[2], 1.0 },
                .{ self.bounds.max[0], self.bounds.min[1], self.bounds.max[2], 1.0 },
                .{ self.bounds.max[0], self.bounds.max[1], self.bounds.min[2], 1.0 },
            };

            // Find the point in furthest in direction
            var max_pt = zmath.rotate(rot, points[0]) + pos;
            var max_dist = zmath.dot3(max_pt, dir)[0];
            for (1..points.len - 1) |i| {
                const pt = zmath.rotate(rot, points[i]) + pos;
                const dist = zmath.dot3(pt, dir)[0];

                if (dist > max_dist) {
                    max_dist = dist;
                    max_pt = pt;
                }
            }

            const norm = zmath.normalize3(dir) * @as(zmath.Vec, @splat(bias));

            return max_pt + norm;
        }
    };

    pub const Sphere = struct {
        radius: f32,

        pub fn support(self: *const @This(), dir: zmath.Vec, pos: zmath.Vec, bias: f32) zmath.Vec {
            return (pos + dir * @as(zmath.Vec, @splat(self.radius + bias)));
        }
    };

    box: Box,
    sphere: Sphere,

    pub fn support(self: *const @This(), dir: zmath.Vec, pos: zmath.Vec, rot: zmath.Quat, bias: f32) zmath.Vec {
        switch (self.*) {
            .box => |*box| return box.support(dir, pos, rot, bias),
            .sphere => |*sphere| return sphere.support(dir, pos, bias),
        }
    }
};

pub const Point = struct {
    xyz: zmath.Vec,
    pta: zmath.Vec,
    ptb: zmath.Vec,
};

pub fn support(shape1: Shape, pos1: zmath.Vec, rot1: zmath.Quat, shape2: Shape, pos2: zmath.Vec, rot2: zmath.Quat, dir: zmath.Vec, bias: f32) Point {
    var norm_dir = zmath.normalize3(dir);

    const pt1 = shape1.support(norm_dir, pos1, rot1, bias);

    norm_dir = norm_dir * @as(zmath.Vec, @splat(-1.0));

    const pt2 = shape2.support(norm_dir, pos2, rot2, bias);

    return .{ .pta = pt1, .ptb = pt2, .xyz = pt1 - pt2 };
}

pub fn hasPoint(simplex_points: [4]Point, pt: Point) bool {
    const precision: f32 = 1e-6;

    for (0..4) |i| {
        const delta = simplex_points[i].xyz - pt.xyz;
        if (zmath.lengthSq3(delta)[0] < precision * precision) {
            return true;
        }
    }
    return false;
}

pub fn signedVolume1D(s1: zmath.Vec, s2: zmath.Vec) zmath.Vec {
    const ab = s2 - s1;
    const ap = zmath.Vec{ 0.0, 0.0, 0.0, 1.0 } - s1;
    const p0 = s1 + ab * zmath.dot3(ab, ap) / zmath.lengthSq3(ab);

    var index: u32 = 0;
    var mu_max: f32 = 0.0;
    for (0..3) |i| {
        const mu = s2[i] - s1[i];
        if (mu * mu > mu_max * mu_max) {
            mu_max = mu;
            index = @intCast(i);
        }
    }

    const a = s1[index];
    const b = s2[index];
    const p = p0[index];

    const c1 = p - a;
    const c2 = b - p;

    if ((p > a and p < b) or (p > b and p < a)) {
        return .{ c2 / mu_max, c1 / mu_max, 0.0, 0.0 };
    }

    if ((a <= b and p <= a) or (a >= b and p >= a)) {
        return .{ 1.0, 0.0, 0.0, 0.0 };
    }

    return .{ 0.0, 1.0, 0.0, 0.0 };
}

pub fn compareSigns(a: f32, b: f32) bool {
    if (a > 0.0 and b > 0.0) {
        return true;
    }
    if (a < 0.0 and b < 0.0) {
        return true;
    }
    return false;
}

pub fn signedVolume2D(s1: zmath.Vec, s2: zmath.Vec, s3: zmath.Vec) zmath.Vec {
    const normal = zmath.cross3(s2 - s1, s3 - s1);
    const p0 = normal * (zmath.dot3(s1, normal) / zmath.lengthSq3(normal));

    var index: u32 = 0;
    var area_max: f32 = 0.0;
    for (0..3) |i| {
        const j = @mod(i + 1, 3);
        const k = @mod(i + 2, 3);

        const a = zmath.Vec{ s1[j], s1[k], 0.0, 0.0 };
        const b = zmath.Vec{ s2[j], s2[k], 0.0, 0.0 };
        const c = zmath.Vec{ s3[j], s3[k], 0.0, 0.0 };

        const ab = b - a;
        const ac = c - a;

        const area: f32 = ab[0] * ac[1] - ab[1] * ac[0];
        if (area * area > area_max * area_max) {
            area_max = area;
            index = @intCast(i);
        }
    }

    const x = @mod(index + 1, 3);
    const y = @mod(index + 2, 3);

    const s = [_]zmath.Vec{
        .{ s1[x], s1[y], 0.0, 0.0 },
        .{ s2[x], s2[y], 0.0, 0.0 },
        .{ s3[x], s3[y], 0.0, 0.0 },
    };

    var areas: zmath.Vec = undefined;
    for (0..3) |i| {
        const j = @mod(i + 1, 3);
        const k = @mod(i + 2, 3);

        const b = s[j];
        const c = s[k];

        const ab = b - p0;
        const ac = c - p0;

        areas[i] = ab[0] * ac[1] - ab[1] * ac[0];
    }

    if (compareSigns(area_max, areas[0]) and compareSigns(area_max, areas[1]) and compareSigns(area_max, areas[2])) {
        return areas / @as(zmath.Vec, @splat(area_max));
    }

    var dist = std.math.floatMax(f32);
    var lambdas = zmath.Vec{ 1.0, 0.0, 0.0, 0.0 };
    for (0..3) |i| {
        const k = @mod(i + 1, 3);
        const l = @mod(i + 2, 3);

        const edges_pts = [_]zmath.Vec{ s1, s2, s3 };

        const lambda_edge = signedVolume1D(edges_pts[k], edges_pts[l]);
        const pt = (edges_pts[k] * @as(zmath.Vec, @splat(lambda_edge[0]))) + (edges_pts[l] * @as(zmath.Vec, @splat(lambda_edge[1])));
        const len_sqr = zmath.lengthSq3(pt)[0];
        if (len_sqr < dist) {
            dist = len_sqr;
            lambdas[i] = 0.0;
            lambdas[k] = lambda_edge[0];
            lambdas[l] = lambda_edge[1];
        }
    }

    return lambdas;
}

pub fn signedVolume3D(s1: zmath.Vec, s2: zmath.Vec, s3: zmath.Vec, s4: zmath.Vec) zmath.Vec {
    const m = zmath.Mat{
        .{ s1[0], s2[0], s3[0], s4[0] },
        .{ s1[1], s2[1], s3[1], s4[1] },
        .{ s1[2], s2[2], s3[2], s4[2] },
        .{ 1.0, 1.0, 1.0, 1.0 },
    };

    const c4 = zmath.Vec{
        zmath.cofactor(m, 3, 0),
        zmath.cofactor(m, 3, 1),
        zmath.cofactor(m, 3, 2),
        zmath.cofactor(m, 3, 3),
    };

    const detm = c4[0] + c4[1] + c4[2] + c4[3];

    if (compareSigns(detm, c4[0]) and compareSigns(detm, c4[1]) and compareSigns(detm, c4[2]) and compareSigns(detm, c4[3])) return c4 * @as(zmath.Vec, @splat(1.0 / detm));

    var lambdas: zmath.Vec = undefined;
    var dist = std.math.floatMax(f32);
    for (0..4) |i| {
        const j = @mod(i + 1, 4);
        const k = @mod(i + 2, 4);

        const face_pts = [_]zmath.Vec{ s1, s2, s3, s4 };

        const lambdas_face = signedVolume2D(face_pts[i], face_pts[j], face_pts[k]);
        const pt = face_pts[i] * @as(zmath.Vec, @splat(lambdas_face[0])) * face_pts[j] * @as(zmath.Vec, @splat(lambdas_face[1])) * face_pts[k] * @as(zmath.Vec, @splat(lambdas_face[2]));
        const len = zmath.lengthSq3(pt)[0];
        if (len < dist) {
            dist = len;
            lambdas = .{ 0.0, 0.0, 0.0, 0.0 };
            lambdas[i] = lambdas_face[0];
            lambdas[j] = lambdas_face[1];
            lambdas[k] = lambdas_face[2];
        }
    }

    return lambdas;
}

pub fn simplexSignedVolumes(points: []Point) struct { does_intersect: bool, lambdas: zmath.Vec, new_dir: zmath.Vec } {
    const epsilonf = 0.0001 * 0.0001;

    var lambdas = zmath.Vec{ 0.0, 0.0, 0.0, 0.0 };
    var does_intersect = false;
    var new_dir: zmath.Vec = undefined;

    switch (points.len) {
        2 => {
            lambdas = signedVolume1D(points[0].xyz, points[1].xyz);
            var v = zmath.Vec{ 0.0, 0.0, 0.0, 0.0 };
            for (0..2) |i| {
                v += points[i].xyz * @as(zmath.Vec, @splat(lambdas[i]));
            }
            new_dir = v * @as(zmath.Vec, @splat(-1.0));
            does_intersect = zmath.lengthSq3(v)[0] < epsilonf;
        },
        3 => {
            lambdas = signedVolume2D(points[0].xyz, points[1].xyz, points[2].xyz);
            var v = zmath.Vec{ 0.0, 0.0, 0.0, 0.0 };
            for (0..3) |i| {
                v += points[i].xyz * @as(zmath.Vec, @splat(lambdas[i]));
            }
            new_dir = v * @as(zmath.Vec, @splat(-1.0));
            does_intersect = zmath.lengthSq3(v)[0] < epsilonf;
        },
        4 => {
            lambdas = signedVolume3D(points[0].xyz, points[1].xyz, points[2].xyz, points[3].xyz);
            var v = zmath.Vec{ 0.0, 0.0, 0.0, 0.0 };
            for (0..4) |i| {
                v += points[i].xyz * @as(zmath.Vec, @splat(lambdas[i]));
            }
            new_dir = v * @as(zmath.Vec, @splat(-1.0));
            does_intersect = zmath.lengthSq3(v)[0] < epsilonf;
        },
        else => std.debug.panic("what", .{}),
    }

    return .{
        .does_intersect = does_intersect,
        .lambdas = lambdas,
        .new_dir = new_dir,
    };
}

pub fn sortValids(simplex_points: *[4]Point, lambdas: *zmath.Vec) void {
    var valid_lambdas = zmath.Vec{ 0.0, 0.0, 0.0, 0.0 };
    var valid_count: u32 = 0;
    var valid_pts = std.mem.zeroes([4]Point);

    for (0..4) |i| {
        if (lambdas[i] != 0.0) {
            valid_pts[valid_count] = simplex_points.*[i];
            valid_lambdas[valid_count] = lambdas.*[i];
            valid_count += 1;
        }
    }

    @memcpy(simplex_points, &valid_pts);
    lambdas.* = valid_lambdas;
}

pub fn countValids(lambdas: zmath.Vec) u32 {
    var count: u32 = 0;
    for (0..4) |i| {
        if (lambdas[i] != 0.0) count += 1;
    }

    return count;
}

pub fn intersect(shape1: Shape, pos1: zmath.Vec, rot1: zmath.Quat, shape2: Shape, pos2: zmath.Vec, rot2: zmath.Quat) bool {
    const origin: zmath.Vec = .{ 0.0, 0.0, 0.0, 1.0 };

    var num_pts: u32 = 1;
    var simplex_points: [4]Point = undefined;

    simplex_points[0] = support(shape1, pos1, rot1, shape2, pos2, rot2, .{ 1.0, 1.0, 1.0, 1.0 }, 0.0);

    var closest_dist = std.math.floatMax(f32);
    var contains_origin = false;
    var new_dir = simplex_points[0].xyz * @as(zmath.Vec, @splat(-1.0));

    while (true) {
        const new_pt = support(shape1, pos1, rot1, shape2, pos2, rot2, new_dir, 0.0);

        if (hasPoint(simplex_points, new_pt)) break;

        simplex_points[num_pts] = new_pt;
        num_pts += 1;

        const dotdot = zmath.dot3(new_dir, new_pt.xyz - origin)[0];
        if (dotdot < 0.0) break;

        const simplex_result = simplexSignedVolumes(simplex_points[0..num_pts]);
        var lambdas: zmath.Vec = simplex_result.lambdas;
        contains_origin = simplex_result.does_intersect;
        new_dir = simplex_result.new_dir;

        if (contains_origin) break;

        const dist = zmath.lengthSq3(new_dir)[0];
        if (dist >= closest_dist) break;
        closest_dist = dist;

        sortValids(&simplex_points, &lambdas);
        contains_origin = (countValids(lambdas) == 4);
        if (contains_origin) break;
    }

    return contains_origin;
}
