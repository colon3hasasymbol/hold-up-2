// Copyright 2025-Present Felix Sapora. All rights reserved.

#version 450

layout(location = 0) in vec3 ray_origin;
layout(location = 1) in vec3 ray_direction;

layout(location = 0) out vec4 outColor;

const vec3 LIGHT_COLOR = vec3(1.0, 1.0, 1.0);
const vec3 LIGHT_LOCATION = vec3(2.5, 2.5, -1.0);

float sphereSDF(vec3 p, vec3 n, float r) {
    return length(p - n) - r;
}

float planeSDF(vec3 p, vec3 n, float h) {
    return dot(p, n) + h;
}

float cubeSDF(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sceneSDF(vec3 p) {
    return min(sphereSDF(p, vec3(0.0, 0.0, 10.0), 1.0), cubeSDF(p - vec3(0.0, -5.0, 0.0), vec3(1.0, 1.0, 1.0)));
}

vec3 calcNormal(vec3 pos) {
    vec3 eps = vec3(0.005, 0.0, 0.0);
    return normalize(vec3(
            sceneSDF(pos + eps.xyy) - sceneSDF(pos - eps.xyy),
            sceneSDF(pos + eps.yxy) - sceneSDF(pos - eps.yxy),
            sceneSDF(pos + eps.yyx) - sceneSDF(pos - eps.yyx)
        ));
}

void main() {
    outColor = vec4(0.0, 0.0, 0.0, 1.0);

    vec3 rd = normalize(ray_direction);

    vec3 p = ray_origin;
    for (int i = 0; i < 50; i++) {
        float dist = sceneSDF(p);
        if (dist < 0.001) {
            vec3 normal = calcNormal(p);
            float light_strength = max(0.0, dot(normalize(LIGHT_LOCATION), normal));
            vec3 light = LIGHT_COLOR * light_strength;
            outColor = vec4(vec3(1.0, 1.0, 1.0) * light, 1.0);
            break;
        }
        p += rd * dist;
    }
}
