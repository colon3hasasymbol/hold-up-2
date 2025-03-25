// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(binding = 0) uniform sampler2D u_col;
layout(binding = 1) uniform sampler2D u_pos;
layout(binding = 2) uniform sampler2D u_norm;

layout(location = 0) in vec2 frag_uv;

layout(location = 0) out vec4 out_color;

void main() {
    out_color = texture(u_pos, frag_uv);
}
