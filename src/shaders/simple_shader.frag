// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(location = 0) in vec2 frag_uv;
layout(location = 1) in vec3 frag_pos;
layout(location = 2) in vec3 frag_norm;
layout(location = 3) in vec3 frag_tan;

layout(location = 0) out vec4 out_color;
layout(location = 1) out vec4 out_pos;
layout(location = 2) out vec4 out_norm;

layout(binding = 0) uniform sampler2D u_tex;
layout(binding = 1) uniform sampler2D u_norm;

void main() {
    out_color = texture(u_tex, frag_uv);
    out_pos = vec4(frag_pos, 1.0);

    vec3 N = normalize(frag_norm);
    vec3 T = normalize(frag_tan);
    vec3 B = cross(N, T);
    mat3 TBN = mat3(T, B, N);
    vec3 tnorm = TBN * normalize(texture(u_norm, frag_uv).xyz * 2.0 - vec3(1.0));
    out_norm = vec4(tnorm, 1.0);
    // out_color = vec4(gl_FragCoord.zzz, 1.0);
}
