#version 450

layout(location = 0) in vec3 ray_origin;
layout(location = 1) in vec3 ray_direction;

layout(location = 0) out vec4 outColor;

float sphereSDF(vec3 p) {
    return length(p - vec3(0.0, 0.0, -10.0)) - 1.0;
}

void main() {
    outColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 rd = normalize(ray_direction);

    vec3 p = ray_origin;
    for (int i = 0; i < 50; i++) {
        float dist = sphereSDF(p);
        if (dist < 0.001) {
            outColor = vec4(1.0, 0.0, 0.0, 1.0);
            break;
        }
        p += rd * dist;
    }
}
