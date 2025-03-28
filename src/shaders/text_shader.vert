// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

struct Character {
    mat3 transform;
    uint character;
};

layout(std140, binding = 0) readonly buffer Characters {
    Character characters[];
} characters;

layout(location = 0) out vec2 frag_uv;

const vec2 vertex_positions[] = {
        vec2(0.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(1.0, 0.0),
        vec2(1.0, 1.0),
        vec2(0.0, 1.0),
    };

const vec2 vertex_uv_map[] = {
        vec2(0.0, 0.0),
        vec2(0.01075268817, 0.0),
        vec2(0.0, 1.0),
        vec2(0.01075268817, 0.0),
        vec2(0.01075268817, 1.0),
        vec2(0.0, 1.0),
    };

void main() {
    Character character = characters.characters[gl_InstanceIndex];

    vec2 uv = vertex_uv_map[gl_VertexIndex];
    float uv_offset = 0.01075268817 * character.character;

    frag_uv = vec2(uv.x + uv_offset, uv.y);
    gl_Position = vec4((character.transform * vec3(vertex_positions[gl_VertexIndex], 1.0)).xy, 0.5, 1.0);
}
