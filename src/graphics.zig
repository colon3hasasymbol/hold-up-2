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

    pub fn init(device: *const vk.LogicalDevice, command_pool: *vk.CommandPool, file_path: []const u8, allocation_callbacks: vk.AllocationCallbacks) !@This() {
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

        return .{
            .image = image,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.image.deinit();
    }
};
