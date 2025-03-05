// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(push_constant) uniform Push {
    mat4 inverse_vp;
    float near_plane;
    float far_plane;
} push;

layout(location = 0) out vec3 ray_origin;
layout(location = 1) out vec3 ray_direction;

vec2 positions[6] = vec2[](vec2(-1.0, -1.0), vec2(-1.0, 1.0), vec2(1.0, 1.0), vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(1.0, 1.0));

void main() {
    vec2 pos = positions[gl_VertexIndex];

    vec4 far_plane = push.inverse_vp * vec4(pos, push.near_plane, 1.0);
    vec4 near_plane = push.inverse_vp * vec4(pos, push.far_plane, 1.0);

    far_plane /= far_plane.w;
    near_plane /= near_plane.w;

    ray_origin = near_plane.xyz;
    ray_direction = (far_plane.xyz - near_plane.xyz);

    gl_Position = vec4(pos, 0.0, 1.0);
}
