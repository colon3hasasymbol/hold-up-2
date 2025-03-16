// Copyright 2025-Present Felix Sapora. All rights reserved.

const std = @import("std");

const stbi = @cImport({
    @cInclude("stb_image.h");
});

const vk = @import("vulkan.zig");

pub const Model = struct {
    pub const Vertex = struct {
        position: @Vector(3, f32),
        uv: @Vector(2, f32),

        pub fn getBindingDescriptions() []vk.VertexBinding {
            return @constCast(&[_]vk.VertexBinding{
                vk.VertexBinding{
                    .binding = 0,
                    .stride = @sizeOf(@This()),
                    .inputRate = vk.VertexInputRate.PER_VERTEX,
                },
            });
        }

        pub fn getAttributeDescriptions() []vk.VertexAttribute {
            return @constCast(&[_]vk.VertexAttribute{
                vk.VertexAttribute{
                    .binding = 0,
                    .format = 106,
                    .location = 0,
                    .offset = 0,
                },
                vk.VertexAttribute{
                    .binding = 0,
                    .format = 103,
                    .location = 1,
                    .offset = @offsetOf(@This(), "uv"),
                },
            });
        }
    };

    vertex_buffer: vk.Buffer,
    vertex_count: u32,
    device: *const vk.LogicalDevice,
    allocation_callbacks: vk.AllocationCallbacks,

    pub fn init(device: *const vk.LogicalDevice, vertices: []const Vertex, allocation_callbacks: vk.AllocationCallbacks) !@This() {
        const vertex_count: u32 = @intCast(vertices.len);

        const vertex_buffer_size: u64 = @sizeOf(@TypeOf(vertices[0])) * vertex_count;

        var vertex_buffer = try vk.Buffer.init(device, vertex_buffer_size, vk.BufferUsage.VERTEX_BUFFER_BIT, allocation_callbacks);
        try vertex_buffer.createMemory(vk.MemoryProperty.HOST_VISIBLE_BIT | vk.MemoryProperty.HOST_COHERENT_BIT);
        try vertex_buffer.uploadData(vertices);

        return .{
            .vertex_buffer = vertex_buffer,
            .vertex_count = vertex_count,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.vertex_buffer.deinit();
    }

    pub fn bind(self: *@This(), command_buffer: *vk.CommandBuffer) void {
        self.device.dispatch.CmdBindVertexBuffers(command_buffer.handle, 0, 1, &self.vertex_buffer.handle, &[_]u64{0});
    }

    pub fn draw(self: *@This(), command_buffer: *vk.CommandBuffer) void {
        self.device.dispatch.CmdDraw(command_buffer.handle, self.vertex_count, 1, 0, 0);
    }
};

pub const Texture = struct {
    image: vk.Image,
    sampler: vk.Sampler,
    descriptor_sets: []vk.c.VkDescriptorSet,
    allocator: std.mem.Allocator,

    pub fn init(device: *const vk.LogicalDevice, command_pool: *vk.CommandPool, descriptor_pool: *vk.DescriptorPool, descriptor_count: u32, file_path: []const u8, allocator: std.mem.Allocator, allocation_callbacks: vk.AllocationCallbacks) !@This() {
        var texture_width: c_int = undefined;
        var texture_height: c_int = undefined;
        var texture_channels: c_int = undefined;

        const pixels = stbi.stbi_load(@ptrCast(file_path), &texture_width, &texture_height, &texture_channels, stbi.STBI_rgb_alpha);
        if (pixels == null) return error.StbiLoad;
        defer stbi.stbi_image_free(pixels);
        const size: u64 = @as(u64, @intCast(texture_width)) * @as(u64, @intCast(texture_height)) * 4;

        const image_create_info = std.mem.zeroInit(vk.c.VkImageCreateInfo, vk.c.VkImageCreateInfo{
            .sType = vk.c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
            .imageType = vk.c.VK_IMAGE_TYPE_2D,
            .extent = .{
                .width = @intCast(texture_width),
                .height = @intCast(texture_height),
                .depth = 1,
            },
            .mipLevels = 1,
            .arrayLayers = 1,
            .format = vk.c.VK_FORMAT_R8G8B8A8_SRGB,
            .tiling = vk.c.VK_IMAGE_TILING_OPTIMAL,
            .initialLayout = vk.c.VK_IMAGE_LAYOUT_UNDEFINED,
            .usage = vk.c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | vk.c.VK_IMAGE_USAGE_SAMPLED_BIT,
            .samples = vk.c.VK_SAMPLE_COUNT_1_BIT,
            .sharingMode = vk.c.VK_SHARING_MODE_EXCLUSIVE,
            .flags = 0,
        });

        var image = try vk.Image.init(device, image_create_info, allocation_callbacks);
        errdefer image.deinit();
        try image.createMemory(vk.c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
        try image.uploadData(pixels[0..size], command_pool);
        try image.createView(vk.ImageViewType.TYPE_2D, vk.c.VK_FORMAT_R8G8B8A8_SRGB, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

        var sampler = try vk.Sampler.init(device, allocation_callbacks);
        errdefer sampler.deinit();

        const descriptor_sets = try descriptor_pool.allocate(descriptor_count, allocator);

        for (0..descriptor_count) |i| {
            const image_info = std.mem.zeroInit(vk.c.VkDescriptorImageInfo, vk.c.VkDescriptorImageInfo{
                .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .sampler = sampler.handle,
                .imageView = image.view,
            });

            const descriptor_write = std.mem.zeroInit(vk.c.VkWriteDescriptorSet, vk.c.VkWriteDescriptorSet{
                .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = descriptor_sets[i],
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = 1,
                .pImageInfo = &image_info,
            });

            device.dispatch.UpdateDescriptorSets(device.handle, 1, &descriptor_write, 0, null);
        }

        return .{
            .image = image,
            .sampler = sampler,
            .descriptor_sets = descriptor_sets,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.image.deinit();
        self.sampler.deinit();
        self.allocator.free(self.descriptor_sets);
    }
};
