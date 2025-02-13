const std = @import("std");
const zmath = @import("zmath");

const gx = @import("graphics.zig");

pub const LockedCube = struct {
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

// const Vec3 origin( 0.0f );

// int numPts = 1;
// point_t simplexPoints[ 4 ];
// simplexPoints[ 0 ] = Support( bodyA, bodyB, Vec3( 1, 1, 1 ), 0.0f );

// float closestDist = 1e10f;
// bool doesContainOrigin = false;
// Vec3 newDir = simplexPoints[ 0 ].xyz * -1.0f;
// do {
// 	// Get the new point to check on
// 	point_t newPt = Support( bodyA, bodyB, newDir, 0.0f );

// 	// If the new point is the same as a previous point, then we can't expand any further
// 	if ( HasPoint( simplexPoints, newPt ) ) {
// 		break;
// 	}

// 	simplexPoints[ numPts ] = newPt;
// 	numPts++;

// 	// If this new point hasn't moved passed the origin, then the
// 	// origin cannot be in the set. And therefore there is no collision.
// 	float dotdot = newDir.Dot( newPt.xyz - origin );
// 	if ( dotdot < 0.0f ) {
// 		break;
// 	}

// 	Vec4 lambdas;
// 	doesContainOrigin = SimplexSignedVolumes( simplexPoints, numPts, newDir, lambdas );
// 	if ( doesContainOrigin ) {
// 		break;
// 	}

// 	// Check that the new projection of the origin onto the simplex is closer than the previous
// 	float dist = newDir.GetLengthSqr();
// 	if ( dist >= closestDist ) {
// 		break;
// 	}
// 	closestDist = dist;

// 	// Use the lambdas that support the new search direction, and invalidate any points that don't support it
// 	SortValids( simplexPoints, lambdas );
// 	numPts = NumValids( lambdas );
// 	doesContainOrigin = ( 4 == numPts );
// } while ( !doesContainOrigin );

// return doesContainOrigin;

pub const ShapeType = enum { box, sphere };

pub const Shape = union(ShapeType) {
    pub const Box = struct {
        bounds: LockedCube,

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
            var max_dist = zmath.dot3(max_pt, dir);
            for (1..points.len - 1) |i| {
                const pt = zmath.rotate(rot, points[i]) + pos;
                const dist = zmath.dot3(pt, dir);

                if (dist > max_dist) {
                    max_dist = dist;
                    max_pt = pt;
                }
            }

            const norm = zmath.mul(zmath.normalize3(dir), bias);

            return max_pt + norm;
        }
    };

    pub const Sphere = struct {
        radius: f32,

        pub fn support(self: *const @This(), dir: zmath.Vec, pos: zmath.Vec, bias: f32) zmath.Vec {
            return (pos + dir * (self.radius + bias));
        }
    };

    box: Box,
    sphere: Sphere,

    pub fn support(self: *const @This(), dir: zmath.Vec, pos: zmath.Vec, rot: zmath.Quat, bias: f32) zmath.Vec {
        switch (self) {
            .box => return self.box.support(dir, pos, rot, bias),
            .sphere => return self.sphere.support(dir, pos, bias),
        }
    }
};

pub fn support(shape1: Shape, pos1: zmath.Vec, rot1: zmath.Quat, shape2: Shape, pos2: zmath.Vec, rot2: zmath.Quat, dir: zmath.Vec, bias: f32) [3]zmath.Vec {
    const norm_dir = zmath.normalize3(dir);

    const pt1 = shape1.support(dir, pos1, rot1, bias);

    norm_dir = zmath.mul(norm_dir, -1.0);

    const pt2 = shape2.support(dir, pos2, rot2, bias);

    return [_]zmath.Vec{ pt1, pt2, pt1 - pt2 };
}

pub fn hasPoint(simplex_points: [4][3]zmath.Vec, pt: [3]zmath.Vec) bool {
    const precision: f32 = 1e-6;

    for (0..4) |i| {
        const delta = simplex_points[i][2] - pt[2];
        if (zmath.lengthSq3(delta) < precision * precision) {
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
            index = i;
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
    const p0 = zmath.mul(normal, zmath.dot3(s1, normal) / zmath.lengthSq3(normal));

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
            index = i;
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
        return areas / area_max;
    }
}

// pub fn simplexSignedVolumes(points: [][3]zmath.Vec, new_dir: zmath.Vec) struct { does_intersect: bool, lambdas: zmath.Vec } {
//     const epsilonf = 0.0001 * 0.0001;

//     var lambdas = zmath.Vec{0.0, 0.0, 0.0, 0.0};

//     var does_intersect = false;

//     switch (points.len) {
//         2 => {
//             Vec2 lambdas = SignedVolume1D( pts[ 0 ].xyz, pts[ 1 ].xyz );
// 			Vec3 v( 0.0f );
// 			for ( int i = 0; i < 2; i++ ) {
// 				v += pts[ i ].xyz * lambdas[ i ];
// 			}
// 			newDir = v * -1.0f;
// 			doesIntersect = ( v.GetLengthSqr() < epsilonf );
// 			lambdasOut[ 0 ] = lambdas[ 0 ];
// 			lambdasOut[ 1 ] = lambdas[ 1 ];
//         }
//     }
// }

// pub fn intersect(shape1: Shape, pos1: zmath.Vec, rot1: zmath.Quat, shape2: Shape, pos2: zmath.Vec, rot2: zmath.Quat) bool {
//     const origin: zmath.Vec = .{ 0.0, 0.0, 0.0, 1.0 };

//     var num_pts: u32 = 1;
//     var simplex_points: [4][3]zmath.Vec = undefined;

//     simplex_points[0] = support(shape1, pos1, rot1, shape2, pos2, rot2, .{ 1.0, 1.0, 1.0, 1.0 }, 0.0);

//     var closest_dist = std.math.floatMax(f32);
//     var contains_origin = false;
//     var new_dir = zmath.mul(simplex_points[0][2], -1.0);

//     while (true) {
//         const new_pt = support(shape1, pos1, rot1, shape2, pos2, rot2, new_dir, 0.0);

//         if (hasPoint(simplex_points, new_pt)) break;

//         simplex_points[num_pts] = new_pt;
//         num_pts += 1;

//         const dotdot = zmath.dot3(new_dir, new_pt[2] - origin);
//         if (dotdot < 0.0) break;

//         var lambdas: zmath.Vec = undefined;

//         if (contains_origin) break;
//     }
// }
