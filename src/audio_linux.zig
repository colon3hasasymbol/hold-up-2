const std = @import("std");
const c = @cImport({
    @cInclude("pulse/pulseaudio.h");
});

loop: *c.pa_threaded_mainloop,
api: *c.pa_mainloop_api,
context: *c.pa_context,

fn on_state_change(context: ?*c.pa_context, user_data: ?*anyopaque) void {
    _ = context;
    c.pa_threaded_mainloop_signal(user_data, 0);
}

pub fn init() !@This() {
    const loop = c.pa_threaded_mainloop_new();
    c.pa_threaded_mainloop_start(loop);
    c.pa_threaded_mainloop_lock(loop);

    const api = c.pa_threaded_mainloop_get_api(loop);
    const context = c.pa_context_new_with_proplist(api, "TGVG Engine", null);

    c.pa_context_set_state_callback(context, &on_state_change, loop);

    c.pa_context_connect(context, null, 0, null);

    while (c.pa_context_get_state(context) != c.PA_CONTEXT_READY) c.pa_threaded_mainloop_wait(loop);

    var operation = c.pa_context_get_sink_info_list(context, &on_dev_sink, loop);

    c.pa_threaded_mainloop_unlock(loop);

    return .{
        .loop = loop,
    };
}

pub fn deinit(self: *@This()) void {
    c.pa_context_disconnect(self.context);
    c.pa_context_unref(self.context);

    c.pa_threaded_mainloop_stop(self.loop);
    c.pa_threaded_mainloop_free(self.loop);
}
