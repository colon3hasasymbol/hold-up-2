const std = @import("std");
const c = @cImport({
    @cInclude("pulse/pulseaudio.h");
});

loop: ?*c.pa_threaded_mainloop,
api: ?*c.pa_mainloop_api,
context: ?*c.pa_context,

fn on_state_change(context: ?*c.pa_context, user_data: ?*anyopaque) callconv(.C) void {
    _ = context;
    const self: *@This() = @ptrCast(@alignCast(user_data.?));

    c.pa_threaded_mainloop_signal(self.loop, 0);
}

fn on_dev_sink(context: ?*c.pa_context, info: [*c]const c.pa_sink_info, eol: c_int, user_data: ?*anyopaque) callconv(.C) void {
    _ = context;
    _ = info;
    const self: *@This() = @ptrCast(@alignCast(user_data.?));

    if (eol != 0) c.pa_threaded_mainloop_signal(self.loop, 0);
}

pub fn init() !@This() {
    var self: @This() = undefined;

    self.loop = c.pa_threaded_mainloop_new();
    if (c.pa_threaded_mainloop_start(self.loop) != 0) return error.PulseAudioMainloopStart;
    c.pa_threaded_mainloop_lock(self.loop);

    self.api = c.pa_threaded_mainloop_get_api(self.loop);
    self.context = c.pa_context_new_with_proplist(self.api, "TGVG Engine", null);

    c.pa_context_set_state_callback(self.context, &on_state_change, &self);

    if (c.pa_context_connect(self.context, null, 0, null) != 0) return error.PulseAudioContextConnect;

    while (c.pa_context_get_state(self.context) != c.PA_CONTEXT_READY) c.pa_threaded_mainloop_wait(self.loop);

    const operation = c.pa_context_get_sink_info_list(self.context, &on_dev_sink, &self);

    while (true) {
        const r = c.pa_operation_get_state(operation);
        if (r == c.PA_OPERATION_DONE or r == c.PA_OPERATION_CANCELLED) break;
        c.pa_threaded_mainloop_wait(self.loop);
    }

    c.pa_operation_unref(operation);

    c.pa_threaded_mainloop_unlock(self.loop);

    return self;
}

pub fn deinit(self: *@This()) void {
    c.pa_context_disconnect(self.context);
    c.pa_context_unref(self.context);

    c.pa_threaded_mainloop_stop(self.loop);
    c.pa_threaded_mainloop_free(self.loop);
}
