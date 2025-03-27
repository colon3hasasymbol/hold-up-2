// Copyright 2025-Present Felix Sapora. All rights reserved.

const std = @import("std");
pub const c = @cImport({
    @cDefine("VK_NO_PROTOTYPES", {});
    @cInclude("vulkan/vulkan.h");
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_vulkan.h");
});

pub const AllocationCallbacks = ?*c.VkAllocationCallbacks;

pub const VertexAttribute = c.VkVertexInputAttributeDescription;
pub const VertexBinding = c.VkVertexInputBindingDescription;

pub const ClearColor = struct { r: f32, g: f32, b: f32, a: f32 };

pub const ShaderStage = struct {
    pub const VERTEX_BIT: u32 = 1;
    pub const TESSELLATION_CONTROL_BIT: u32 = 2;
    pub const TESSELLATION_EVALUATION_BIT: u32 = 4;
    pub const GEOMETRY_BIT: u32 = 8;
    pub const FRAGMENT_BIT: u32 = 16;
    pub const COMPUTE_BIT: u32 = 32;
    pub const ALL_GRAPHICS: u32 = 31;
    pub const ALL: u32 = 2147483647;
    pub const RAYGEN_BIT_KHR: u32 = 256;
    pub const ANY_HIT_BIT_KHR: u32 = 512;
    pub const CLOSEST_HIT_BIT_KHR: u32 = 1024;
    pub const MISS_BIT_KHR: u32 = 2048;
    pub const INTERSECTION_BIT_KHR: u32 = 4096;
    pub const CALLABLE_BIT_KHR: u32 = 8192;
    pub const TASK_BIT_EXT: u32 = 64;
    pub const MESH_BIT_EXT: u32 = 128;
    pub const SUBPASS_SHADING_BIT_HUAWEI: u32 = 16384;
    pub const CLUSTER_CULLING_BIT_HUAWEI: u32 = 524288;
    pub const RAYGEN_BIT_NV: u32 = 256;
    pub const ANY_HIT_BIT_NV: u32 = 512;
    pub const CLOSEST_HIT_BIT_NV: u32 = 1024;
    pub const MISS_BIT_NV: u32 = 2048;
    pub const INTERSECTION_BIT_NV: u32 = 4096;
    pub const CALLABLE_BIT_NV: u32 = 8192;
    pub const TASK_BIT_NV: u32 = 64;
    pub const MESH_BIT_NV: u32 = 128;
    pub const FLAG_BITS_MAX_ENUM: u32 = 2147483647;
};

pub const BufferUsage = struct {
    pub const TRANSFER_SRC_BIT: c_int = 1;
    pub const TRANSFER_DST_BIT: c_int = 2;
    pub const UNIFORM_TEXEL_BUFFER_BIT: c_int = 4;
    pub const STORAGE_TEXEL_BUFFER_BIT: c_int = 8;
    pub const UNIFORM_BUFFER_BIT: c_int = 16;
    pub const STORAGE_BUFFER_BIT: c_int = 32;
    pub const INDEX_BUFFER_BIT: c_int = 64;
    pub const VERTEX_BUFFER_BIT: c_int = 128;
    pub const INDIRECT_BUFFER_BIT: c_int = 256;
    pub const SHADER_DEVICE_ADDRESS_BIT: c_int = 131072;
    pub const VIDEO_DECODE_SRC_BIT_KHR: c_int = 8192;
    pub const VIDEO_DECODE_DST_BIT_KHR: c_int = 16384;
    pub const TRANSFORM_FEEDBACK_BUFFER_BIT_EXT: c_int = 2048;
    pub const TRANSFORM_FEEDBACK_COUNTER_BUFFER_BIT_EXT: c_int = 4096;
    pub const CONDITIONAL_RENDERING_BIT_EXT: c_int = 512;
    pub const ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR: c_int = 524288;
    pub const ACCELERATION_STRUCTURE_STORAGE_BIT_KHR: c_int = 1048576;
    pub const SHADER_BINDING_TABLE_BIT_KHR: c_int = 1024;
    pub const VIDEO_ENCODE_DST_BIT_KHR: c_int = 32768;
    pub const VIDEO_ENCODE_SRC_BIT_KHR: c_int = 65536;
    pub const SAMPLER_DESCRIPTOR_BUFFER_BIT_EXT: c_int = 2097152;
    pub const RESOURCE_DESCRIPTOR_BUFFER_BIT_EXT: c_int = 4194304;
    pub const PUSH_DESCRIPTORS_DESCRIPTOR_BUFFER_BIT_EXT: c_int = 67108864;
    pub const MICROMAP_BUILD_INPUT_READ_ONLY_BIT_EXT: c_int = 8388608;
    pub const MICROMAP_STORAGE_BIT_EXT: c_int = 16777216;
    pub const RAY_TRACING_BIT_NV: c_int = 1024;
    pub const SHADER_DEVICE_ADDRESS_BIT_EXT: c_int = 131072;
    pub const SHADER_DEVICE_ADDRESS_BIT_KHR: c_int = 131072;
    pub const FLAG_BITS_MAX_ENUM: c_int = 2147483647;
};

pub const MemoryProperty = struct {
    pub const DEVICE_LOCAL_BIT: c_int = 1;
    pub const HOST_VISIBLE_BIT: c_int = 2;
    pub const HOST_COHERENT_BIT: c_int = 4;
    pub const HOST_CACHED_BIT: c_int = 8;
    pub const LAZILY_ALLOCATED_BIT: c_int = 16;
    pub const PROTECTED_BIT: c_int = 32;
    pub const DEVICE_COHERENT_BIT_AMD: c_int = 64;
    pub const DEVICE_UNCACHED_BIT_AMD: c_int = 128;
    pub const RDMA_CAPABLE_BIT_NV: c_int = 256;
    pub const FLAG_BITS_MAX_ENUM: c_int = 2147483647;
};

pub const VertexInputRate = struct {
    pub const PER_VERTEX: c_uint = 0;
    pub const PER_INSTANCE: c_uint = 1;
};

pub const ImageViewType = struct {
    pub const TYPE_1D: c_int = 0;
    pub const TYPE_2D: c_int = 1;
    pub const TYPE_3D: c_int = 2;
    pub const TYPE_CUBE: c_int = 3;
    pub const TYPE_1D_ARRAY: c_int = 4;
    pub const TYPE_2D_ARRAY: c_int = 5;
    pub const TYPE_CUBE_ARRAY: c_int = 6;
};

pub const Extent2D = struct { x: u32, y: u32 };
pub const Extent3D = struct { x: u32, y: u32, z: u32 };

pub const Library = struct {
    get_instance_proc_addr: std.meta.Child(c.PFN_vkGetInstanceProcAddr),

    pub fn init() !@This() {
        if (c.SDL_Vulkan_LoadLibrary(null) != 0) {
            c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
            return error.SDLVulkanLoadLibrary;
        }
        if (c.SDL_Vulkan_GetVkGetInstanceProcAddr()) |proc| {
            return .{
                .get_instance_proc_addr = @ptrCast(proc),
            };
        } else {
            return error.SDLVulkanGetVkGetInstanceProcAddr;
        }
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
        c.SDL_Vulkan_UnloadLibrary();
    }

    pub fn getProc(self: *const @This(), instance: c.VkInstance, comptime PFN: type, name: [*c]const u8) !std.meta.Child(PFN) {
        if (self.get_instance_proc_addr(instance, name)) |proc| {
            return @ptrCast(proc);
        } else {
            return error.GetInstanceProcAddr;
        }
    }

    pub fn load(self: *const @This(), comptime Dispatch: type, instance: c.VkInstance) !Dispatch {
        var dispatch = Dispatch{};
        inline for (@typeInfo(Dispatch).Struct.fields) |field| {
            @field(dispatch, field.name) = try self.getProc(instance, ?field.type, "vk" ++ field.name);
        }
        return dispatch;
    }
};

pub const Window = struct {
    handle: ?*c.SDL_Window,

    pub fn init(title: [*c]const u8) !@This() {
        const handle = c.SDL_CreateWindow(title, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 800, 800, c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_HIDDEN);
        if (handle == null) {
            c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
            return error.SDLCreateWindow;
        }

        if (c.SDL_SetWindowOpacity(handle, 0.2) < 0) return error.SDLSetWindowOpacity;

        return .{
            .handle = handle,
        };
    }

    pub fn deinit(self: *@This()) void {
        c.SDL_DestroyWindow(self.handle);
    }

    pub fn getRequiredExtensions(self: *const @This(), allocator: std.mem.Allocator) ![][*c]const u8 {
        var extension_count: c_uint = undefined;
        if (c.SDL_Vulkan_GetInstanceExtensions(self.handle, &extension_count, null) == c.SDL_FALSE) {
            c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
            return error.SDLVulkanGetInstanceExtensionsCount;
        }

        const extensions = try allocator.alloc([*c]const u8, extension_count);
        errdefer allocator.free(extensions);

        if (c.SDL_Vulkan_GetInstanceExtensions(self.handle, &extension_count, extensions.ptr) == c.SDL_FALSE) {
            c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
            return error.SDLVulkanGetInstanceExtensions;
        }

        return extensions;
    }

    pub fn show(self: *@This()) void {
        c.SDL_ShowWindow(self.handle);
    }

    pub fn getExtent(self: *const @This()) Extent2D {
        var width: u32 = 800;
        var height: u32 = 600;
        c.SDL_Vulkan_GetDrawableSize(self.handle, @ptrCast(&width), @ptrCast(&height));

        return Extent2D{ .x = width, .y = height };
    }
};

