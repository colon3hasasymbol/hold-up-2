#version 450

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;

layout(location = 0) out vec2 frag_uv;

layout(push_constant) uniform Push {
    mat4 vp;
} push;

void main() {
    frag_uv = uv;
    gl_Position = push.vp * vec4(position, 1.0);
}
