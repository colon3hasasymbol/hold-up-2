const std = @import("std");
const zmath = @import("zmath");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_vulkan.h");
});

const vk = @import("vulkan.zig");

pub fn raymarch(allocator: std.mem.Allocator) !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
        return error.SDLInitVideo;
    }
    defer c.SDL_Quit();

    var vulkan_library = try vk.Library.init();
    defer vulkan_library.deinit();

    var window = try vk.Window.init("the unqeustionable");
    defer window.deinit();

    const extensions = try window.getRequiredExtensions(allocator);
    defer allocator.free(extensions);

    var instance = try vk.Instance.init(extensions, &vulkan_library, null);
    defer instance.deinit();

    var surface = try vk.Surface.init(&instance, &window);
    defer surface.deinit();

    const physical_device = try instance.requestPhysicalDevice(allocator, &surface);

    var logical_device = try physical_device.createLogicalDevice(null);
    defer logical_device.deinit();

    var swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
    defer swapchain.deinit();

    var command_pool = try logical_device.createCommandPool(physical_device.graphics_queue_family_index, allocator, null);
    defer command_pool.deinit();

    const command_buffers = try command_pool.allocate(swapchain.color_images.len, allocator);
    defer allocator.free(command_buffers);

    const window_extent = window.getExtent();

    const PushConstantData = struct {
        inverse_vp: zmath.Mat,
        near_plane: f32,
        far_plane: f32,
    };

    const pipeline_layout = try vk.Pipeline.createLayout(&logical_device, PushConstantData, null);
    defer vk.Pipeline.destroyLayout(&logical_device, pipeline_layout, null);

    const frag_spv align(@alignOf(u32)) = @embedFile("shaders/ray_marching.frag.spv").*;
    const vert_spv align(@alignOf(u32)) = @embedFile("shaders/ray_marching.vert.spv").*;

    var frag_shader = try vk.ShaderModule.init(&logical_device, &frag_spv, null);
    defer frag_shader.deinit();

    var vert_shader = try vk.ShaderModule.init(&logical_device, &vert_spv, null);
    defer vert_shader.deinit();

    var pipeline = try vk.Pipeline.init(&logical_device, pipeline_layout, swapchain.render_pass, &frag_shader, &vert_shader, window_extent, &[_]c.VkVertexInputAttributeDescription{}, &[_]c.VkVertexInputBindingDescription{}, null);
    defer pipeline.deinit();

    window.show();

    const Keyboard = struct {
        w: bool,
        a: bool,
        s: bool,
        d: bool,
        space: bool,
        lshift: bool,
        up: bool,
        down: bool,
        right: bool,
        left: bool,
    };

    var keyboard = std.mem.zeroes(Keyboard);

    var camera_position: @Vector(3, f32) = .{ 0.0, 0.0, 0.0 };
    var camera_rotation: @Vector(3, f32) = .{ 0.0, 0.0, 0.0 };

    var push_constant_data = PushConstantData{
        .inverse_vp = zmath.inverse(zmath.perspectiveFovLh(90.0, 1.0, 1.0, 100.0)),
        .near_plane = 1.0,
        .far_plane = 100.0,
    };

    main_loop: while (true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) == c.SDL_TRUE) {
            switch (event.type) {
                c.SDL_QUIT => {
                    try logical_device.waitIdle();
                    break :main_loop;
                },
                c.SDL_WINDOWEVENT => switch (event.window.event) {
                    c.SDL_WINDOWEVENT_RESIZED => {
                        swapchain.deinit();
                        swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
                    },
                    else => {},
                },
                c.SDL_KEYUP => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_w => keyboard.w = false,
                        c.SDLK_a => keyboard.a = false,
                        c.SDLK_s => keyboard.s = false,
                        c.SDLK_d => keyboard.d = false,
                        c.SDLK_SPACE => keyboard.space = false,
                        c.SDLK_LSHIFT => keyboard.lshift = false,
                        c.SDLK_UP => keyboard.up = false,
                        c.SDLK_DOWN => keyboard.down = false,
                        c.SDLK_RIGHT => keyboard.right = false,
                        c.SDLK_LEFT => keyboard.left = false,

                        else => {},
                    }
                },
                c.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_w => keyboard.w = true,
                        c.SDLK_a => keyboard.a = true,
                        c.SDLK_s => keyboard.s = true,
                        c.SDLK_d => keyboard.d = true,
                        c.SDLK_SPACE => keyboard.space = true,
                        c.SDLK_LSHIFT => keyboard.lshift = true,
                        c.SDLK_UP => keyboard.up = true,
                        c.SDLK_DOWN => keyboard.down = true,
                        c.SDLK_RIGHT => keyboard.right = true,
                        c.SDLK_LEFT => keyboard.left = true,

                        else => {},
                    }
                },
                else => {},
            }
        }

        if (keyboard.w) camera_position[2] -= 0.1;
        if (keyboard.s) camera_position[2] += 0.1;
        if (keyboard.d) camera_position[0] -= 0.1;
        if (keyboard.a) camera_position[0] += 0.1;
        if (keyboard.lshift) camera_position[1] -= 0.1;
        if (keyboard.space) camera_position[1] += 0.1;

        if (keyboard.up) camera_rotation[0] -= 0.01;
        if (keyboard.down) camera_rotation[0] += 0.01;
        if (keyboard.right) camera_rotation[1] -= 0.01;
        if (keyboard.left) camera_rotation[1] += 0.01;

        push_constant_data.inverse_vp = zmath.translation(camera_position[0], camera_position[1], camera_position[2]);
        push_constant_data.inverse_vp = zmath.mul(push_constant_data.inverse_vp, zmath.rotationY(camera_rotation[1]));
        push_constant_data.inverse_vp = zmath.mul(push_constant_data.inverse_vp, zmath.rotationX(camera_rotation[0]));
        push_constant_data.inverse_vp = zmath.mul(push_constant_data.inverse_vp, zmath.perspectiveFovLh(90.0, 1.0, 1.0, 100.0));
        push_constant_data.inverse_vp = zmath.inverse(push_constant_data.inverse_vp);

        const image_index = try swapchain.acquireNextImage();
        var command_buffer = command_buffers[image_index];
        const frame_buffer = swapchain.frame_buffers[image_index];

        try command_buffer.begin();

        const clear_values = [_]c.VkClearValue{
            c.VkClearValue{
                .color = c.VkClearColorValue{ .float32 = .{ 1.0, 0.0, 0.0, 1.0 } },
            },
            c.VkClearValue{
                .depthStencil = c.VkClearDepthStencilValue{ .depth = 0.0, .stencil = 0 },
            },
        };

        const render_pass_info = std.mem.zeroInit(c.VkRenderPassBeginInfo, c.VkRenderPassBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
            .renderPass = swapchain.render_pass,
            .framebuffer = frame_buffer,
            .renderArea = c.VkRect2D{
                .offset = c.VkOffset2D{ .x = 0, .y = 0 },
                .extent = window_extent,
            },
            .clearValueCount = @intCast(clear_values.len),
            .pClearValues = &clear_values,
        });

        logical_device.dispatch.CmdBeginRenderPass(command_buffer.handle, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);

        pipeline.bind(&command_buffer);

        command_buffer.pushConstants(pipeline_layout, c.VK_SHADER_STAGE_VERTEX_BIT, &push_constant_data);

        logical_device.dispatch.CmdDraw(command_buffer.handle, 6, 1, 0, 0);

        logical_device.dispatch.CmdEndRenderPass(command_buffer.handle);

        try command_buffer.end();

        try swapchain.submitCommandBuffers(&command_buffer, image_index);
    }
}