pub const Instance = struct {
    const Dispatch = struct {
        DestroyInstance: std.meta.Child(c.PFN_vkDestroyInstance) = undefined,
        EnumeratePhysicalDevices: std.meta.Child(c.PFN_vkEnumeratePhysicalDevices) = undefined,
        GetPhysicalDeviceQueueFamilyProperties: std.meta.Child(c.PFN_vkGetPhysicalDeviceQueueFamilyProperties) = undefined,
        CreateDevice: std.meta.Child(c.PFN_vkCreateDevice) = undefined,
        GetDeviceProcAddr: std.meta.Child(c.PFN_vkGetDeviceProcAddr) = undefined,
        DestroySurfaceKHR: std.meta.Child(c.PFN_vkDestroySurfaceKHR) = undefined,
        GetPhysicalDeviceSurfaceSupportKHR: std.meta.Child(c.PFN_vkGetPhysicalDeviceSurfaceSupportKHR) = undefined,
        GetPhysicalDeviceProperties: std.meta.Child(c.PFN_vkGetPhysicalDeviceProperties) = undefined,
        GetPhysicalDeviceSurfaceCapabilitiesKHR: std.meta.Child(c.PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR) = undefined,
        GetPhysicalDeviceFormatProperties: std.meta.Child(c.PFN_vkGetPhysicalDeviceFormatProperties) = undefined,
        GetPhysicalDeviceSurfaceFormatsKHR: std.meta.Child(c.PFN_vkGetPhysicalDeviceSurfaceFormatsKHR) = undefined,
        GetPhysicalDeviceSurfacePresentModesKHR: std.meta.Child(c.PFN_vkGetPhysicalDeviceSurfacePresentModesKHR) = undefined,
        GetPhysicalDeviceMemoryProperties: std.meta.Child(c.PFN_vkGetPhysicalDeviceMemoryProperties) = undefined,
        CreateGraphicsPipelines: std.meta.Child(c.PFN_vkCreateGraphicsPipelines) = undefined,
        GetPhysicalDeviceFeatures: std.meta.Child(c.PFN_vkGetPhysicalDeviceFeatures) = undefined,
    };

    handle: c.VkInstance,
    allocation_callbacks: AllocationCallbacks,
    vulkan_library: *Library,
    dispatch: Dispatch,

    pub fn init(extensions: [][*c]const u8, vulkan_library: *Library, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkInstanceCreateInfo, .{
            .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .enabledExtensionCount = @as(u32, @intCast(extensions.len)),
            .ppEnabledExtensionNames = extensions.ptr,
        });

        const create_instance = try vulkan_library.getProc(null, c.PFN_vkCreateInstance, "vkCreateInstance");

        var handle: c.VkInstance = undefined;
        if (create_instance(&create_info, allocation_callbacks, &handle) < 0) return error.VkCreateInstance;

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .vulkan_library = vulkan_library,
            .dispatch = try vulkan_library.load(Dispatch, handle),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.dispatch.DestroyInstance(self.handle, self.allocation_callbacks);
    }

    pub fn getProc(self: *const @This(), comptime PFN: type, name: [*c]const u8) std.meta.Child(PFN) {
        return self.vulkan_library.getProc(self.handle, PFN, name);
    }

    fn getDeviceProc(self: *const @This(), comptime PFN: type, device: c.VkDevice, name: [*c]const u8) !std.meta.Child(PFN) {
        if (self.dispatch.GetDeviceProcAddr(device, name)) |proc| {
            return @ptrCast(proc);
        } else {
            c.SDL_Log("%s", name);
            return error.GetDeviceProcAddr;
        }
    }

    fn load(self: *const @This(), comptime DeviceDispatch: type, device: c.VkDevice) !DeviceDispatch {
        var dispatch = DeviceDispatch{};
        inline for (@typeInfo(DeviceDispatch).Struct.fields) |field| {
            @field(dispatch, field.name) = try self.getDeviceProc(?field.type, device, "vk" ++ field.name);
        }
        return dispatch;
    }

    pub fn enumeratePhysicalDevices(self: *const @This(), allocator: std.mem.Allocator) ![]c.VkPhysicalDevice {
        var count: u32 = undefined;
        if (self.dispatch.EnumeratePhysicalDevices(self.handle, &count, null) < 0) return error.VkEnumeratePhysicalDevicesCount;

        const allocation = try allocator.alloc(c.VkPhysicalDevice, count);
        errdefer allocator.free(allocation);

        if (self.dispatch.EnumeratePhysicalDevices(self.handle, &count, allocation.ptr) < 0) return error.VkEnumeratePhysicalDevices;
        return allocation;
    }

    pub fn getPhysicalDeviceQueueFamilyProperties(self: *const @This(), physical_device: c.VkPhysicalDevice, allocator: std.mem.Allocator) ![]c.VkQueueFamilyProperties {
        var count: u32 = undefined;
        self.dispatch.GetPhysicalDeviceQueueFamilyProperties(physical_device, &count, null);

        const allocation = try allocator.alloc(c.VkQueueFamilyProperties, count);
        errdefer allocator.free(allocation);

        self.dispatch.GetPhysicalDeviceQueueFamilyProperties(physical_device, &count, allocation.ptr);
        return allocation;
    }

    pub fn getPhysicalDeviceFeatures(self: *const @This(), physical_device: c.VkPhysicalDevice) c.VkPhysicalDeviceFeatures {
        var result: c.VkPhysicalDeviceFeatures = undefined;
        self.dispatch.GetPhysicalDeviceFeatures(physical_device, &result);

        return result;
    }

    pub fn requestPhysicalDevice(self: *const @This(), allocator: std.mem.Allocator, maybe_surface: ?*Surface) !PhysicalDevice {
        const physical_devices = try self.enumeratePhysicalDevices(allocator);
        defer allocator.free(physical_devices);

        for (physical_devices) |physical_device| {
            const queue_families_properties = try self.getPhysicalDeviceQueueFamilyProperties(physical_device, allocator);
            defer allocator.free(queue_families_properties);

            const features = self.getPhysicalDeviceFeatures(physical_device);

            var graphics_queue_family_index: ?u32 = null;
            var present_queue_family_index: ?u32 = null;

            for (queue_families_properties, 0..) |queue_family_properties, index| {
                var is_surface_supported = true;
                if (maybe_surface) |surface| is_surface_supported = try surface.getPhysicalDeviceSupport(physical_device, @intCast(index));

                if (is_surface_supported) present_queue_family_index = @intCast(index);
                if ((queue_family_properties.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) != 0) graphics_queue_family_index = @intCast(index);

                if (graphics_queue_family_index != null and present_queue_family_index != null and features.samplerAnisotropy == c.VK_TRUE) return PhysicalDevice.init(physical_device, self, graphics_queue_family_index.?, present_queue_family_index.?);
            }
        }

        return error.NoCompatiblePhysicalDevices;
    }
};

