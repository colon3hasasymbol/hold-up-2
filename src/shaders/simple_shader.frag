// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(location = 0) in vec2 frag_uv;

layout(location = 0) out vec4 out_color;

void main() {
    out_color = vec4(frag_uv, 0.0, 1.0);
}
