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
        normal: @Vector(3, f16),
        tangent: @Vector(3, f16),

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
                vk.VertexAttribute{
                    .binding = 0,
                    .format = vk.c.VK_FORMAT_R16G16B16_UNORM,
                    .location = 2,
                    .offset = @offsetOf(@This(), "normal"),
                },
                vk.VertexAttribute{
                    .binding = 0,
                    .format = vk.c.VK_FORMAT_R16G16B16_UNORM,
                    .location = 3,
                    .offset = @offsetOf(@This(), "tangent"),
                },
            });
        }
    };

    vertex_buffer: vk.Buffer,
    vertex_count: u32,
    index_buffer: vk.Buffer,
    index_count: u32,
    device: *const vk.LogicalDevice,
    allocation_callbacks: vk.AllocationCallbacks,

    pub fn init(device: *const vk.LogicalDevice, vertices: []const Vertex, indices: []const u32, allocation_callbacks: vk.AllocationCallbacks) !@This() {
        const vertex_count: u32 = @intCast(vertices.len);
        const index_count: u32 = @intCast(indices.len);

        const vertex_buffer_size: u64 = @sizeOf(Vertex) * vertex_count;
        const index_buffer_size: u64 = @sizeOf(u32) * index_count;

        var vertex_buffer = try vk.Buffer.init(device, vertex_buffer_size, vk.BufferUsage.VERTEX_BUFFER_BIT, allocation_callbacks);
        try vertex_buffer.createMemory(vk.MemoryProperty.HOST_VISIBLE_BIT | vk.MemoryProperty.HOST_COHERENT_BIT);
        try vertex_buffer.uploadData(vertices);

        var index_buffer = try vk.Buffer.init(device, index_buffer_size, vk.BufferUsage.INDEX_BUFFER_BIT, allocation_callbacks);
        try index_buffer.createMemory(vk.MemoryProperty.HOST_VISIBLE_BIT | vk.MemoryProperty.HOST_COHERENT_BIT);
        try index_buffer.uploadData(indices);

        return .{
            .vertex_buffer = vertex_buffer,
            .vertex_count = vertex_count,
            .index_buffer = index_buffer,
            .index_count = index_count,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.vertex_buffer.deinit();
        self.index_buffer.deinit();
    }

    pub fn bind(self: *@This(), command_buffer: *vk.CommandBuffer) void {
        self.device.dispatch.CmdBindVertexBuffers(command_buffer.handle, 0, 1, &self.vertex_buffer.handle, &[_]u64{0});
        self.device.dispatch.CmdBindIndexBuffer(command_buffer.handle, self.index_buffer.handle, 0, vk.c.VK_INDEX_TYPE_UINT32);
    }

    pub fn draw(self: *@This(), command_buffer: *vk.CommandBuffer) void {
        self.device.dispatch.CmdDrawIndexed(command_buffer.handle, self.index_count, 1, 0, 0, 0);
    }
};