pub const Surface = struct {
    handle: c.VkSurfaceKHR,
    instance: *Instance,

    pub fn init(instance: *Instance, window: *Window) !@This() {
        var handle: c.VkSurfaceKHR = undefined;
        if (c.SDL_Vulkan_CreateSurface(window.handle, instance.handle, &handle) == c.SDL_FALSE) return error.SDLVulkanCreateInstance;

        return .{
            .handle = handle,
            .instance = instance,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.instance.dispatch.DestroySurfaceKHR(self.instance.handle, self.handle, null);
    }

    pub fn getPhysicalDeviceSupport(self: *@This(), device: c.VkPhysicalDevice, queue_family_index: u32) !bool {
        var does_support: c.VkBool32 = undefined;
        if (self.instance.dispatch.GetPhysicalDeviceSurfaceSupportKHR(device, queue_family_index, self.handle, &does_support) < 0) return error.VkGetPhysicalDeviceSurfaceSupport;

        return does_support != 0;
    }
};

pub const PhysicalDevice = struct {
    pub const SwapChainSupportDetails = struct {
        capabilities: c.VkSurfaceCapabilitiesKHR,
        formats: []c.VkSurfaceFormatKHR,
        present_modes: []c.VkPresentModeKHR,
        allocator: std.mem.Allocator,

        pub fn deinit(self: *@This()) void {
            self.allocator.free(self.formats);
            self.allocator.free(self.present_modes);
        }
    };

    instance: *const Instance,
    handle: c.VkPhysicalDevice,
    graphics_queue_family_index: u32,
    present_queue_family_index: u32,
    properties: c.VkPhysicalDeviceProperties,

    pub fn init(handle: c.VkPhysicalDevice, instance: *const Instance, graphics_queue_family_index: u32, present_queue_family_index: u32) @This() {
        var properties: c.VkPhysicalDeviceProperties = undefined;
        instance.dispatch.GetPhysicalDeviceProperties(handle, &properties);

        return .{
            .instance = instance,
            .handle = handle,
            .graphics_queue_family_index = graphics_queue_family_index,
            .present_queue_family_index = present_queue_family_index,
            .properties = properties,
        };
    }

    pub fn createLogicalDevice(self: *const @This(), allocation_callbacks: AllocationCallbacks) !LogicalDevice {
        return LogicalDevice.init(self, allocation_callbacks);
    }

    pub fn getSwapchainSupport(self: *const @This(), surface: *const Surface, allocator: std.mem.Allocator) !SwapChainSupportDetails {
        var details: SwapChainSupportDetails = undefined;
        details.present_modes = &[_]c.VkPresentModeKHR{};
        details.formats = &[_]c.VkSurfaceFormatKHR{};

        if (self.instance.dispatch.GetPhysicalDeviceSurfaceCapabilitiesKHR(self.handle, surface.handle, &details.capabilities) < 0) return error.VkGetPhysicalDeviceSurfaceCapabilities;

        var format_count: u32 = undefined;
        if (self.instance.dispatch.GetPhysicalDeviceSurfaceFormatsKHR(self.handle, surface.handle, &format_count, null) < 0) return error.VkGetPhysicalDeviceSurfaceFormatCount;

        if (format_count != 0) {
            details.formats = try allocator.alloc(c.VkSurfaceFormatKHR, format_count);
            if (self.instance.dispatch.GetPhysicalDeviceSurfaceFormatsKHR(self.handle, surface.handle, &format_count, details.formats.ptr) < 0) return error.VkGetPhysicalDeviceSurfaceFormats;
        }

        var present_mode_count: u32 = undefined;
        if (self.instance.dispatch.GetPhysicalDeviceSurfacePresentModesKHR(self.handle, surface.handle, &present_mode_count, null) < 0) return error.VkGetPhysicalDeviceSurfacePresentModeCount;

        if (present_mode_count != 0) {
            details.present_modes = try allocator.alloc(c.VkPresentModeKHR, present_mode_count);
            if (self.instance.dispatch.GetPhysicalDeviceSurfacePresentModesKHR(self.handle, surface.handle, &present_mode_count, details.present_modes.ptr) < 0) return error.VkGetPhysicalDeviceSurfacePresentModeCount;
        }

        details.allocator = allocator;

        return details;
    }

    pub fn findMemoryType(self: *const @This(), filter: u32, properties: c.VkMemoryPropertyFlags) !u32 {
        var mem_properties: c.VkPhysicalDeviceMemoryProperties = undefined;
        self.instance.dispatch.GetPhysicalDeviceMemoryProperties(self.handle, &mem_properties);
        for (0..mem_properties.memoryTypeCount) |i| {
            if ((filter & (@as(u32, 1) << @intCast(i))) != 0 and (mem_properties.memoryTypes[i].propertyFlags & properties) == properties) return @intCast(i);
        }

        return error.NoSuitableMemoryType;
    }
};

pub const LogicalDevice = struct {
    pub const Dispatch = struct {
        DestroyDevice: std.meta.Child(c.PFN_vkDestroyDevice) = undefined,
        GetDeviceQueue: std.meta.Child(c.PFN_vkGetDeviceQueue) = undefined,
        CreateImageView: std.meta.Child(c.PFN_vkCreateImageView) = undefined,
        DestroyImageView: std.meta.Child(c.PFN_vkDestroyImageView) = undefined,
        CreateShaderModule: std.meta.Child(c.PFN_vkCreateShaderModule) = undefined,
        DestroyShaderModule: std.meta.Child(c.PFN_vkDestroyShaderModule) = undefined,
        CreatePipelineLayout: std.meta.Child(c.PFN_vkCreatePipelineLayout) = undefined,
        DestroyPipelineLayout: std.meta.Child(c.PFN_vkDestroyPipelineLayout) = undefined,
        CreateRenderPass: std.meta.Child(c.PFN_vkCreateRenderPass) = undefined,
        DestroyRenderPass: std.meta.Child(c.PFN_vkDestroyRenderPass) = undefined,
        CreateGraphicsPipelines: std.meta.Child(c.PFN_vkCreateGraphicsPipelines) = undefined,
        DestroyPipeline: std.meta.Child(c.PFN_vkDestroyPipeline) = undefined,
        CreateSwapchainKHR: std.meta.Child(c.PFN_vkCreateSwapchainKHR) = undefined,
        DestroySwapchainKHR: std.meta.Child(c.PFN_vkDestroySwapchainKHR) = undefined,
        GetSwapchainImagesKHR: std.meta.Child(c.PFN_vkGetSwapchainImagesKHR) = undefined,
        CreateFence: std.meta.Child(c.PFN_vkCreateFence) = undefined,
        DestroyFence: std.meta.Child(c.PFN_vkDestroyFence) = undefined,
        CreateSemaphore: std.meta.Child(c.PFN_vkCreateSemaphore) = undefined,
        DestroySemaphore: std.meta.Child(c.PFN_vkDestroySemaphore) = undefined,
        AcquireNextImageKHR: std.meta.Child(c.PFN_vkAcquireNextImageKHR) = undefined,
        QueuePresentKHR: std.meta.Child(c.PFN_vkQueuePresentKHR) = undefined,
        WaitForFences: std.meta.Child(c.PFN_vkWaitForFences) = undefined,
        ResetFences: std.meta.Child(c.PFN_vkResetFences) = undefined,
        DeviceWaitIdle: std.meta.Child(c.PFN_vkDeviceWaitIdle) = undefined,
        CreateCommandPool: std.meta.Child(c.PFN_vkCreateCommandPool) = undefined,
        DestroyCommandPool: std.meta.Child(c.PFN_vkDestroyCommandPool) = undefined,
        AllocateCommandBuffers: std.meta.Child(c.PFN_vkAllocateCommandBuffers) = undefined,
        BeginCommandBuffer: std.meta.Child(c.PFN_vkBeginCommandBuffer) = undefined,
        EndCommandBuffer: std.meta.Child(c.PFN_vkEndCommandBuffer) = undefined,
        QueueSubmit: std.meta.Child(c.PFN_vkQueueSubmit) = undefined,
        CmdPipelineBarrier: std.meta.Child(c.PFN_vkCmdPipelineBarrier) = undefined,
        CreateImage: std.meta.Child(c.PFN_vkCreateImage) = undefined,
        DestroyImage: std.meta.Child(c.PFN_vkDestroyImage) = undefined,
        AllocateMemory: std.meta.Child(c.PFN_vkAllocateMemory) = undefined,
        FreeMemory: std.meta.Child(c.PFN_vkFreeMemory) = undefined,
        BindImageMemory: std.meta.Child(c.PFN_vkBindImageMemory) = undefined,
        GetImageMemoryRequirements: std.meta.Child(c.PFN_vkGetImageMemoryRequirements) = undefined,
        CreateFramebuffer: std.meta.Child(c.PFN_vkCreateFramebuffer) = undefined,
        DestroyFramebuffer: std.meta.Child(c.PFN_vkDestroyFramebuffer) = undefined,
        CmdBeginRenderPass: std.meta.Child(c.PFN_vkCmdBeginRenderPass) = undefined,
        CmdEndRenderPass: std.meta.Child(c.PFN_vkCmdEndRenderPass) = undefined,
        CmdBindPipeline: std.meta.Child(c.PFN_vkCmdBindPipeline) = undefined,
        CmdDraw: std.meta.Child(c.PFN_vkCmdDraw) = undefined,
        CmdPushConstants: std.meta.Child(c.PFN_vkCmdPushConstants) = undefined,
        CreateBuffer: std.meta.Child(c.PFN_vkCreateBuffer) = undefined,
        DestroyBuffer: std.meta.Child(c.PFN_vkDestroyBuffer) = undefined,
        BindBufferMemory: std.meta.Child(c.PFN_vkBindBufferMemory) = undefined,
        GetBufferMemoryRequirements: std.meta.Child(c.PFN_vkGetBufferMemoryRequirements) = undefined,
        MapMemory: std.meta.Child(c.PFN_vkMapMemory) = undefined,
        UnmapMemory: std.meta.Child(c.PFN_vkUnmapMemory) = undefined,
        CmdBindVertexBuffers: std.meta.Child(c.PFN_vkCmdBindVertexBuffers) = undefined,
        QueueWaitIdle: std.meta.Child(c.PFN_vkQueueWaitIdle) = undefined,
        FreeCommandBuffers: std.meta.Child(c.PFN_vkFreeCommandBuffers) = undefined,
        CmdCopyBuffer: std.meta.Child(c.PFN_vkCmdCopyBuffer) = undefined,
        CmdCopyBufferToImage: std.meta.Child(c.PFN_vkCmdCopyBufferToImage) = undefined,
        CreateSampler: std.meta.Child(c.PFN_vkCreateSampler) = undefined,
        DestroySampler: std.meta.Child(c.PFN_vkDestroySampler) = undefined,
        CreateDescriptorSetLayout: std.meta.Child(c.PFN_vkCreateDescriptorSetLayout) = undefined,
        DestroyDescriptorSetLayout: std.meta.Child(c.PFN_vkDestroyDescriptorSetLayout) = undefined,
        CreateDescriptorPool: std.meta.Child(c.PFN_vkCreateDescriptorPool) = undefined,
        DestroyDescriptorPool: std.meta.Child(c.PFN_vkDestroyDescriptorPool) = undefined,
        AllocateDescriptorSets: std.meta.Child(c.PFN_vkAllocateDescriptorSets) = undefined,
        UpdateDescriptorSets: std.meta.Child(c.PFN_vkUpdateDescriptorSets) = undefined,
        CmdBindDescriptorSets: std.meta.Child(c.PFN_vkCmdBindDescriptorSets) = undefined,
        CmdSetViewport: std.meta.Child(c.PFN_vkCmdSetViewport) = undefined,
        CmdSetScissor: std.meta.Child(c.PFN_vkCmdSetScissor) = undefined,
        CmdDrawIndexed: std.meta.Child(c.PFN_vkCmdDrawIndexed) = undefined,
        CmdBindIndexBuffer: std.meta.Child(c.PFN_vkCmdBindIndexBuffer) = undefined,
    };

    handle: c.VkDevice,
    allocation_callbacks: AllocationCallbacks,
    physical_device: *const PhysicalDevice,
    graphics_queue: c.VkQueue,
    present_queue: c.VkQueue,
    dispatch: Dispatch,

    pub fn init(physical_device: *const PhysicalDevice, allocation_callbacks: AllocationCallbacks) !@This() {
        const queue_priorities = [_]f32{1.0};

        const queue_create_infos = [_]c.VkDeviceQueueCreateInfo{
            std.mem.zeroInit(c.VkDeviceQueueCreateInfo, c.VkDeviceQueueCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .queueFamilyIndex = physical_device.graphics_queue_family_index,
                .queueCount = @as(u32, queue_priorities.len),
                .pQueuePriorities = &queue_priorities,
            }),
            std.mem.zeroInit(c.VkDeviceQueueCreateInfo, c.VkDeviceQueueCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .queueFamilyIndex = physical_device.present_queue_family_index,
                .queueCount = @as(u32, queue_priorities.len),
                .pQueuePriorities = &queue_priorities,
            }),
        };

        const extensions = [_][*c]const u8{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        };

        const enabled_features = std.mem.zeroInit(c.VkPhysicalDeviceFeatures, c.VkPhysicalDeviceFeatures{
            .samplerAnisotropy = c.VK_TRUE,
            .fillModeNonSolid = c.VK_TRUE,
        });

        const create_info = std.mem.zeroInit(c.VkDeviceCreateInfo, c.VkDeviceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = if (physical_device.graphics_queue_family_index == physical_device.present_queue_family_index) 1 else 2,
            .pQueueCreateInfos = &queue_create_infos,
            .enabledExtensionCount = @as(u32, extensions.len),
            .ppEnabledExtensionNames = &extensions,
            .pEnabledFeatures = &enabled_features,
        });

        var handle: c.VkDevice = undefined;
        if (physical_device.instance.dispatch.CreateDevice(physical_device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateDevice;

        const dispatch = try physical_device.instance.load(Dispatch, handle);

        var graphics_queue: c.VkQueue = undefined;
        dispatch.GetDeviceQueue(handle, physical_device.graphics_queue_family_index, 0, &graphics_queue);

        var present_queue: c.VkQueue = undefined;
        dispatch.GetDeviceQueue(handle, physical_device.present_queue_family_index, 0, &present_queue);

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .physical_device = physical_device,
            .graphics_queue = graphics_queue,
            .present_queue = present_queue,
            .dispatch = dispatch,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.dispatch.DestroyDevice(self.handle, self.allocation_callbacks);
    }

    pub fn createSwapchain(self: *const @This(), surface: *Surface, image_extent: Extent2D, allocator: std.mem.Allocator, allocation_callbacks: AllocationCallbacks) !Swapchain {
        return Swapchain.init(surface, self, image_extent, allocator, allocation_callbacks);
    }

    pub fn createImageView(self: *const @This(), create_info: c.VkImageViewCreateInfo, allocation_callbacks: AllocationCallbacks) !c.VkImageView {
        var handle: c.VkImageView = undefined;
        if (self.dispatch.CreateImageView(self.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateImageView;

        return handle;
    }

    pub fn waitIdle(self: *const @This()) !void {
        if (self.dispatch.DeviceWaitIdle(self.handle) < 0) return error.VkDeviceWaitIdle;
    }

    pub fn createCommandPool(self: *const @This(), queue_family_index: u32, allocation_callbacks: AllocationCallbacks) !CommandPool {
        return CommandPool.init(self, queue_family_index, allocation_callbacks);
    }

    pub fn findSupportedFormat(self: *const @This(), candidates: []const c.VkFormat, tiling: c.VkImageTiling, features: c.VkFormatFeatureFlags) !c.VkFormat {
        for (candidates) |format| {
            var props: c.VkFormatProperties = undefined;
            self.physical_device.instance.dispatch.GetPhysicalDeviceFormatProperties(self.physical_device.handle, format, &props);

            if (tiling == c.VK_IMAGE_TILING_LINEAR and (props.linearTilingFeatures & features) == features) {
                return format;
            } else if (tiling == c.VK_IMAGE_TILING_OPTIMAL and (props.optimalTilingFeatures & features) == features) {
                return format;
            }
        }

        return error.NoSupportedFormat;
    }

    pub fn allocateMemory(self: *const @This(), properties: c.VkMemoryPropertyFlags, requirements: c.VkMemoryRequirements, allocation_callbacks: AllocationCallbacks) !c.VkDeviceMemory {
        const allocate_info = std.mem.zeroInit(c.VkMemoryAllocateInfo, c.VkMemoryAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .allocationSize = requirements.size,
            .memoryTypeIndex = try self.physical_device.findMemoryType(requirements.memoryTypeBits, properties),
        });

        var handle: c.VkDeviceMemory = undefined;
        if (self.dispatch.AllocateMemory(self.handle, &allocate_info, allocation_callbacks, &handle) < 0) return error.VkAllocateMemory;

        return handle;
    }

    pub fn freeMemory(self: *const @This(), memory: c.VkDeviceMemory, allocation_callbacks: AllocationCallbacks) void {
        self.dispatch.FreeMemory(self.handle, memory, allocation_callbacks);
    }
};

pub const Image = struct {
    handle: c.VkImage,
    view: c.VkImageView,
    memory: c.VkDeviceMemory,
    device: *const LogicalDevice,
    allocation_callbacks: AllocationCallbacks,
    should_destroy_image: bool,
    extent: c.VkExtent3D,

    pub fn init(device: *const LogicalDevice, create_info: c.VkImageCreateInfo, allocation_callbacks: AllocationCallbacks) !@This() {
        var handle: c.VkImage = undefined;
        if (device.dispatch.CreateImage(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateImage;

        return .{
            .handle = handle,
            .view = null,
            .memory = null,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
            .should_destroy_image = true,
            .extent = create_info.extent,
        };
    }

    pub fn fromHandle(device: *const LogicalDevice, handle: c.VkImage, extent: c.VkExtent3D, allocation_callbacks: AllocationCallbacks) @This() {
        return .{
            .handle = handle,
            .view = null,
            .memory = null,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
            .should_destroy_image = false,
            .extent = extent,
        };
    }

    pub fn deinit(self: *@This()) void {
        if (self.view != null) self.device.dispatch.DestroyImageView(self.device.handle, self.view, self.allocation_callbacks);
        if (self.should_destroy_image) self.device.dispatch.DestroyImage(self.device.handle, self.handle, self.allocation_callbacks);
        if (self.memory != null) self.device.freeMemory(self.memory, self.allocation_callbacks);
    }

    pub fn createView(self: *@This(), view_type: c.VkImageViewType, format: c.VkFormat, subresource_range: c.VkImageSubresourceRange) !void {
        if (self.view != null) return error.ViewNotNull;
        self.view = try self.device.createImageView(std.mem.zeroInit(c.VkImageViewCreateInfo, c.VkImageViewCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
            .image = self.handle,
            .viewType = view_type,
            .format = format,
            .subresourceRange = subresource_range,
        }), self.allocation_callbacks);
    }

    pub fn createMemory(self: *@This(), properties: c.VkMemoryPropertyFlags) !void {
        if (self.memory != null) return error.MemoryNotNull;

        var requirements: c.VkMemoryRequirements = undefined;
        self.device.dispatch.GetImageMemoryRequirements(self.device.handle, self.handle, &requirements);

        self.memory = try self.device.allocateMemory(properties, requirements, self.allocation_callbacks);

        if (self.device.dispatch.BindImageMemory(self.device.handle, self.handle, self.memory, 0) < 0) return error.VkBindImageMemory;
    }

    pub fn uploadData(self: *@This(), data: anytype, command_pool: *CommandPool) !void {
        var staging_buffer = try Buffer.init(self.device, data.len * @sizeOf(@TypeOf(data[0])), BufferUsage.TRANSFER_SRC_BIT, self.allocation_callbacks);
        defer staging_buffer.deinit();
        try staging_buffer.createMemory(MemoryProperty.HOST_VISIBLE_BIT | MemoryProperty.HOST_COHERENT_BIT);
        try staging_buffer.uploadData(data);

        try staging_buffer.copyToImage(self, self.extent.width, self.extent.height, self.extent.depth, command_pool);
    }

    pub fn transitionLayout(self: *@This(), old_layout: c.VkImageLayout, new_layout: c.VkImageLayout, src_access_mask: c.VkAccessFlags, dst_access_mask: c.VkAccessFlags, src_stage: c.VkPipelineStageFlags, dst_stage: c.VkPipelineStageFlags, command_pool: *CommandPool) !void {
        var command_buffer = try command_pool.beginSingleTimeCommands();

        var barrier = std.mem.zeroInit(c.VkImageMemoryBarrier, c.VkImageMemoryBarrier{
            .sType = c.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
            .oldLayout = old_layout,
            .newLayout = new_layout,
            .srcQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = c.VK_QUEUE_FAMILY_IGNORED,
            .image = self.handle,
            .srcAccessMask = src_access_mask,
            .dstAccessMask = dst_access_mask,
            .subresourceRange = c.VkImageSubresourceRange{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .baseMipLevel = 0,
                .levelCount = 1,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
        });

        self.device.dispatch.CmdPipelineBarrier(command_buffer.handle, src_stage, dst_stage, 0, 0, null, 0, null, 1, &barrier);

        try command_pool.endSingleTimeCommands(&command_buffer);
    }
};

pub const Buffer = struct {
    handle: c.VkBuffer,
    memory: c.VkDeviceMemory,
    memory_size: c.VkDeviceSize,
    mapped: ?*anyopaque,
    mapped_count: u64,
    device: *const LogicalDevice,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, size: c.VkDeviceSize, usage: c.VkBufferUsageFlags, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkBufferCreateInfo, c.VkBufferCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
            .size = size,
            .usage = usage,
            .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
        });

        var handle: c.VkBuffer = undefined;
        if (device.dispatch.CreateBuffer(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateBuffer;

        return .{
            .handle = handle,
            .memory = null,
            .memory_size = size,
            .mapped = null,
            .mapped_count = 0,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyBuffer(self.device.handle, self.handle, self.allocation_callbacks);
        if (self.memory != null) self.device.freeMemory(self.memory, self.allocation_callbacks);
    }

    pub fn createMemory(self: *@This(), properties: c.VkMemoryPropertyFlags) !void {
        var requirements: c.VkMemoryRequirements = undefined;
        self.device.dispatch.GetBufferMemoryRequirements(self.device.handle, self.handle, &requirements);

        self.memory = try self.device.allocateMemory(properties, requirements, self.allocation_callbacks);

        if (self.device.dispatch.BindBufferMemory(self.device.handle, self.handle, self.memory, 0) < 0) return error.VkBindBufferMemory;
    }

    pub fn map(self: *@This()) !*anyopaque {
        if (self.mapped_count == 0) {
            var result: *anyopaque = undefined;
            if (self.device.dispatch.MapMemory(self.device.handle, self.memory, 0, self.memory_size, 0, @ptrCast(&result)) < 0) return error.VkMapMemory;

            self.mapped = result;
            self.mapped_count = 1;
            return result;
        }

        self.mapped_count += 1;
        return self.mapped.?;
    }

    pub fn unmap(self: *@This()) void {
        if (self.mapped_count == 0) return;
        if (self.mapped_count == 1) self.device.dispatch.UnmapMemory(self.device.handle, self.memory);

        self.mapped_count -= 1;
    }

    pub fn uploadData(self: *@This(), data: anytype) !void {
        const mapped = try self.map();
        @memcpy(@as([*]u8, @ptrCast(mapped)), @as([*]u8, @ptrCast(@constCast(data.ptr)))[0 .. data.len * @sizeOf(@TypeOf(data[0]))]);
        self.unmap();
    }

    pub fn copy(self: *@This(), dst: *@This(), size: u64, command_pool: *CommandPool) !void {
        const command_buffer = try command_pool.beginSingleTimeCommands();
        command_buffer.copyBuffer(self, dst, size);
        try command_pool.endSingleTimeCommands(&command_buffer);
    }

    pub fn copyToImage(self: *@This(), dst: *Image, width: u32, height: u32, depth: u32, command_pool: *CommandPool) !void {
        var command_buffer = try command_pool.beginSingleTimeCommands();

        const region = std.mem.zeroInit(c.VkBufferImageCopy, c.VkBufferImageCopy{
            .imageSubresource = c.VkImageSubresourceLayers{
                .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                .mipLevel = 0,
                .baseArrayLayer = 0,
                .layerCount = 1,
            },
            .imageExtent = c.VkExtent3D{
                .width = width,
                .height = height,
                .depth = depth,
            },
        });

        self.device.dispatch.CmdCopyBufferToImage(command_buffer.handle, self.handle, dst.handle, c.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &region);

        try command_pool.endSingleTimeCommands(&command_buffer);
    }
};

pub const RenderPass = struct {
    pub const Attachment = struct {
        format: c.VkFormat = c.VK_FORMAT_R8G8B8A8_SRGB,
        layout: c.VkImageLayout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    handle: c.VkRenderPass,
    device: *const LogicalDevice,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, color_attachments: []const Attachment, has_depth: bool, double_pass: bool, allocator: std.mem.Allocator, allocation_callbacks: AllocationCallbacks) !@This() {
        const depth_format = try device.findSupportedFormat(&[_]c.VkFormat{ c.VK_FORMAT_D32_SFLOAT, c.VK_FORMAT_D32_SFLOAT_S8_UINT, c.VK_FORMAT_D24_UNORM_S8_UINT }, c.VK_IMAGE_TILING_OPTIMAL, c.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);

        var attachment_descriptions = try allocator.alloc(c.VkAttachmentDescription, color_attachments.len + 1);
        defer allocator.free(attachment_descriptions);
        var attachment_references = try allocator.alloc(c.VkAttachmentReference, color_attachments.len + 1);
        defer allocator.free(attachment_references);

        if (has_depth) {
            attachment_descriptions[0] = c.VkAttachmentDescription{
                .format = depth_format,
                .samples = c.VK_SAMPLE_COUNT_1_BIT,
                .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
                .storeOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
                .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
                .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
                .finalLayout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            };

            attachment_references[0] = c.VkAttachmentReference{
                .attachment = 0,
                .layout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            };
        }

        for (color_attachments, if (has_depth) 1 else 0..) |color_attachment, i| {
            //         .samples = vk.c.VK_SAMPLE_COUNT_1_BIT,
            //         .loadOp = vk.c.VK_ATTACHMENT_LOAD_OP_CLEAR,
            //         .storeOp = vk.c.VK_ATTACHMENT_STORE_OP_STORE,
            //         .stencilLoadOp = vk.c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
            //         .stencilStoreOp = vk.c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
            //         .initialLayout = vk.c.VK_IMAGE_LAYOUT_UNDEFINED,
            //         .finalLayout = vk.c.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
            //         .format = vk.c.VK_FORMAT_R8G8B8A8_UNORM,

            attachment_descriptions[i] = c.VkAttachmentDescription{
                .format = color_attachment.format,
                .samples = c.VK_SAMPLE_COUNT_1_BIT,
                .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
                .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
                .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
                .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
                .finalLayout = color_attachment.layout,
            };

            attachment_references[i] = c.VkAttachmentReference{
                .attachment = @intCast(i),
                .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
            };
        }

        const subpass = c.VkSubpassDescription{
            .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            .colorAttachmentCount = @intCast(attachment_descriptions[1..].len),
            .pColorAttachments = attachment_references[1..].ptr,
            .pDepthStencilAttachment = &attachment_references[0],
        };

        const subpass_dependencies = if (double_pass) [2]c.VkSubpassDependency{
            c.VkSubpassDependency{
                .srcSubpass = c.VK_SUBPASS_EXTERNAL,
                .dstSubpass = 0,
                .srcStageMask = c.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
                .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                .srcAccessMask = c.VK_ACCESS_MEMORY_READ_BIT,
                .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
                .dependencyFlags = c.VK_DEPENDENCY_BY_REGION_BIT,
            },
            c.VkSubpassDependency{
                .srcSubpass = 0,
                .dstSubpass = c.VK_SUBPASS_EXTERNAL,
                .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                .dstStageMask = c.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
                .srcAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
                .dstAccessMask = c.VK_ACCESS_MEMORY_READ_BIT,
                .dependencyFlags = c.VK_DEPENDENCY_BY_REGION_BIT,
            },
        } else [2]c.VkSubpassDependency{
            c.VkSubpassDependency{
                .dstSubpass = 0,
                .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
                .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
                .srcSubpass = c.VK_SUBPASS_EXTERNAL,
                .srcAccessMask = 0,
                .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
            },
            std.mem.zeroes(c.VkSubpassDependency),
        };

        const create_info = c.VkRenderPassCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
            .attachmentCount = @intCast(attachment_descriptions.len),
            .pAttachments = attachment_descriptions.ptr,
            .subpassCount = 1,
            .pSubpasses = &subpass,
            .dependencyCount = if (double_pass) 2 else 1,
            .pDependencies = &subpass_dependencies,
        };

        var handle: c.VkRenderPass = undefined;
        if (device.dispatch.CreateRenderPass(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateRenderPass;

        return .{
            .handle = handle,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyRenderPass(self.device.handle, self.handle, self.allocation_callbacks);
    }
};

pub const Framebuffer = struct {
    handle: c.VkFramebuffer,
    device: *const LogicalDevice,
    attachment_views: []c.VkImageView,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, extent: Extent2D, attachment_views: []c.VkImageView, render_pass: *const RenderPass, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = c.VkFramebufferCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
            .renderPass = render_pass.handle,
            .attachmentCount = @intCast(attachment_views.len),
            .pAttachments = attachment_views.ptr,
            .width = extent.x,
            .height = extent.y,
            .layers = 1,
        };

        var handle: c.VkFramebuffer = undefined;
        if (device.dispatch.CreateFramebuffer(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateFrameBuffer;

        return .{
            .handle = handle,
            .device = device,
            .attachment_views = attachment_views,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyFramebuffer(self.device, self.handle, self.allocation_callbacks);
    }
};

pub const Swapchain = struct {
    handle: c.VkSwapchainKHR,
    allocation_callbacks: AllocationCallbacks,
    vulkan_library: *Library,
    device: *const LogicalDevice,
    color_images: []Image,
    depth_images: []Image,
    render_pass: RenderPass,
    frame_buffers: []c.VkFramebuffer,
    image_available_semaphores: []c.VkSemaphore,
    render_finished_semaphores: []c.VkSemaphore,
    in_flight_fences: []c.VkFence,
    images_in_flight: []c.VkFence,
    current_frame: u32,
    allocator: std.mem.Allocator,
    extent: Extent2D,

    pub fn init(surface: *Surface, device: *const LogicalDevice, window_extent: Extent2D, allocator: std.mem.Allocator, allocation_callbacks: AllocationCallbacks) !@This() {
        var swapchain_support = try device.physical_device.getSwapchainSupport(surface, allocator);
        defer swapchain_support.deinit();

        var surface_format: c.VkSurfaceFormatKHR = swapchain_support.formats[0];
        for (swapchain_support.formats) |available_format| {
            if (available_format.format == c.VK_FORMAT_B8G8R8A8_SRGB and available_format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
                surface_format = available_format;
                break;
            }
        }

        var present_mode: c.VkPresentModeKHR = c.VK_PRESENT_MODE_FIFO_KHR;
        for (swapchain_support.present_modes) |available_present_mode| {
            if (available_present_mode == c.VK_PRESENT_MODE_MAILBOX_KHR) {
                present_mode = c.VK_PRESENT_MODE_MAILBOX_KHR;
                break;
            }
        }

        var extent: c.VkExtent2D = undefined;
        if (swapchain_support.capabilities.currentExtent.width != std.math.maxInt(u32)) {
            extent = swapchain_support.capabilities.currentExtent;
        } else {
            var actual_extent: c.VkExtent2D = .{ .width = window_extent.x, .height = window_extent.y };
            actual_extent.width = @max(swapchain_support.capabilities.minImageExtent.width, @min(swapchain_support.capabilities.maxImageExtent.width, actual_extent.width));
            actual_extent.height = @max(swapchain_support.capabilities.minImageExtent.height, @min(swapchain_support.capabilities.maxImageExtent.height, actual_extent.height));

            extent = actual_extent;
        }

        const queue_family_indices = [_]u32{ device.physical_device.graphics_queue_family_index, device.physical_device.present_queue_family_index };

        const create_info = std.mem.zeroInit(c.VkSwapchainCreateInfoKHR, c.VkSwapchainCreateInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
            .surface = surface.handle,
            .presentMode = swapchain_support.present_modes[0],
            .preTransform = swapchain_support.capabilities.currentTransform,
            .imageFormat = c.VK_FORMAT_B8G8R8A8_SRGB,
            .imageColorSpace = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
            .clipped = c.VK_TRUE,
            .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
            .queueFamilyIndexCount = if (queue_family_indices[0] == queue_family_indices[1]) 1 else @as(u32, queue_family_indices.len),
            .pQueueFamilyIndices = &queue_family_indices,
            .imageSharingMode = if (queue_family_indices[0] == queue_family_indices[1]) c.VK_SHARING_MODE_EXCLUSIVE else c.VK_SHARING_MODE_CONCURRENT,
            .imageArrayLayers = 1,
            .imageExtent = extent,
            .minImageCount = if (swapchain_support.capabilities.maxImageCount == 0) swapchain_support.capabilities.minImageCount + 1 else @min(swapchain_support.capabilities.minImageCount + 1, swapchain_support.capabilities.maxImageCount),
        });

        var handle: c.VkSwapchainKHR = undefined;
        if (device.dispatch.CreateSwapchainKHR(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateSwapchain;
        errdefer device.dispatch.DestroySwapchainKHR(device.handle, handle, allocation_callbacks);

        var image_count: u32 = undefined;
        if (device.dispatch.GetSwapchainImagesKHR(device.handle, handle, &image_count, null) < 0) return error.VkGetSwapchainImageCount;

        const color_image_handles = try allocator.alloc(c.VkImage, image_count);
        defer allocator.free(color_image_handles);

        if (device.dispatch.GetSwapchainImagesKHR(device.handle, handle, &image_count, color_image_handles.ptr) < 0) return error.VkGetSwapchainImages;

        const color_images = try allocator.alloc(Image, image_count);
        errdefer allocator.free(color_images);

        for (color_image_handles, color_images) |color_image_handle, *color_image| {
            color_image.* = Image.fromHandle(device, color_image_handle, .{ .width = extent.width, .height = extent.height, .depth = 1 }, allocation_callbacks);
            try color_image.createView(
                c.VK_IMAGE_VIEW_TYPE_2D,
                create_info.imageFormat,
                c.VkImageSubresourceRange{
                    .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseArrayLayer = 0,
                    .baseMipLevel = 0,
                    .layerCount = 1,
                    .levelCount = 1,
                },
            );
        }

        const depth_format = try device.findSupportedFormat(&[_]c.VkFormat{ c.VK_FORMAT_D32_SFLOAT, c.VK_FORMAT_D32_SFLOAT_S8_UINT, c.VK_FORMAT_D24_UNORM_S8_UINT }, c.VK_IMAGE_TILING_OPTIMAL, c.VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT);

        // const depth_attachment = std.mem.zeroInit(c.VkAttachmentDescription, c.VkAttachmentDescription{
        //     .format = depth_format,
        //     .samples = c.VK_SAMPLE_COUNT_1_BIT,
        //     .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        //     .storeOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        //     .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        //     .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        //     .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        //     .finalLayout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        // });

        // const depth_attachment_ref = std.mem.zeroInit(c.VkAttachmentReference, c.VkAttachmentReference{
        //     .attachment = 1,
        //     .layout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        // });

        // const color_attachment = std.mem.zeroInit(c.VkAttachmentDescription, c.VkAttachmentDescription{
        //     .format = surface_format.format,
        //     .samples = c.VK_SAMPLE_COUNT_1_BIT,
        //     .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        //     .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
        //     .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        //     .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        //     .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
        //     .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        // });

        // const color_attachment_ref = std.mem.zeroInit(c.VkAttachmentReference, c.VkAttachmentReference{
        //     .attachment = 0,
        //     .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        // });

        // const subpass = std.mem.zeroInit(c.VkSubpassDescription, c.VkSubpassDescription{
        //     .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        //     .colorAttachmentCount = 1,
        //     .pColorAttachments = &color_attachment_ref,
        //     .pDepthStencilAttachment = &depth_attachment_ref,
        // });

        // const dependency = std.mem.zeroInit(c.VkSubpassDependency, c.VkSubpassDependency{
        //     .dstSubpass = 0,
        //     .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
        //     .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        //     .srcSubpass = c.VK_SUBPASS_EXTERNAL,
        //     .srcAccessMask = 0,
        //     .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        // });

        // const attachments = [_]c.VkAttachmentDescription{ color_attachment, depth_attachment };

        // const render_pass_info = std.mem.zeroInit(c.VkRenderPassCreateInfo, c.VkRenderPassCreateInfo{
        //     .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        //     .attachmentCount = attachments.len,
        //     .pAttachments = &attachments,
        //     .subpassCount = 1,
        //     .pSubpasses = &subpass,
        //     .dependencyCount = 1,
        //     .pDependencies = &dependency,
        // });

        // var render_pass: c.VkRenderPass = undefined;
        // if (device.dispatch.CreateRenderPass(device.handle, &render_pass_info, allocation_callbacks, &render_pass) < 0) return error.VkCreateRenderPass;
        // errdefer device.dispatch.DestroyRenderPass(device.handle, render_pass, allocation_callbacks);

        var render_pass = try RenderPass.init(device, &[_]RenderPass.Attachment{.{ .format = surface_format.format, .layout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR }}, true, false, allocator, allocation_callbacks);
        errdefer render_pass.deinit();

        var depth_images = try allocator.alloc(Image, image_count);

        for (0..image_count) |i| {
            const image_create_info = std.mem.zeroInit(c.VkImageCreateInfo, c.VkImageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
                .imageType = c.VK_IMAGE_TYPE_2D,
                .extent = .{
                    .width = extent.width,
                    .height = extent.height,
                    .depth = 1,
                },
                .mipLevels = 1,
                .arrayLayers = 1,
                .format = depth_format,
                .tiling = c.VK_IMAGE_TILING_OPTIMAL,
                .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
                .usage = c.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
                .samples = c.VK_SAMPLE_COUNT_1_BIT,
                .sharingMode = c.VK_SHARING_MODE_EXCLUSIVE,
                .flags = 0,
            });

            depth_images[i] = try Image.init(device, image_create_info, allocation_callbacks);
            try depth_images[i].createMemory(c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
            try depth_images[i].createView(
                c.VK_IMAGE_VIEW_TYPE_2D,
                depth_format,
                c.VkImageSubresourceRange{
                    .aspectMask = c.VK_IMAGE_ASPECT_DEPTH_BIT,
                    .baseArrayLayer = 0,
                    .baseMipLevel = 0,
                    .layerCount = 1,
                    .levelCount = 1,
                },
            );
        }

        var frame_buffers = try allocator.alloc(c.VkFramebuffer, image_count);

        for (color_images, depth_images, 0..) |*color_image, *depth_image, i| {
            const frame_buffer_attachments = [_]c.VkImageView{ depth_image.view, color_image.view };

            const frame_buffer_create_info = std.mem.zeroInit(c.VkFramebufferCreateInfo, c.VkFramebufferCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                .renderPass = render_pass.handle,
                .attachmentCount = @intCast(frame_buffer_attachments.len),
                .pAttachments = &frame_buffer_attachments,
                .width = extent.width,
                .height = extent.height,
                .layers = 1,
            });

            if (device.dispatch.CreateFramebuffer(device.handle, &frame_buffer_create_info, null, &frame_buffers[i]) < 0) return error.VkCreateFrameBuffer;
        }

        const image_available_semaphores = try allocator.alloc(c.VkSemaphore, 2);
        const render_finished_semaphores = try allocator.alloc(c.VkSemaphore, 2);
        const in_flight_fences = try allocator.alloc(c.VkFence, 2);
        const images_in_flight = try allocator.alloc(c.VkFence, image_count);
        @memset(images_in_flight, null);

        const semaphore_create_info = std.mem.zeroInit(c.VkSemaphoreCreateInfo, c.VkSemaphoreCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        });

        const fence_create_info = std.mem.zeroInit(c.VkFenceCreateInfo, c.VkFenceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .flags = c.VK_FENCE_CREATE_SIGNALED_BIT,
        });

        for (image_available_semaphores, render_finished_semaphores, in_flight_fences) |*image_semaphore, *render_semaphore, *fence| {
            if (device.dispatch.CreateSemaphore(device.handle, &semaphore_create_info, null, image_semaphore) < 0) return error.VkCreateSemaphore;
            if (device.dispatch.CreateSemaphore(device.handle, &semaphore_create_info, null, render_semaphore) < 0) return error.VkCreateSemaphore;
            if (device.dispatch.CreateFence(device.handle, &fence_create_info, null, fence) < 0) return error.VkCreateFence;
        }

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .vulkan_library = device.physical_device.instance.vulkan_library,
            .device = device,
            .color_images = color_images,
            .depth_images = depth_images,
            .render_pass = render_pass,
            .frame_buffers = frame_buffers,
            .image_available_semaphores = image_available_semaphores,
            .render_finished_semaphores = render_finished_semaphores,
            .in_flight_fences = in_flight_fences,
            .images_in_flight = images_in_flight,
            .current_frame = 0,
            .allocator = allocator,
            .extent = window_extent,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.images_in_flight);

        for (self.color_images) |*color_image| {
            color_image.deinit();
        }
        self.allocator.free(self.color_images);

        self.device.dispatch.DestroySwapchainKHR(self.device.handle, self.handle, self.allocation_callbacks);

        for (self.depth_images) |*depth_image| {
            depth_image.deinit();
        }
        self.allocator.free(self.depth_images);

        for (self.frame_buffers) |frame_buffer| {
            self.device.dispatch.DestroyFramebuffer(self.device.handle, frame_buffer, self.allocation_callbacks);
        }
        self.allocator.free(self.frame_buffers);

        self.render_pass.deinit();

        for (self.image_available_semaphores, self.render_finished_semaphores, self.in_flight_fences) |image_semaphore, render_semaphore, fence| {
            self.device.dispatch.DestroySemaphore(self.device.handle, image_semaphore, self.allocation_callbacks);
            self.device.dispatch.DestroySemaphore(self.device.handle, render_semaphore, self.allocation_callbacks);
            self.device.dispatch.DestroyFence(self.device.handle, fence, self.allocation_callbacks);
        }
        self.allocator.free(self.image_available_semaphores);
        self.allocator.free(self.render_finished_semaphores);
        self.allocator.free(self.in_flight_fences);
    }

    pub fn acquireNextImage(self: *@This()) !u32 {
        _ = self.device.dispatch.WaitForFences(self.device.handle, 1, &self.in_flight_fences[self.current_frame], c.VK_TRUE, std.math.maxInt(u64));

        var result: u32 = undefined;
        if (self.device.dispatch.AcquireNextImageKHR(self.device.handle, self.handle, std.math.maxInt(u64), self.image_available_semaphores[self.current_frame], @ptrCast(c.VK_NULL_HANDLE), &result) < 0) return error.VkAcquireNextImage;

        return result;
    }

    pub fn submitCommandBuffers(self: *@This(), buffer: *CommandBuffer, image_index: u32) !void {
        if (self.images_in_flight[image_index]) |fence| _ = self.device.dispatch.WaitForFences(self.device.handle, 1, &fence, c.VK_TRUE, std.math.maxInt(u64));
        self.images_in_flight[image_index] = self.in_flight_fences[self.current_frame];

        const wait_semaphore = self.image_available_semaphores[self.current_frame];
        const wait_stage = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        const signal_semaphore = self.render_finished_semaphores[self.current_frame];

        const submit_info = std.mem.zeroInit(c.VkSubmitInfo, c.VkSubmitInfo{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &wait_semaphore,
            .pWaitDstStageMask = @ptrCast(&wait_stage),
            .commandBufferCount = 1,
            .pCommandBuffers = &buffer.handle,
            .signalSemaphoreCount = 1,
            .pSignalSemaphores = &signal_semaphore,
        });

        _ = self.device.dispatch.ResetFences(self.device.handle, 1, &self.in_flight_fences[self.current_frame]);
        _ = self.device.dispatch.QueueSubmit(self.device.graphics_queue, 1, &submit_info, self.in_flight_fences[self.current_frame]);

        const present_info = std.mem.zeroInit(c.VkPresentInfoKHR, c.VkPresentInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = 1,
            .pWaitSemaphores = &signal_semaphore,
            .swapchainCount = 1,
            .pSwapchains = &self.handle,
            .pImageIndices = &image_index,
        });

        if (self.device.dispatch.QueuePresentKHR(self.device.present_queue, &present_info) < 0) return error.VkQueuePresent;

        self.current_frame = (self.current_frame + 1) % 2;
    }

    pub fn beginRenderPass(self: *@This(), command_buffer: *CommandBuffer, image_index: u32, clear_color: ClearColor) void {
        const clear_values = [_]c.VkClearValue{
            c.VkClearValue{
                .depthStencil = c.VkClearDepthStencilValue{ .depth = 1.0, .stencil = 0 },
            },
            c.VkClearValue{
                .color = c.VkClearColorValue{ .float32 = .{ clear_color.r, clear_color.g, clear_color.b, clear_color.a } },
            },
        };

        const begin_info = std.mem.zeroInit(c.VkRenderPassBeginInfo, c.VkRenderPassBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
            .renderPass = self.render_pass.handle,
            .framebuffer = self.frame_buffers[image_index],
            .renderArea = c.VkRect2D{
                .offset = c.VkOffset2D{ .x = 0, .y = 0 },
                .extent = .{ .width = self.extent.x, .height = self.extent.y },
            },
            .clearValueCount = @intCast(clear_values.len),
            .pClearValues = &clear_values,
        });

        self.device.dispatch.CmdBeginRenderPass(command_buffer.handle, &begin_info, c.VK_SUBPASS_CONTENTS_INLINE);
    }

    pub fn endRenderPass(self: *@This(), command_buffer: *CommandBuffer) void {
        self.device.dispatch.CmdEndRenderPass(command_buffer.handle);
    }
};

pub const CommandPool = struct {
    handle: c.VkCommandPool,
    allocation_callbacks: AllocationCallbacks,
    device: *const LogicalDevice,

    pub fn init(device: *const LogicalDevice, queue_family_index: u32, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkCommandPoolCreateInfo, c.VkCommandPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .queueFamilyIndex = queue_family_index,
            .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        });

        var handle: c.VkCommandPool = undefined;
        if (device.dispatch.CreateCommandPool(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateCommandPool;

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .device = device,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyCommandPool(self.device.handle, self.handle, self.allocation_callbacks);
    }

    pub fn allocate(self: *@This(), count: u32, allocator: std.mem.Allocator) ![]CommandBuffer {
        const allocate_info = std.mem.zeroInit(c.VkCommandBufferAllocateInfo, c.VkCommandBufferAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .commandBufferCount = count,
            .commandPool = self.handle,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        });

        const handles = try allocator.alloc(c.VkCommandBuffer, count);
        defer allocator.free(handles);

        if (self.device.dispatch.AllocateCommandBuffers(self.device.handle, &allocate_info, handles.ptr) < 0) return error.VkAllocateCommandBuffers;

        const results = try allocator.alloc(CommandBuffer, count);

        for (handles, results) |handle, *result| {
            result.* = CommandBuffer{ .handle = handle, .device = self.device };
        }

        return results;
    }

    pub fn beginSingleTimeCommands(self: *@This()) !CommandBuffer {
        const alloc_info = std.mem.zeroInit(c.VkCommandBufferAllocateInfo, c.VkCommandBufferAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
            .commandPool = self.handle,
            .commandBufferCount = 1,
        });

        var command_buffer: c.VkCommandBuffer = undefined;
        if (self.device.dispatch.AllocateCommandBuffers(self.device.handle, &alloc_info, &command_buffer) < 0) return error.VkAllocateCommandBuffer;

        const begin_info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = c.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
        });

        if (self.device.dispatch.BeginCommandBuffer(command_buffer, &begin_info) < 0) return error.VkBeginCommandBuffer;

        return .{
            .handle = command_buffer,
            .device = self.device,
        };
    }

    pub fn endSingleTimeCommands(self: *@This(), command_buffer: *CommandBuffer) !void {
        try command_buffer.end();

        const submit_info = std.mem.zeroInit(c.VkSubmitInfo, c.VkSubmitInfo{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .commandBufferCount = 1,
            .pCommandBuffers = &command_buffer.handle,
        });

        _ = self.device.dispatch.QueueSubmit(self.device.graphics_queue, 1, &submit_info, @ptrCast(c.VK_NULL_HANDLE));
        _ = self.device.dispatch.QueueWaitIdle(self.device.graphics_queue);

        self.device.dispatch.FreeCommandBuffers(self.device.handle, self.handle, 1, &command_buffer.handle);
    }
};

