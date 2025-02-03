const std = @import("std");

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
        self.device.dispatch.DestroyBuffer(self.device.handle, self.vertex_buffer, self.allocation_callbacks);
        self.device.freeMemory(self.vertex_memory, self.allocation_callbacks);
    }

    pub fn bind(self: *@This(), command_buffer: *vk.CommandBuffer) void {
        self.device.dispatch.CmdBindVertexBuffers(command_buffer.handle, 0, 1, &self.vertex_buffer.handle, &[_]u64{0});
    }

    pub fn draw(self: *@This(), command_buffer: *vk.CommandBuffer) void {
        self.device.dispatch.CmdDraw(command_buffer.handle, self.vertex_count, 1, 0, 0);
    }
};
