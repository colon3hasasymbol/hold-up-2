# Copyright 2025-Present Felix Sapora. All rights reserved.

glslc src/shaders/simple_shader.frag -o src/shaders/simple_shader.frag.spv
glslc src/shaders/simple_shader.vert -o src/shaders/simple_shader.vert.spv
glslc src/shaders/ray_marching.frag -o src/shaders/ray_marching.frag.spv
glslc src/shaders/ray_marching.vert -o src/shaders/ray_marching.vert.spv
glslc src/shaders/lighting_shader.frag -o src/shaders/lighting_shader.frag.spv
glslc src/shaders/lighting_shader.vert -o src/shaders/lighting_shader.vert.spv