pub const CommandBuffer = struct {
    handle: c.VkCommandBuffer,
    device: *const LogicalDevice,

    pub fn begin(self: *@This()) !void {
        const begin_info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        });

        if (self.device.dispatch.BeginCommandBuffer(self.handle, &begin_info) < 0) return error.VkBeginCommandBuffer;
    }

    pub fn end(self: *@This()) !void {
        if (self.device.dispatch.EndCommandBuffer(self.handle) < 0) return error.VkEndCommandBuffer;
    }

    pub fn pushConstants(self: *@This(), pipeline_layout: c.VkPipelineLayout, shader_stage: c.VkShaderStageFlags, push_constant_data: anytype) void {
        self.device.dispatch.CmdPushConstants(self.handle, pipeline_layout, shader_stage, 0, @sizeOf(@TypeOf(push_constant_data.*)), push_constant_data);
    }

    pub fn copyBuffer(self: *@This(), src_buffer: *Buffer, dst_buffer: *Buffer, size: u64) void {
        const copy_region = std.mem.zeroInit(c.VkBufferCopy, c.VkBufferCopy{ .size = size });
        self.device.dispatch.CmdCopyBuffer(self.handle, src_buffer.handle, dst_buffer.handle, 1, &copy_region);
    }
};

pub const DescriptorPool = struct {
    handle: c.VkDescriptorPool,
    device: *const LogicalDevice,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, sizes: []c.VkDescriptorPoolSize, max_sets: u32, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkDescriptorPoolCreateInfo, c.VkDescriptorPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
            .poolSizeCount = @intCast(sizes.len),
            .pPoolSizes = sizes.ptr,
            .maxSets = max_sets,
        });

        var handle: c.VkDescriptorPool = undefined;
        if (device.dispatch.CreateDescriptorPool(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateDescriptorPool;

        return .{
            .handle = handle,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyDescriptorPool(self.device.handle, self.handle, self.allocation_callbacks);
    }

    pub fn allocate(self: *@This(), pipeline: *Pipeline, count: u32, allocator: std.mem.Allocator) ![]c.VkDescriptorSet {
        const layouts = try allocator.alloc(c.VkDescriptorSetLayout, count);
        defer allocator.free(layouts);
        @memset(layouts, pipeline.descriptor_layout);

        const allocate_info = std.mem.zeroInit(c.VkDescriptorSetAllocateInfo, c.VkDescriptorSetAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
            .descriptorPool = self.handle,
            .descriptorSetCount = count,
            .pSetLayouts = layouts.ptr,
        });

        const handles = try allocator.alloc(c.VkDescriptorSet, count);
        errdefer allocator.free(handles);
        if (self.device.dispatch.AllocateDescriptorSets(self.device.handle, &allocate_info, handles.ptr) < 0) return error.VkAllocateDescriptorSet;

        return handles;
    }
};