pub fn conventional(allocator: std.mem.Allocator) !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
        return error.SDLInitVideo;
    }
    defer c.SDL_Quit();

    var vulkan_library = try vk.Library.init();
    defer vulkan_library.deinit();

    var window = try vk.Window.init("the unqeustionable");
    defer window.deinit();

    const extensions = try window.getRequiredExtensions(allocator);
    defer allocator.free(extensions);

    var instance = try vk.Instance.init(extensions, &vulkan_library, null);
    defer instance.deinit();

    var surface = try vk.Surface.init(&instance, &window);
    defer surface.deinit();

    const physical_device = try instance.requestPhysicalDevice(allocator, &surface);

    var logical_device = try physical_device.createLogicalDevice(null);
    defer logical_device.deinit();

    var swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
    defer swapchain.deinit();

    var command_pool = try logical_device.createCommandPool(physical_device.graphics_queue_family_index, allocator, null);
    defer command_pool.deinit();

    const command_buffers = try command_pool.allocate(swapchain.color_images.len, allocator);
    defer allocator.free(command_buffers);

    const window_extent = window.getExtent();

    const PushConstantData = struct {
        vp: zmath.Mat,
    };

    const pipeline_layout = try vk.Pipeline.createLayout(&logical_device, PushConstantData, null);
    defer vk.Pipeline.destroyLayout(&logical_device, pipeline_layout, null);

    const frag_spv align(@alignOf(u32)) = @embedFile("shaders/simple_shader.frag.spv").*;
    const vert_spv align(@alignOf(u32)) = @embedFile("shaders/simple_shader.vert.spv").*;

    var frag_shader = try vk.ShaderModule.init(&logical_device, &frag_spv, null);
    defer frag_shader.deinit();

    var vert_shader = try vk.ShaderModule.init(&logical_device, &vert_spv, null);
    defer vert_shader.deinit();

    var pipeline = try vk.Pipeline.init(&logical_device, pipeline_layout, swapchain.render_pass, &frag_shader, &vert_shader, window_extent, vk.Model.Vertex.getAttributeDescriptions(), vk.Model.Vertex.getBindingDescriptions(), null);
    defer pipeline.deinit();

    window.show();

    const vertices = [_]vk.Model.Vertex{
        vk.Model.Vertex{
            .position = .{ 0.0, -0.5, 0.5 },
            .uv = .{ 0.0, 1.0 },
        },
        vk.Model.Vertex{
            .position = .{ 0.5, 0.5, 0.5 },
            .uv = .{ 1.0, 0.0 },
        },
        vk.Model.Vertex{
            .position = .{ -0.5, 0.5, 0.5 },
            .uv = .{ 1.0, 1.0 },
        },
    };

    var model = try vk.Model.init(&logical_device, &vertices, null);

    const Keyboard = struct {
        w: bool,
        a: bool,
        s: bool,
        d: bool,
        space: bool,
        lshift: bool,
        up: bool,
        down: bool,
        right: bool,
        left: bool,
    };

    var keyboard = std.mem.zeroes(Keyboard);

    var camera_position: zmath.F32x4 = .{ 0.0, 0.0, 0.0, 1.0 };
    var camera_rotation: @Vector(3, f32) = .{ 0.0, 0.0, 0.0 };

    var push_constant_data = PushConstantData{
        .vp = zmath.identity(),
    };

    main_loop: while (true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) == c.SDL_TRUE) {
            switch (event.type) {
                c.SDL_QUIT => {
                    try logical_device.waitIdle();
                    break :main_loop;
                },
                c.SDL_WINDOWEVENT => switch (event.window.event) {
                    c.SDL_WINDOWEVENT_RESIZED => {
                        swapchain.deinit();
                        swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
                    },
                    else => {},
                },
                c.SDL_KEYUP => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_w => keyboard.w = false,
                        c.SDLK_a => keyboard.a = false,
                        c.SDLK_s => keyboard.s = false,
                        c.SDLK_d => keyboard.d = false,
                        c.SDLK_SPACE => keyboard.space = false,
                        c.SDLK_LSHIFT => keyboard.lshift = false,
                        c.SDLK_UP => keyboard.up = false,
                        c.SDLK_DOWN => keyboard.down = false,
                        c.SDLK_RIGHT => keyboard.right = false,
                        c.SDLK_LEFT => keyboard.left = false,

                        else => {},
                    }
                },
                c.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        c.SDLK_w => keyboard.w = true,
                        c.SDLK_a => keyboard.a = true,
                        c.SDLK_s => keyboard.s = true,
                        c.SDLK_d => keyboard.d = true,
                        c.SDLK_SPACE => keyboard.space = true,
                        c.SDLK_LSHIFT => keyboard.lshift = true,
                        c.SDLK_UP => keyboard.up = true,
                        c.SDLK_DOWN => keyboard.down = true,
                        c.SDLK_RIGHT => keyboard.right = true,
                        c.SDLK_LEFT => keyboard.left = true,

                        else => {},
                    }
                },
                else => {},
            }
        }

        var camera_movement: zmath.F32x4 = .{ 0.0, 0.0, 0.0, 1.0 };

        if (keyboard.w) camera_movement[2] -= 0.1;
        if (keyboard.s) camera_movement[2] += 0.1;
        if (keyboard.d) camera_movement[0] += 0.1;
        if (keyboard.a) camera_movement[0] -= 0.1;
        if (keyboard.lshift) camera_movement[1] += 0.1;
        if (keyboard.space) camera_movement[1] -= 0.1;

        camera_position += camera_movement;

        if (keyboard.up) camera_rotation[0] += 0.01;
        if (keyboard.down) camera_rotation[0] -= 0.01;
        if (keyboard.right) camera_rotation[1] += 0.01;
        if (keyboard.left) camera_rotation[1] -= 0.01;

        var world_to_view = zmath.inverse(zmath.translation(camera_position[0], camera_position[1], camera_position[2]));
        world_to_view = zmath.mul(world_to_view, zmath.mul(zmath.rotationX(camera_rotation[0]), zmath.rotationY(camera_rotation[1])));

        const view_to_clip = zmath.perspectiveFovRh(0.25 * std.math.pi, 1, 0.1, 200.0);

        const world_to_clip = zmath.mul(world_to_view, view_to_clip);

        push_constant_data.vp = world_to_clip;

        const image_index = try swapchain.acquireNextImage();
        var command_buffer = command_buffers[image_index];

        try command_buffer.begin();

        swapchain.beginRenderPass(&command_buffer, image_index, .{ .r = 0.0, .g = 0.4, .b = 0.6, .a = 1.0 });

        pipeline.bind(&command_buffer);

        command_buffer.pushConstants(pipeline_layout, vk.ShaderStage.VERTEX_BIT, &push_constant_data);

        model.bind(&command_buffer);
        model.draw(&command_buffer);

        swapchain.endRenderPass(&command_buffer);

        try command_buffer.end();

        try swapchain.submitCommandBuffers(&command_buffer, image_index);
    }
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    // try raymarch(allocator);
    try conventional(allocator);
}
