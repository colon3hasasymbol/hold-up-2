// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(location = 0) in vec2 frag_uv;

layout(location = 0) out vec4 out_color;

layout(binding = 0) uniform sampler2D u_tex;

void main() {
    out_color = texture(u_tex, frag_uv);
}
