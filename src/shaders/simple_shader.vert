// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec3 normal;
layout(location = 3) in vec3 tangent;

layout(location = 0) out vec2 frag_uv;
layout(location = 1) out vec3 frag_pos;
layout(location = 2) out vec3 frag_norm;
layout(location = 3) out vec3 frag_tan;

layout(push_constant) uniform Push {
    mat4 vp;
    mat4 model;
} push;

void main() {
    frag_uv = uv;

    vec3 world_pos = push.model * vec4(position, 1.0);

    frag_pos = world_pos;

    mat3 mNormal = transpose(inverse(mat3(push.model)));
    frag_norm = mNormal * normalize(normal);

    gl_Position = push.vp * vec4(world_pos, 1.0);
}
