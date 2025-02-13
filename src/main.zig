const std = @import("std");
const zmath = @import("zmath");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_vulkan.h");
});

const vk = @import("vulkan.zig");
const gx = @import("graphics.zig");
const px = @import("physics.zig");

pub const GameWorld = struct {
    pub const Object = struct {
        model: ?*gx.Model,
        transform: ?[2]zmath.Vec,
        aabb: ?px.LockedCube,
    };

    objects: std.StringHashMap(Object),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        return .{
            .objects = std.StringHashMap(Object).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.objects.deinit();
    }

    pub fn spawn(self: *@This(), object: Object, name: []const u8) !void {
        if (self.objects.contains(name)) return error.ObjectNameUnavailable;
        try self.objects.put(name, object);
    }

    pub fn kill(self: *@This(), name: []u8) !void {
        if (!self.objects.remove(name)) return error.ObjectNonExistent;
    }
};

pub fn conventional(allocator: std.mem.Allocator) !void {
    var game_world = try GameWorld.init(allocator);
    defer game_world.deinit();

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

    var pipeline = try vk.Pipeline.init(&logical_device, pipeline_layout, swapchain.render_pass, &frag_shader, &vert_shader, window_extent, gx.Model.Vertex.getAttributeDescriptions(), gx.Model.Vertex.getBindingDescriptions(), null);
    defer pipeline.deinit();

    window.show();

    var is_colliding = false;
    var was_colliding = true;

    var shape = px.LockedCube.cube1x1();
    shape.max[2] = 4.0;
    shape.min[2] = 0.0;
    const vertices = shape.vertices();

    var triangle_model = try gx.Model.init(&logical_device, &vertices, null);

    try game_world.spawn(.{ .transform = .{ .{ 10.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } }, .model = &triangle_model, .aabb = shape }, "cube0");
    try game_world.spawn(.{ .transform = .{ .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } }, .model = &triangle_model, .aabb = shape }, "cube1");

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
        i: bool,
        j: bool,
        k: bool,
        l: bool,
    };

    var keyboard = std.mem.zeroes(Keyboard);

    var camera_position: zmath.Vec = .{ 0.0, 0.0, 0.0, 1.0 };
    var camera_rotation: zmath.Vec = .{ 0.0, 0.0, 0.0, 0.0 };

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
                        c.SDLK_i => keyboard.i = false,
                        c.SDLK_j => keyboard.j = false,
                        c.SDLK_k => keyboard.k = false,
                        c.SDLK_l => keyboard.l = false,

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
                        c.SDLK_i => keyboard.i = true,
                        c.SDLK_j => keyboard.j = true,
                        c.SDLK_k => keyboard.k = true,
                        c.SDLK_l => keyboard.l = true,

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

        const image_index = try swapchain.acquireNextImage();
        var command_buffer = command_buffers[image_index];

        try command_buffer.begin();

        swapchain.beginRenderPass(&command_buffer, image_index, .{ .r = 0.0, .g = 0.4, .b = 0.6, .a = 1.0 });

        pipeline.bind(&command_buffer);

        var object_iterator = game_world.objects.iterator();
        while (object_iterator.next()) |*object| {
            if (object.value_ptr.model) |model| {
                if (object.value_ptr.transform) |transform| {
                    const object_to_world = zmath.mul(zmath.translation(transform[0][0], transform[0][1], transform[0][2]), zmath.matFromRollPitchYaw(transform[1][0], transform[1][1], transform[1][2]));
                    push_constant_data.vp = zmath.mul(object_to_world, world_to_clip);
                } else {
                    push_constant_data.vp = world_to_clip;
                }
                command_buffer.pushConstants(pipeline_layout, vk.ShaderStage.VERTEX_BIT, &push_constant_data);
                model.bind(&command_buffer);
                model.draw(&command_buffer);
            }
        }

        swapchain.endRenderPass(&command_buffer);

        try command_buffer.end();

        try swapchain.submitCommandBuffers(&command_buffer, image_index);

        const cube0 = game_world.objects.getPtr("cube0").?;
        const cube1 = game_world.objects.getPtr("cube1").?;

        var cube0position = &cube0.transform.?[0];
        const cube1position = cube1.transform.?[0];

        if (keyboard.i) cube0position[2] -= 0.1;
        if (keyboard.k) cube0position[2] += 0.1;
        if (keyboard.j) cube0position[0] -= 0.1;
        if (keyboard.l) cube0position[0] += 0.1;

        const cube0aabb = cube0.aabb.?;
        const cube1aabb = cube1.aabb.?;

        is_colliding = cube0aabb.translate(cube0position.*).overlapping(cube1aabb.translate(cube1position));

        if (was_colliding and !is_colliding) {
            std.debug.print("is_colliding: false\n", .{});
        }
        if (is_colliding and !was_colliding) {
            std.debug.print("is_colliding: true\n", .{});
        }
        was_colliding = is_colliding;
    }
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    try conventional(allocator);
}