pub const ShaderModule = struct {
    handle: c.VkShaderModule,
    device: *const LogicalDevice,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, shader_code: []const u8, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkShaderModuleCreateInfo, c.VkShaderModuleCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
            .codeSize = shader_code.len,
            .pCode = @ptrCast(@alignCast(shader_code.ptr)),
        });

        var handle: c.VkShaderModule = undefined;
        if (device.dispatch.CreateShaderModule(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateShaderModule;

        return .{
            .handle = handle,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyShaderModule(self.device.handle, self.handle, self.allocation_callbacks);
    }
};

pub const Pipeline = struct {
    handle: c.VkPipeline,
    device: *const LogicalDevice,
    frag_shader: *const ShaderModule,
    vert_shader: *const ShaderModule,
    layout: c.VkPipelineLayout,
    descriptor_layout: c.VkDescriptorSetLayout,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, PushConstantData: type, layout_bindings: []c.VkDescriptorSetLayoutBinding, render_pass: c.VkRenderPass, color_attachments: []c.VkPipelineColorBlendAttachmentState, primitive_topology: c.VkPrimitiveTopology, polygon_mode: c.VkPolygonMode, frag_shader: *const ShaderModule, vert_shader: *const ShaderModule, extent: Extent2D, attribute_descriptions: []c.VkVertexInputAttributeDescription, binding_descriptions: []c.VkVertexInputBindingDescription, allocation_callbacks: AllocationCallbacks) !@This() {
        const descriptor_layout_create_info = std.mem.zeroInit(c.VkDescriptorSetLayoutCreateInfo, c.VkDescriptorSetLayoutCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
            .bindingCount = @intCast(layout_bindings.len),
            .pBindings = layout_bindings.ptr,
        });

        var descriptor_layout: c.VkDescriptorSetLayout = undefined;
        if (device.dispatch.CreateDescriptorSetLayout(device.handle, &descriptor_layout_create_info, allocation_callbacks, &descriptor_layout) < 0) return error.VkCreateDescriptorSetLayout;
        errdefer device.dispatch.DestroyDescriptorSetLayout(device.handle, descriptor_layout, allocation_callbacks);

        const push_constant_range = std.mem.zeroInit(c.VkPushConstantRange, c.VkPushConstantRange{
            .stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT,
            .offset = 0,
            .size = @sizeOf(PushConstantData),
        });

        const layout_create_info = std.mem.zeroInit(c.VkPipelineLayoutCreateInfo, c.VkPipelineLayoutCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
            .pushConstantRangeCount = 1,
            .pPushConstantRanges = &push_constant_range,
            .pSetLayouts = &descriptor_layout,
            .setLayoutCount = 1,
        });

        var layout: c.VkPipelineLayout = undefined;
        if (device.dispatch.CreatePipelineLayout(device.handle, &layout_create_info, allocation_callbacks, &layout) < 0) return error.VkCreatePipelineLayout;
        errdefer device.dispatch.DestroyPipelineLayout(device.handle, layout, allocation_callbacks);

        const input_assembly_info = std.mem.zeroInit(c.VkPipelineInputAssemblyStateCreateInfo, c.VkPipelineInputAssemblyStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
            .topology = primitive_topology,
            .primitiveRestartEnable = c.VK_FALSE,
        });

        const viewport = std.mem.zeroInit(c.VkViewport, c.VkViewport{
            .x = 0.0,
            .y = 0.0,
            .width = @floatFromInt(extent.x),
            .height = @floatFromInt(extent.y),
            .minDepth = 0.0,
            .maxDepth = 1.0,
        });

        const scissor = std.mem.zeroInit(c.VkRect2D, c.VkRect2D{
            .offset = std.mem.zeroes(c.VkOffset2D),
            .extent = .{ .width = extent.x, .height = extent.y },
        });

        const viewport_info = std.mem.zeroInit(c.VkPipelineViewportStateCreateInfo, c.VkPipelineViewportStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
            .viewportCount = 1,
            .pViewports = &viewport,
            .scissorCount = 1,
            .pScissors = &scissor,
        });

        const rasterization_info = std.mem.zeroInit(c.VkPipelineRasterizationStateCreateInfo, c.VkPipelineRasterizationStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
            .depthClampEnable = c.VK_FALSE,
            .rasterizerDiscardEnable = c.VK_FALSE,
            .polygonMode = polygon_mode,
            .lineWidth = 1.0,
            .cullMode = c.VK_CULL_MODE_NONE,
            .frontFace = c.VK_FRONT_FACE_CLOCKWISE,
            .depthBiasEnable = c.VK_FALSE,
        });

        const multisample_info = std.mem.zeroInit(c.VkPipelineMultisampleStateCreateInfo, c.VkPipelineMultisampleStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
            .sampleShadingEnable = c.VK_FALSE,
            .rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT,
        });

        const color_blend_info = std.mem.zeroInit(c.VkPipelineColorBlendStateCreateInfo, c.VkPipelineColorBlendStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
            .logicOpEnable = c.VK_FALSE,
            .attachmentCount = @intCast(color_attachments.len),
            .pAttachments = color_attachments.ptr,
        });

        const depth_stencil_info = std.mem.zeroInit(c.VkPipelineDepthStencilStateCreateInfo, c.VkPipelineDepthStencilStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
            .depthTestEnable = c.VK_TRUE,
            .depthWriteEnable = c.VK_TRUE,
            .depthCompareOp = c.VK_COMPARE_OP_LESS,
            .depthBoundsTestEnable = c.VK_FALSE,
        });

        const shader_stages = [_]c.VkPipelineShaderStageCreateInfo{
            std.mem.zeroInit(c.VkPipelineShaderStageCreateInfo, c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .stage = c.VK_SHADER_STAGE_VERTEX_BIT,
                .module = vert_shader.handle,
                .pName = "main",
            }),
            std.mem.zeroInit(c.VkPipelineShaderStageCreateInfo, c.VkPipelineShaderStageCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                .stage = c.VK_SHADER_STAGE_FRAGMENT_BIT,
                .module = frag_shader.handle,
                .pName = "main",
            }),
        };

        const vertex_input_info = std.mem.zeroInit(c.VkPipelineVertexInputStateCreateInfo, c.VkPipelineVertexInputStateCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
            .vertexAttributeDescriptionCount = @intCast(attribute_descriptions.len),
            .pVertexAttributeDescriptions = attribute_descriptions.ptr,
            .vertexBindingDescriptionCount = @intCast(binding_descriptions.len),
            .pVertexBindingDescriptions = binding_descriptions.ptr,
        });

        const create_info = std.mem.zeroInit(c.VkGraphicsPipelineCreateInfo, c.VkGraphicsPipelineCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &shader_stages,
            .pVertexInputState = &vertex_input_info,
            .pInputAssemblyState = &input_assembly_info,
            .pViewportState = &viewport_info,
            .pRasterizationState = &rasterization_info,
            .pColorBlendState = &color_blend_info,
            .pDepthStencilState = &depth_stencil_info,
            .pDynamicState = null,
            .layout = layout,
            .renderPass = render_pass,
            .subpass = 0,
            .basePipelineIndex = -1,
            .basePipelineHandle = @ptrCast(c.VK_NULL_HANDLE),
            .pMultisampleState = &multisample_info,
        });

        var handle: c.VkPipeline = undefined;
        if (device.dispatch.CreateGraphicsPipelines(device.handle, @ptrCast(c.VK_NULL_HANDLE), 1, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateGraphicsPipelines;

        return .{
            .handle = handle,
            .device = device,
            .frag_shader = frag_shader,
            .vert_shader = vert_shader,
            .layout = layout,
            .descriptor_layout = descriptor_layout,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyPipeline(self.device.handle, self.handle, self.allocation_callbacks);
        self.device.dispatch.DestroyDescriptorSetLayout(self.device.handle, self.descriptor_layout, self.allocation_callbacks);
        self.device.dispatch.DestroyPipelineLayout(self.device.handle, self.layout, self.allocation_callbacks);
    }

    pub fn bind(self: *@This(), command_buffer: *CommandBuffer) void {
        self.device.dispatch.CmdBindPipeline(command_buffer.handle, c.VK_PIPELINE_BIND_POINT_GRAPHICS, self.handle);
    }
};

pub const Sampler = struct {
    handle: c.VkSampler,
    device: *const LogicalDevice,
    allocation_callbacks: AllocationCallbacks,

    pub fn init(device: *const LogicalDevice, allocation_callbacks: AllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkSamplerCreateInfo, c.VkSamplerCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
            .addressModeU = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
            .addressModeV = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
            .addressModeW = c.VK_SAMPLER_ADDRESS_MODE_REPEAT,
            .magFilter = c.VK_FILTER_LINEAR,
            .minFilter = c.VK_FILTER_LINEAR,
            .anisotropyEnable = c.VK_TRUE,
            .maxAnisotropy = device.physical_device.properties.limits.maxSamplerAnisotropy,
            .borderColor = c.VK_BORDER_COLOR_INT_OPAQUE_BLACK,
            .unnormalizedCoordinates = c.VK_FALSE,
            .compareEnable = c.VK_FALSE,
            .compareOp = c.VK_COMPARE_OP_ALWAYS,
            .mipmapMode = c.VK_SAMPLER_MIPMAP_MODE_LINEAR,
            .mipLodBias = 0.0,
            .minLod = 0.0,
            .maxLod = 0.0,
        });

        var handle: c.VkSampler = undefined;
        if (device.dispatch.CreateSampler(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateSampler;

        return .{
            .handle = handle,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroySampler(self.device.handle, self.handle, self.allocation_callbacks);
    }
};
