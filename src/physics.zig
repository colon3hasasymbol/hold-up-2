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

// pub fn intersect(shape1: Shape, pos1: zmath.Vec, rot1: zmath.Quat, shape2: Shape, pos2: zmath.Vec, rot2: zmath.Quat) bool {}
