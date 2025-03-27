// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

struct Character {
    mat3 transform;
    uint character;
};

layout(std140, binding = 0) readonly buffer Characters {
    Character characters[];
} characters;

layout(push_constant) uniform Push {
    mat3 text_block_transform;
} push;

layout(location = 0) out vec2 frag_uv;

const vec2 character_uv_map[] = {
        vec2(0.0, 0.0),
        vec2(0.5, 0.0)
    };

void main() {
    Character character = characters.characters[gl_InstanceIndex];

    vec2 uv = vec2((gl_VertexIndex << 1) & 2, gl_VertexIndex & 2);
    vec2 uv_offset = character_uv_map[character.character];

    frag_uv = vec2((uv.x / character_uv_map.length()) + uv_offset.x, uv.y + uv_offset.y);
    gl_Position = vec4(((character.transform * vec3(frag_uv * 2.0f - 1.0f, 1.0f)).xy), 0.0, 1.0);
}