pub const Texture = struct {
    color_image: vk.Image,
    normal_image: vk.Image,
    sampler: vk.Sampler,
    descriptor_sets: []vk.c.VkDescriptorSet,
    allocator: std.mem.Allocator,

    pub fn init(device: *const vk.LogicalDevice, command_pool: *vk.CommandPool, pipeline: *vk.Pipeline, descriptor_pool: *vk.DescriptorPool, descriptor_count: u32, file_path: []const u8, allocator: std.mem.Allocator, allocation_callbacks: vk.AllocationCallbacks) !@This() {
        var texture_width: c_int = undefined;
        var texture_height: c_int = undefined;
        var texture_channels: c_int = undefined;

        const pixels = stbi.stbi_load(@ptrCast(file_path), &texture_width, &texture_height, &texture_channels, stbi.STBI_rgb_alpha);
        if (pixels == null) return error.StbiLoad;
        defer stbi.stbi_image_free(pixels);
        const size: u64 = @as(u64, @intCast(texture_width)) * @as(u64, @intCast(texture_height)) * 4;

        var image_create_info = std.mem.zeroInit(vk.c.VkImageCreateInfo, vk.c.VkImageCreateInfo{
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

        var color_image = try vk.Image.init(device, image_create_info, allocation_callbacks);
        errdefer color_image.deinit();
        try color_image.createMemory(vk.c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
        try color_image.transitionLayout(vk.c.VK_IMAGE_LAYOUT_UNDEFINED, vk.c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 0, vk.c.VK_ACCESS_TRANSFER_WRITE_BIT, vk.c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.c.VK_PIPELINE_STAGE_TRANSFER_BIT, command_pool);
        try color_image.uploadData(pixels[0..size], command_pool);
        try color_image.transitionLayout(vk.c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.c.VK_ACCESS_TRANSFER_WRITE_BIT, vk.c.VK_ACCESS_SHADER_READ_BIT, vk.c.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, command_pool);
        try color_image.createView(vk.ImageViewType.TYPE_2D, image_create_info.format, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

        image_create_info.format = vk.c.VK_FORMAT_R8G8B8A8_UNORM;

        var normal_image = try vk.Image.init(device, image_create_info, allocation_callbacks);
        errdefer normal_image.deinit();
        try normal_image.createMemory(vk.c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
        try normal_image.transitionLayout(vk.c.VK_IMAGE_LAYOUT_UNDEFINED, vk.c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 0, vk.c.VK_ACCESS_TRANSFER_WRITE_BIT, vk.c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.c.VK_PIPELINE_STAGE_TRANSFER_BIT, command_pool);
        try normal_image.uploadData(pixels[0..size], command_pool);
        try normal_image.transitionLayout(vk.c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.c.VK_ACCESS_TRANSFER_WRITE_BIT, vk.c.VK_ACCESS_SHADER_READ_BIT, vk.c.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, command_pool);
        try normal_image.createView(vk.ImageViewType.TYPE_2D, image_create_info.format, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

        var sampler = try vk.Sampler.init(device, allocation_callbacks);
        errdefer sampler.deinit();

        const descriptor_sets = try descriptor_pool.allocate(pipeline, descriptor_count, allocator);

        for (0..descriptor_count) |i| {
            const color_image_info = std.mem.zeroInit(vk.c.VkDescriptorImageInfo, vk.c.VkDescriptorImageInfo{
                .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .sampler = sampler.handle,
                .imageView = color_image.view,
            });

            const color_descriptor_write = std.mem.zeroInit(vk.c.VkWriteDescriptorSet, vk.c.VkWriteDescriptorSet{
                .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = descriptor_sets[i],
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = 1,
                .pImageInfo = &color_image_info,
            });

            const normal_image_info = std.mem.zeroInit(vk.c.VkDescriptorImageInfo, vk.c.VkDescriptorImageInfo{
                .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .sampler = sampler.handle,
                .imageView = normal_image.view,
            });

            const normal_descriptor_write = std.mem.zeroInit(vk.c.VkWriteDescriptorSet, vk.c.VkWriteDescriptorSet{
                .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = descriptor_sets[i],
                .dstBinding = 1,
                .dstArrayElement = 0,
                .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = 1,
                .pImageInfo = &normal_image_info,
            });

            // _ = normal_descriptor_write;

            const descriptor_writes = [_]vk.c.VkWriteDescriptorSet{
                color_descriptor_write,
                normal_descriptor_write,
            };

            device.dispatch.UpdateDescriptorSets(device.handle, @intCast(descriptor_writes.len), &descriptor_writes, 0, null);
        }

        return .{
            .color_image = color_image,
            .normal_image = normal_image,
            .sampler = sampler,
            .descriptor_sets = descriptor_sets,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.color_image.deinit();
        self.normal_image.deinit();
        self.sampler.deinit();
        self.allocator.free(self.descriptor_sets);
    }
};

pub const TextRenderer = struct {
    pub const Character = struct {
        transform: [3]@Vector(3, f32),
        character: u32,
    };

    const PushConstantData = struct {
        text_block_transform: [3]@Vector(3, f32),
    };

    device: *const vk.LogicalDevice,
    pipeline: vk.Pipeline,
    text_buffer: vk.Buffer,
    character_count: u32,
    font_atlas_image: vk.Image,
    font_atlas_sampler: vk.Sampler,
    descriptor_sets: []vk.c.VkDescriptorSet,
    allocator: std.mem.Allocator,
    allocation_callbacks: vk.AllocationCallbacks,

    pub fn init(device: *const vk.LogicalDevice, render_pass: *const vk.RenderPass, extent: vk.Extent2D, descriptor_count: u32, descriptor_pool: *vk.DescriptorPool, command_pool: *vk.CommandPool, font_atlas_file_path: []const u8, allocator: std.mem.Allocator, allocation_callbacks: vk.AllocationCallbacks) !@This() {
        const frag_spv align(@alignOf(u32)) = @embedFile("shaders/text_shader.frag.spv").*;
        const vert_spv align(@alignOf(u32)) = @embedFile("shaders/text_shader.vert.spv").*;

        var frag_shader = try vk.ShaderModule.init(device, &frag_spv, null);
        defer frag_shader.deinit();

        var vert_shader = try vk.ShaderModule.init(device, &vert_spv, null);
        defer vert_shader.deinit();

        var pipeline = try vk.Pipeline.init(
            device,
            PushConstantData,
            @constCast(&[_]vk.c.VkDescriptorSetLayoutBinding{
                std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 0, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_VERTEX_BIT }),
                std.mem.zeroInit(vk.c.VkDescriptorSetLayoutBinding, .{ .binding = 1, .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 1, .stageFlags = vk.c.VK_SHADER_STAGE_FRAGMENT_BIT }),
            }),
            render_pass.handle,
            @constCast(&[_]vk.c.VkPipelineColorBlendAttachmentState{
                .{ .colorWriteMask = vk.c.VK_COLOR_COMPONENT_R_BIT | vk.c.VK_COLOR_COMPONENT_G_BIT | vk.c.VK_COLOR_COMPONENT_B_BIT | vk.c.VK_COLOR_COMPONENT_A_BIT, .blendEnable = vk.c.VK_FALSE },
            }),
            vk.c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
            vk.c.VK_POLYGON_MODE_FILL,
            &frag_shader,
            &vert_shader,
            extent,
            &[_]vk.c.VkVertexInputAttributeDescription{},
            &[_]vk.c.VkVertexInputBindingDescription{},
            null,
        );
        errdefer pipeline.deinit();

        var text_buffer = try vk.Buffer.init(device, @sizeOf(Character) * 1024, vk.c.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT, allocation_callbacks);
        try text_buffer.createMemory(vk.c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
        _ = try text_buffer.map();

        var texture_width: c_int = undefined;
        var texture_height: c_int = undefined;
        var texture_channels: c_int = undefined;

        const pixels = stbi.stbi_load(@ptrCast(font_atlas_file_path), &texture_width, &texture_height, &texture_channels, stbi.STBI_rgb_alpha);
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

        var font_atlas_image = try vk.Image.init(device, image_create_info, allocation_callbacks);
        errdefer font_atlas_image.deinit();
        try font_atlas_image.createMemory(vk.c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
        try font_atlas_image.transitionLayout(vk.c.VK_IMAGE_LAYOUT_UNDEFINED, vk.c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 0, vk.c.VK_ACCESS_TRANSFER_WRITE_BIT, vk.c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, vk.c.VK_PIPELINE_STAGE_TRANSFER_BIT, command_pool);
        try font_atlas_image.uploadData(pixels[0..size], command_pool);
        try font_atlas_image.transitionLayout(vk.c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, vk.c.VK_ACCESS_TRANSFER_WRITE_BIT, vk.c.VK_ACCESS_SHADER_READ_BIT, vk.c.VK_PIPELINE_STAGE_TRANSFER_BIT, vk.c.VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, command_pool);
        try font_atlas_image.createView(vk.ImageViewType.TYPE_2D, image_create_info.format, .{ .aspectMask = vk.c.VK_IMAGE_ASPECT_COLOR_BIT, .baseMipLevel = 0, .levelCount = 1, .baseArrayLayer = 0, .layerCount = 1 });

        var font_atlas_sampler = try vk.Sampler.init(device, allocation_callbacks);
        errdefer font_atlas_sampler.deinit();

        const descriptor_sets = try descriptor_pool.allocate(&pipeline, descriptor_count, allocator);
        errdefer allocator.free(descriptor_sets);

        for (0..descriptor_count) |i| {
            const text_info = vk.c.VkDescriptorBufferInfo{
                .buffer = text_buffer.handle,
                .offset = 0,
                .range = vk.c.VK_WHOLE_SIZE,
            };

            const text_write = vk.c.VkWriteDescriptorSet{
                .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = descriptor_sets[i],
                .dstBinding = 0,
                .dstArrayElement = 0,
                .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
                .descriptorCount = 1,
                .pBufferInfo = &text_info,
            };

            const font_atlas_info = vk.c.VkDescriptorImageInfo{
                .imageLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                .imageView = font_atlas_image.view,
                .sampler = font_atlas_sampler.handle,
            };

            const font_atlas_write = vk.c.VkWriteDescriptorSet{
                .sType = vk.c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
                .dstSet = descriptor_sets[i],
                .dstBinding = 1,
                .dstArrayElement = 0,
                .descriptorType = vk.c.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
                .descriptorCount = 1,
                .pImageInfo = &font_atlas_info,
            };

            const descriptor_writes = [_]vk.c.VkWriteDescriptorSet{
                text_write,
                font_atlas_write,
            };

            device.dispatch.UpdateDescriptorSets(device.handle, @intCast(descriptor_writes.len), &descriptor_writes, 0, null);
        }

        return .{
            .device = device,
            .pipeline = pipeline,
            .text_buffer = text_buffer,
            .character_count = 0,
            .font_atlas_image = font_atlas_image,
            .font_atlas_sampler = font_atlas_sampler,
            .descriptor_sets = descriptor_sets,
            .allocator = allocator,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.descriptor_sets);
        self.font_atlas_sampler.deinit();
        self.font_atlas_image.deinit();
        self.text_buffer.deinit();
        self.pipeline.deinit();
    }

    pub fn print(self: *@This(), text: []const Character) void {
        @memcpy(@as([*]Character, @alignCast(@ptrCast(self.text_buffer.mapped.?)))[self.character_count .. self.character_count + text.len], text);
        self.character_count += @intCast(text.len);
    }

    pub fn recordCommands(self: *@This(), command_buffer: *vk.CommandBuffer, image_index: u32) void {
        self.pipeline.bind(command_buffer);
        self.device.dispatch.CmdBindDescriptorSets(command_buffer.handle, vk.c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.pipeline.layout, 0, 1, &self.descriptor_sets[image_index], 0, null);
        self.device.dispatch.CmdDraw(command_buffer.handle, 6, self.character_count, 0, 0);
    }
};
