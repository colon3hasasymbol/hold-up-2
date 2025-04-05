const std = @import("std");

const c = @cImport({
    @cInclude("pulse/pulseaudio.h");
});

pub const Device = struct {
    loop: ?*c.pa_threaded_mainloop,
    api: ?*c.pa_mainloop_api,
    context: ?*c.pa_context,
    device_id: [*c]const u8,
    allocator: std.mem.Allocator,

    fn on_state_change(context: ?*c.pa_context, user_data: ?*anyopaque) callconv(.C) void {
        _ = context;
        const self: *@This() = @ptrCast(@alignCast(user_data.?));

        c.pa_threaded_mainloop_signal(self.loop, 0);
    }

    fn on_dev_sink(context: ?*c.pa_context, info: [*c]const c.pa_sink_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
        _ = context;
        const self: *@This() = @ptrCast(@alignCast(user_data.?));

        if (eol != 0) {
            c.pa_threaded_mainloop_signal(self.loop, 0);
            return;
        }

        self.device_id = info.*.name;
    }

    fn on_playback_complete(stream_handle: ?*c.pa_stream, num_bytes: usize, user_data: ?*anyopaque) callconv(.C) void {
        _ = stream_handle;
        _ = num_bytes;

        const stream: *Stream = @ptrCast(@alignCast(user_data.?));
        c.pa_threaded_mainloop_signal(stream.device.loop, 0);
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        errdefer allocator.destroy(self);

        self.loop = c.pa_threaded_mainloop_new();
        if (c.pa_threaded_mainloop_start(self.loop) != 0) return error.PulseAudioMainloopStart;
        c.pa_threaded_mainloop_lock(self.loop);

        self.api = c.pa_threaded_mainloop_get_api(self.loop);
        self.context = c.pa_context_new_with_proplist(self.api, "TGVG Engine", null);

        c.pa_context_set_state_callback(self.context, on_state_change, self);

        if (c.pa_context_connect(self.context, null, 0, null) != 0) return error.PulseAudioContextConnect;

        while (c.pa_context_get_state(self.context) != c.PA_CONTEXT_READY) c.pa_threaded_mainloop_wait(self.loop);

        const operation = c.pa_context_get_sink_info_list(self.context, on_dev_sink, self);

        while (true) {
            const r = c.pa_operation_get_state(operation);
            if (r == c.PA_OPERATION_DONE or r == c.PA_OPERATION_CANCELLED) break;
            c.pa_threaded_mainloop_wait(self.loop);
        }

        c.pa_operation_unref(operation);

        c.pa_threaded_mainloop_unlock(self.loop);

        self.allocator = allocator;

        return self;
    }

    pub fn deinit(self: *@This()) void {
        c.pa_context_disconnect(self.context);
        c.pa_context_unref(self.context);

        c.pa_threaded_mainloop_stop(self.loop);
        c.pa_threaded_mainloop_free(self.loop);

        self.allocator.destroy(self);
    }

    pub fn createStream(self: *@This()) !*Stream {
        const result = try self.allocator.create(Stream);
        errdefer self.allocator.destroy(result);

        const spec = c.pa_sample_spec{
            .format = c.PA_SAMPLE_S16LE,
            .rate = 48000,
            .channels = 2,
        };

        result.handle = c.pa_stream_new(self.context, "stream", &spec, null);

        const attr = c.pa_buffer_attr{
            .fragsize = std.math.maxInt(u32),
            .maxlength = std.math.maxInt(u32),
            .minreq = std.math.maxInt(u32),
            .prebuf = std.math.maxInt(u32),
            .tlength = spec.rate * (16 / 8) * spec.channels * (500 / 1000),
        };

        result.device = self;

        c.pa_stream_set_write_callback(result.handle, on_playback_complete, result);
        _ = c.pa_stream_connect_playback(result.handle, self.device_id, &attr, 0, null, null);

        while (true) {
            switch (c.pa_stream_get_state(result.handle)) {
                c.PA_STREAM_READY => break,
                c.PA_STREAM_FAILED => return error.PAConnectStream,
                else => {},
            }

            c.pa_threaded_mainloop_wait(self.loop);
        }

        return result;
    }
};

pub const Stream = struct {
    handle: ?*c.pa_stream,
    device: *Device,

    fn on_stream_success(stream_handle: ?*c.pa_stream, success: c_int, user_data: ?*anyopaque) callconv(.C) void {
        _ = stream_handle;
        _ = success;
        const self: *@This() = @ptrCast(@alignCast(user_data.?));

        c.pa_threaded_mainloop_signal(self.device.loop, 0);
    }

    pub inline fn init(device: *Device) !*@This() {
        return device.createStream();
    }

    pub fn deinit(self: *@This()) void {
        _ = c.pa_stream_disconnect(self.handle);
        c.pa_stream_unref(self.handle);
        self.device.allocator.destroy(self);
    }

    pub fn play(self: *@This()) void {
        var index: u64 = 0;
        while (true) {
            var writable_size = c.pa_stream_writable_size(self.handle);
            if (writable_size == 0) {
                c.pa_threaded_mainloop_wait(self.device.loop);
                continue;
            }

            var buffer_ptr: ?*anyopaque = undefined;
            _ = c.pa_stream_begin_write(self.handle, &buffer_ptr, &writable_size);
            const buffer: []i16 = @as([*]i16, @ptrCast(@alignCast(buffer_ptr.?)))[0..writable_size];

            for (buffer, index..) |*sample, i| {
                const float = std.math.sin(@as(f32, @mod(@as(f32, @floatFromInt(i)) / 100.0, std.math.pi)));
                sample.* = @intFromFloat(float * @as(f32, @floatFromInt(std.math.maxInt(i16))));
            }

            _ = c.pa_stream_write(self.handle, buffer_ptr, writable_size, null, 0, c.PA_SEEK_RELATIVE);

            index += writable_size;

            if (index > 24000) break;
        }

        const op = c.pa_stream_drain(self.handle, on_stream_success, self);

        while (true) {
            const r = c.pa_operation_get_state(op);
            if (r == c.PA_OPERATION_DONE or r == c.PA_OPERATION_CANCELLED) break;
            c.pa_threaded_mainloop_wait(self.device.loop);
        }

        c.pa_operation_unref(op);
    }
};
