// Copyright 2025-Present Felix Sapora. All rights reserved.

const std = @import("std");
const zmath = @import("zmath");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_vulkan.h");
});

const vk = @import("vulkan.zig");
const gx = @import("graphics.zig");
const px = @import("physics.zig");

const AudioLinux = @import("audio_linux.zig");

pub const GameWorld = struct {
    pub const Object = struct {
        model: ?*gx.Model,
        texture: ?*gx.Texture,
        pipeline: ?*vk.Pipeline,
        transform: ?[2]zmath.Vec,
        aabb: ?px.BoundingBox,
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
        const err = c.SDL_GetError();
        c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", err);
        return error.SDLInitVideo;
    }
    defer c.SDL_Quit();

    var vulkan_library = try vk.Library.init();
    defer vulkan_library.deinit();

    var window = try vk.Window.init("the unqeustionable");
    defer window.deinit();

    const extensions = try window.getRequiredExtensions(allocator);
    defer allocator.free(extensions);

    for (extensions) |extension| {
        std.debug.print("{s}", .{extension});
    }

    var instance = try vk.Instance.init(extensions, &vulkan_library, null);
    defer instance.deinit();

    var surface = try vk.Surface.init(&instance, &window);
    defer surface.deinit();

    const physical_device = try instance.requestPhysicalDevice(allocator, &surface);

    var logical_device = try physical_device.createLogicalDevice(null);
    defer logical_device.deinit();

    var swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
    defer swapchain.deinit();

    var command_pool = try logical_device.createCommandPool(physical_device.graphics_queue_family_index, null);
    defer command_pool.deinit();

    const command_buffers = try command_pool.allocate(@intCast(swapchain.color_images.len), allocator);
    defer allocator.free(command_buffers);

    var descriptor_pool = try vk.DescriptorPool.init(&logical_device, @constCast(&[_]vk.c.VkDescriptorPoolSize{.{ .type = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = @intCast((2 * 2) + (3 * swapchain.color_images.len)) }}), @intCast((2 * 2) + (3 * swapchain.color_images.len)), null);
    defer descriptor_pool.deinit();

    const window_extent = window.getExtent();

    var offscreen_albedo = try vk.Image.init(&logical_device, .{ .sType = vk.c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, .imageType = vk.c.VK_IMAGE_TYPE_2D, .format = vk.c.VK_FORMAT_R8G8B8A8_UNORM, .extent = .{ .width = window_extent.x, .height = window_extent.y, .depth = 1 }, .mipLevels = 1, .arrayLayers = 1, .samples = vk.c.VK_SAMPLE_COUNT_1_BIT, .tiling = vk.c.VK_IMAGE_TILING_OPTIMAL, .usage = vk.c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.c.VK_IMAGE_USAGE_SAMPLED_BIT }, null);
    defer offscreen_albedo.deinit();
    try offscreen_albedo.createMemory(vk.MemoryProperty.DEVICE_LOCAL_BIT);
    try offscreen_albedo.createView(vk.ImageViewType.TYPE_2D, vk.c.VK_FORMAT_R8G8B8A8_UNORM, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

    var offscreen_positions = try vk.Image.init(&logical_device, .{ .sType = vk.c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, .imageType = vk.c.VK_IMAGE_TYPE_2D, .format = vk.c.VK_FORMAT_R16G16B16A16_SFLOAT, .extent = .{ .width = window_extent.x, .height = window_extent.y, .depth = 1 }, .mipLevels = 1, .arrayLayers = 1, .samples = vk.c.VK_SAMPLE_COUNT_1_BIT, .tiling = vk.c.VK_IMAGE_TILING_OPTIMAL, .usage = vk.c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.c.VK_IMAGE_USAGE_SAMPLED_BIT }, null);
    defer offscreen_positions.deinit();
    try offscreen_positions.createMemory(vk.MemoryProperty.DEVICE_LOCAL_BIT);
    try offscreen_positions.createView(vk.ImageViewType.TYPE_2D, vk.c.VK_FORMAT_R16G16B16A16_SFLOAT, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

    var offscreen_normals = try vk.Image.init(&logical_device, .{ .sType = vk.c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, .imageType = vk.c.VK_IMAGE_TYPE_2D, .format = vk.c.VK_FORMAT_R16G16B16A16_SFLOAT, .extent = .{ .width = window_extent.x, .height = window_extent.y, .depth = 1 }, .mipLevels = 1, .arrayLayers = 1, .samples = vk.c.VK_SAMPLE_COUNT_1_BIT, .tiling = vk.c.VK_IMAGE_TILING_OPTIMAL, .usage = vk.c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.c.VK_IMAGE_USAGE_SAMPLED_BIT }, null);
    defer offscreen_normals.deinit();
    try offscreen_normals.createMemory(vk.MemoryProperty.DEVICE_LOCAL_BIT);
    try offscreen_normals.createView(vk.ImageViewType.TYPE_2D, vk.c.VK_FORMAT_R16G16B16A16_SFLOAT, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

    const depth_format = try logical_device.findSupportedFormat(&[_]vk.c.VkFormat{ vk.c.VK_FORMAT_D32_SFLOAT, vk.c.VK_FORMAT_D32_SFLOAT_S8_UINT, vk.c.VK_FORMAT_D24_UNORM_S8_UINT }, vk.c.VK_IMAGE_TILING_OPTIMAL, vk.c.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);

    var offscreen_depth = try vk.Image.init(&logical_device, .{ .sType = vk.c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, .imageType = vk.c.VK_IMAGE_TYPE_2D, .format = depth_format, .extent = .{ .width = window_extent.x, .height = window_extent.y, .depth = 1 }, .mipLevels = 1, .arrayLayers = 1, .samples = vk.c.VK_SAMPLE_COUNT_1_BIT, .tiling = vk.c.VK_IMAGE_TILING_OPTIMAL, .usage = vk.c.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT }, null);
    defer offscreen_depth.deinit();
    try offscreen_depth.createMemory(vk.MemoryProperty.DEVICE_LOCAL_BIT);
    try offscreen_depth.createView(vk.ImageViewType.TYPE_2D, depth_format, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_DEPTH_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

    var render_pass = try vk.RenderPass.init(&logical_device, &[_]vk.RenderPass.Attachment{ .{ .format = vk.c.VK_FORMAT_R8G8B8A8_UNORM, .layout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL }, .{ .format = vk.c.VK_FORMAT_R16G16B16A16_SFLOAT, .layout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL }, .{ .format = vk.c.VK_FORMAT_R16G16B16A16_SFLOAT, .layout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL } }, true, true, allocator, null);
    defer render_pass.deinit();

    const attachments = [_]vk.c.VkImageView{
        offscreen_depth.view,
        offscreen_albedo.view,
        offscreen_positions.view,
        offscreen_normals.view,
    };

    const framebuffer_create_info = vk.c.VkFramebufferCreateInfo{
        .sType = vk.c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
        .renderPass = render_pass.handle,
        .pAttachments = &attachments,
        .attachmentCount = @intCast(attachments.len),
        .width = window_extent.x,
        .height = window_extent.y,
        .layers = 1,
    };

    var framebuffer: vk.c.VkFramebuffer = undefined;
    if (logical_device.dispatch.CreateFramebuffer(logical_device.handle, &framebuffer_create_info, null, &framebuffer) < 0) return error.VkCreateFramebuffer;
    defer logical_device.dispatch.DestroyFramebuffer(logical_device.handle, framebuffer, null);

    const color_sampler_create_info = vk.c.VkSamplerCreateInfo{
        .sType = vk.c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
        .magFilter = vk.c.VK_FILTER_NEAREST,
        .minFilter = vk.c.VK_FILTER_NEAREST,
        .mipmapMode = vk.c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
        .addressModeU = vk.c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        .addressModeV = vk.c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        .addressModeW = vk.c.VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
        .mipLodBias = 0.0,
        .maxAnisotropy = 1.0,
        .minLod = 0.0,
        .maxLod = 0.0,
        .borderColor = vk.c.VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE,
    };

    var color_sampler: vk.c.VkSampler = undefined;
    if (logical_device.dispatch.CreateSampler(logical_device.handle, &color_sampler_create_info, null, &color_sampler) < 0) return error.VkCreateSampler;
    defer logical_device.dispatch.DestroySampler(logical_device.handle, color_sampler, null);

    const semaphore_create_info = vk.c.VkSemaphoreCreateInfo{ .sType = vk.c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO };

    var present_semaphore: vk.c.VkSemaphore = undefined;
    if (logical_device.dispatch.CreateSemaphore(logical_device.handle, &semaphore_create_info, null, &present_semaphore) < 0) return error.VkCreateSemaphore;
    defer logical_device.dispatch.DestroySemaphore(logical_device.handle, present_semaphore, null);

    var render_semaphore: vk.c.VkSemaphore = undefined;
    if (logical_device.dispatch.CreateSemaphore(logical_device.handle, &semaphore_create_info, null, &render_semaphore) < 0) return error.VkCreateSemaphore;
    defer logical_device.dispatch.DestroySemaphore(logical_device.handle, render_semaphore, null);

    var offscreen_semaphore: vk.c.VkSemaphore = undefined;
    if (logical_device.dispatch.CreateSemaphore(logical_device.handle, &semaphore_create_info, null, &offscreen_semaphore) < 0) return error.VkCreateSemaphore;
    defer logical_device.dispatch.DestroySemaphore(logical_device.handle, offscreen_semaphore, null);

    const offscreen_command_buffers = try command_pool.allocate(1, allocator);
    const offscreen_command_buffer = offscreen_command_buffers[0];
    allocator.free(offscreen_command_buffers);

    const PushConstantData = struct {
        vp: zmath.Mat,
        object: zmath.Mat,
    };

    const frag_spv align(@alignOf(u32)) = @embedFile("shaders/simple_shader.frag.spv").*;
    const vert_spv align(@alignOf(u32)) = @embedFile("shaders/simple_shader.vert.spv").*;

    var frag_shader = try vk.ShaderModule.init(&logical_device, &frag_spv, null);
    defer frag_shader.deinit();

    var vert_shader = try vk.ShaderModule.init(&logical_device, &vert_spv, null);
    defer vert_shader.deinit();

    var pipeline1 = try vk.Pipeline.init(
        &logical_device,
        PushConstantData,
        @constCast(&[_]vk.c.VkDescriptorSetLayoutBinding{
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 0, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 1, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
        }),
        render_pass.handle,
        @constCast(&[_]vk.c.VkPipelineColorBlendAttachmentState{
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
        }),
        vk.c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        vk.c.VK_POLYGON_MODE_FILL,
        &frag_shader,
        &vert_shader,
        window_extent,
        gx.Model.Vertex.getAttributeDescriptions(),
        gx.Model.Vertex.getBindingDescriptions(),
        null,
    );
    defer pipeline1.deinit();

    var pipeline2 = try vk.Pipeline.init(
        &logical_device,
        PushConstantData,
        @constCast(&[_]vk.c.VkDescriptorSetLayoutBinding{
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 0, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 1, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
        }),
        render_pass.handle,
        @constCast(&[_]vk.c.VkPipelineColorBlendAttachmentState{
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
        }),
        vk.c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        vk.c.VK_POLYGON_MODE_LINE,
        &frag_shader,
        &vert_shader,
        window_extent,
        gx.Model.Vertex.getAttributeDescriptions(),
        gx.Model.Vertex.getBindingDescriptions(),
        null,
    );
    defer pipeline2.deinit();

    const lighting_frag_spv align(@alignOf(u32)) = @embedFile("shaders/lighting_shader.frag.spv").*;
    const lighting_vert_spv align(@alignOf(u32)) = @embedFile("shaders/lighting_shader.vert.spv").*;

    var lighting_frag_shader = try vk.ShaderModule.init(&logical_device, &lighting_frag_spv, null);
    defer lighting_frag_shader.deinit();

    var lighting_vert_shader = try vk.ShaderModule.init(&logical_device, &lighting_vert_spv, null);
    defer lighting_vert_shader.deinit();

    var lighting_pipeline = try vk.Pipeline.init(
        &logical_device,
        PushConstantData,
        @constCast(&[_]vk.c.VkDescriptorSetLayoutBinding{
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 0, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 1, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
            std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 2, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
        }),
        swapchain.render_pass.handle,
        @constCast(&[_]vk.c.VkPipelineColorBlendAttachmentState{
            .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
        }),
        vk.c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        vk.c.VK_POLYGON_MODE_FILL,
        &lighting_frag_shader,
        &lighting_vert_shader,
        window_extent,
        &[_]vk.c.VkVertexInputAttributeDescription{},
        &[_]vk.c.VkVertexInputBindingDescription{},
        null,
    );

    defer lighting_pipeline.deinit();

    const offsceen_descriptors = try descriptor_pool.allocate(&lighting_pipeline, @intCast(swapchain.color_images.len), allocator);
    defer allocator.free(offsceen_descriptors);

    for (0..swapchain.color_images.len) |i| {
        const color_image_info = vk.c.VkDescriptorImageInfo{
            .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .imageView = offscreen_albedo.view,
            .sampler = color_sampler,
        };

        const color_descriptor_write = vk.c.VkWriteDescriptorSet{
            .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = offsceen_descriptors[i],
            .dstBinding = 0,
            .dstArrayElement = 0,
            .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1,
            .pImageInfo = &color_image_info,
        };

        const position_image_info = vk.c.VkDescriptorImageInfo{
            .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .imageView = offscreen_positions.view,
            .sampler = color_sampler,
        };

        const position_descriptor_write = vk.c.VkWriteDescriptorSet{
            .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = offsceen_descriptors[i],
            .dstBinding = 1,
            .dstArrayElement = 0,
            .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1,
            .pImageInfo = &position_image_info,
        };

        const normal_image_info = vk.c.VkDescriptorImageInfo{
            .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            .imageView = offscreen_normals.view,
            .sampler = color_sampler,
        };

        const normal_descriptor_write = vk.c.VkWriteDescriptorSet{
            .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
            .dstSet = offsceen_descriptors[i],
            .dstBinding = 2,
            .dstArrayElement = 0,
            .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1,
            .pImageInfo = &normal_image_info,
        };

        const descriptor_writes = [_]vk.c.VkWriteDescriptorSet{
            color_descriptor_write,
            position_descriptor_write,
            normal_descriptor_write,
        };

        logical_device.dispatch.UpdateDescriptorSets(logical_device.handle, @intCast(descriptor_writes.len), &descriptor_writes, 0, null);
    }

    // for (command_buffers, 0..) |*command_buffer, i| {
    //     try command_buffer.begin();

    //     swapchain.beginRenderPass(command_buffer, @intCast(i), .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 });

    //     lighting_pipeline.bind(command_buffer);

    //     logical_device.dispatch.CmdBindDescriptorSets(command_buffer.handle, vk.c.VK_PIPELINE_BIND_POINT_GRAPHICS, lighting_pipeline.layout, 0, 1, &offsceen_descriptors[i], 0, null);

    //     logical_device.dispatch.CmdDraw(command_buffer.handle, 6, 1, 0, 0);

    //     swapchain.endRenderPass(command_buffer);

    //     try command_buffer.end();
    // }

    var texture1 = try gx.Texture.init(&logical_device, &command_pool, &pipeline1, &descriptor_pool, 1, "textures/the f word :3.png", allocator, null);
    defer texture1.deinit();

    var texture2 = try gx.Texture.init(&logical_device, &command_pool, &pipeline1, &descriptor_pool, 1, "textures/map.png", allocator, null);
    defer texture2.deinit();

    var shape = px.BoundingBox.cube1x1();
    // shape.max[2] = 2.0;
    // shape.min[2] = -2.0;
    const vertices = shape.vertices();
    const indices = px.BoundingBox.indices();

    var triangle_model = try gx.Model.init(&logical_device, &vertices, &indices, null);
    defer triangle_model.deinit();

    try game_world.spawn(.{ .transform = .{ .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } }, .model = &triangle_model, .texture = &texture1, .pipeline = &pipeline1, .aabb = shape }, "segment1");
    try game_world.spawn(.{ .transform = .{ .{ 2.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } }, .model = &triangle_model, .texture = &texture2, .pipeline = &pipeline2, .aabb = shape }, "segment0");
    // try game_world.spawn(.{ .transform = .{ .{ 0.0, 8.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } }, .model = &triangle_model, .aabb = shape }, "segment2");

    // const start = zmath.Vec{ 0.0, 0.0, 0.0, 0.0 };
    // const end = zmath.Vec{ 8.5, 0.0, 0.0, 0.0 };

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
        n: bool,
        m: bool,
    };

    var keyboard = std.mem.zeroes(Keyboard);

    var camera_position: zmath.Vec = .{ 0.0, 0.0, 0.0, 1.0 };
    var camera_rotation: zmath.Vec = .{ 0.0, 0.0, 0.0, 0.0 };

    var push_constant_data = PushConstantData{
        .vp = zmath.identity(),
        .object = zmath.identity(),
    };

    var old_colliding = false;

    window.show();

    main_loop: while (true) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) == c.SDL_TRUE) {
            switch (event.type) {
                c.SDL_QUIT => {
                    try logical_device.waitIdle();
                    break :main_loop;
                },
                // c.SDL_WINDOWEVENT => switch (event.window.event) {
                //     c.SDL_WINDOWEVENT_RESIZED => {
                //         swapchain.deinit();
                //         swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
                //     },
                //     else => {},
                // },
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
                        c.SDLK_n => keyboard.n = false,
                        c.SDLK_m => keyboard.m = false,

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
                        c.SDLK_n => keyboard.n = true,
                        c.SDLK_m => keyboard.m = true,
                        c.SDLK_ESCAPE => {
                            try logical_device.waitIdle();
                            break :main_loop;
                        },

                        else => {},
                    }
                },
                else => {},
            }
        }
        var camera_movement: zmath.F32x4 = .{ 0.0, 0.0, 0.0, 1.0 };

        if (keyboard.w) camera_movement[2] -= 0.01;
        if (keyboard.s) camera_movement[2] += 0.01;
        if (keyboard.d) camera_movement[0] += 0.01;
        if (keyboard.a) camera_movement[0] -= 0.01;
        if (keyboard.lshift) camera_movement[1] += 0.01;
        if (keyboard.space) camera_movement[1] -= 0.01;

        camera_movement = zmath.mul(zmath.rotationY(camera_rotation[1]), camera_movement);

        camera_position += camera_movement;

        if (keyboard.up) camera_rotation[0] += 0.001;
        if (keyboard.down) camera_rotation[0] -= 0.001;
        if (keyboard.right) camera_rotation[1] += 0.001;
        if (keyboard.left) camera_rotation[1] -= 0.001;

        var world_to_view = zmath.inverse(zmath.translation(camera_position[0], camera_position[1], camera_position[2]));
        world_to_view = zmath.mul(world_to_view, zmath.mul(zmath.rotationY(camera_rotation[1]), zmath.rotationX(camera_rotation[0])));

        const view_to_clip = zmath.perspectiveFovRh(0.25 * std.math.pi, 1, 0.1, 200.0);

        const world_to_clip = zmath.mul(world_to_view, view_to_clip);

        var image_index: u32 = undefined;
        if (logical_device.dispatch.AcquireNextImageKHR(logical_device.handle, swapchain.handle, std.math.maxInt(u64), present_semaphore, @ptrCast(vk.c.VK_NULL_HANDLE), &image_index) < 0) return error.VkAcquireNextImage;

        // const image_index = try swapchain.acquireNextImage();
        var command_buffer = offscreen_command_buffer;

        try command_buffer.begin();

        // swapchain.beginRenderPass(&command_buffer, image_index, .{ .r = 0.0, .g = 0.4, .b = 0.6, .a = 1.0 });

        const clear_values = [_]vk.c.VkClearValue{
            .{ .depthStencil = .{ .depth = 1.0, .stencil = 0 } },
            .{ .color = .{ .float32 = .{ 0.0, 0.75, 1.0, 1.0 } } },
            .{ .color = .{ .float32 = .{ 0.0, 0.75, 1.0, 1.0 } } },
            .{ .color = .{ .float32 = .{ 0.0, 0.75, 1.0, 1.0 } } },
        };

        const render_pass_begin_info = vk.c.VkRenderPassBeginInfo{
            .sType = vk.c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
            .renderPass = render_pass.handle,
            .framebuffer = framebuffer,
            .renderArea = .{ .extent = .{ .width = window_extent.x, .height = window_extent.y } },
            .clearValueCount = @intCast(clear_values.len),
            .pClearValues = &clear_values,
        };

        logical_device.dispatch.CmdBeginRenderPass(command_buffer.handle, &render_pass_begin_info, vk.c.VK_SUBPASS_CONTENTS_INLINE);

        const viewport = vk.c.VkViewport{
            .width = @floatFromInt(window_extent.x),
            .height = @floatFromInt(window_extent.y),
            .minDepth = 0.0,
            .maxDepth = 1.0,
        };

        logical_device.dispatch.CmdSetViewport(command_buffer.handle, 0, 1, &viewport);

        const scissor = vk.c.VkRect2D{ .extent = .{ .width = window_extent.x, .height = window_extent.y } };

        logical_device.dispatch.CmdSetScissor(command_buffer.handle, 0, 1, &scissor);

        var object_iterator = game_world.objects.iterator();
        while (object_iterator.next()) |*object| {
            if (object.value_ptr.model) |model| {
                if (object.value_ptr.pipeline) |pipeline| {
                    push_constant_data.vp = world_to_clip;
                    push_constant_data.object = zmath.identity();

                    if (object.value_ptr.transform) |transform| push_constant_data.object = zmath.mul(zmath.matFromRollPitchYaw(transform[1][0], transform[1][1], transform[1][2]), zmath.translation(transform[0][0], transform[0][1], transform[0][2]));

                    if (object.value_ptr.texture) |texture| logical_device.dispatch.CmdBindDescriptorSets(command_buffer.handle, vk.c.VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline.layout, 0, 1, &texture.descriptor_sets[0], 0, null);

                    pipeline.bind(&command_buffer);
                    command_buffer.pushConstants(pipeline.layout, vk.ShaderStage.VERTEX_BIT, &push_constant_data);
                    model.bind(&command_buffer);
                    model.draw(&command_buffer);
                }
            }
        }

        // swapchain.endRenderPass(&command_buffer);

        logical_device.dispatch.CmdEndRenderPass(command_buffer.handle);

        try command_buffer.end();

        var onscreen_command_buffer = command_buffers[image_index];

        try onscreen_command_buffer.begin();

        swapchain.beginRenderPass(&onscreen_command_buffer, image_index, .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 });

        lighting_pipeline.bind(&onscreen_command_buffer);

        logical_device.dispatch.CmdBindDescriptorSets(onscreen_command_buffer.handle, vk.c.VK_PIPELINE_BIND_POINT_GRAPHICS, lighting_pipeline.layout, 0, 1, &offsceen_descriptors[image_index], 0, null);

        logical_device.dispatch.CmdDraw(onscreen_command_buffer.handle, 6, 1, 0, 0);

        swapchain.endRenderPass(&onscreen_command_buffer);

        try onscreen_command_buffer.end();

        const wait_stage = vk.c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

        var submit_info = vk.c.VkSubmitInfo{
            .sType = vk.c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &present_semaphore,
            .signalSemaphoreCount = 1,
            .pSignalSemaphores = &offscreen_semaphore,
            .commandBufferCount = 1,
            .pCommandBuffers = &command_buffer.handle,
            .pWaitDstStageMask = @ptrCast(&wait_stage),
        };

        if (logical_device.dispatch.QueueSubmit(logical_device.graphics_queue, 1, &submit_info, null) < 0) return error.VkQueueSubmit;

        submit_info.pCommandBuffers = &onscreen_command_buffer.handle;
        submit_info.pWaitSemaphores = &offscreen_semaphore;
        submit_info.pSignalSemaphores = &render_semaphore;

        if (logical_device.dispatch.QueueSubmit(logical_device.graphics_queue, 1, &submit_info, null) < 0) return error.VkQueueSubmit;

        const present_info = std.mem.zeroInit(vk.c.VkPresentInfoKHR, vk.c.VkPresentInfoKHR{
            .sType = vk.c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &render_semaphore,
            .swapchainCount = 1,
            .pSwapchains = &swapchain.handle,
            .pImageIndices = &image_index,
        });

        if (logical_device.dispatch.QueuePresentKHR(logical_device.present_queue, &present_info) < 0) return error.VkQueuePresent;

        if (logical_device.dispatch.QueueWaitIdle(logical_device.graphics_queue) < 0) return error.VkQueueWaitIdle;

        const segment0 = game_world.objects.getPtr("segment0").?;
        const segment1 = game_world.objects.getPtr("segment1").?;

        const pos1 = &segment1.transform.?[0];

        if (keyboard.i) pos1.*[2] -= 0.01;
        if (keyboard.k) pos1.*[2] += 0.01;
        if (keyboard.j) pos1.*[0] -= 0.01;
        if (keyboard.l) pos1.*[0] += 0.01;
        if (keyboard.n) pos1.*[1] -= 0.01;
        if (keyboard.m) pos1.*[1] += 0.01;

        const shape0 = px.Shape{ .box = .{ .bounds = segment0.aabb.? } };
        const shape1 = px.Shape{ .box = .{ .bounds = segment1.aabb.? } };

        const is_colliding = px.intersect(shape0, segment0.transform.?[0], zmath.quatFromRollPitchYawV(segment0.transform.?[1]), shape1, segment1.transform.?[0], zmath.quatFromRollPitchYawV(segment1.transform.?[1]));

        if (is_colliding and !old_colliding) std.debug.print("is_colliding: true\n", .{});
        if (!is_colliding and old_colliding) std.debug.print("is_colliding: false\n", .{});

        old_colliding = is_colliding;
    }
}

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    // {
    //     const exe_path = try std.fs.selfExeDirPathAlloc(allocator);
    //     defer allocator.free(exe_path);
    //     var dir = try std.fs.cwd().openDir(exe_path, .{});
    //     defer dir.close();
    //     try dir.setAsCwd();
    // }

    conventional(allocator) catch |e| {
        var file = try std.fs.cwd().createFile("log.txt", .{});
        defer file.close();
        const writer = file.writer();
        try writer.print("{}\n", .{e});
        return e;
    };

    // var audio = try AudioLinux.init();
    // defer audio.deinit();

    // const cube = px.BoundingBox.cube1x1();

    // const shape1 = px.Shape{ .box = .{ .bounds = cube } };

    // const shape2 = px.Shape{ .box = .{ .bounds = cube } };

    // if (px.intersect(shape1, .{ 0.0, 0.0, 1.5, 1.0 }, zmath.quatFromAxisAngle(.{ 1.0, 0.0, 0.0, 0.0 }, 0.0), shape2, .{ 0.0, 0.0, 0.0, 1.0 }, zmath.quatFromAxisAngle(.{ 1.0, 0.0, 0.0, 0.0 }, 0.0))) {
    //     std.debug.print("aaaaaaaa", .{});
    // }
}
