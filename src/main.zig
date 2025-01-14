const std = @import("std");
const GameRandom = @import("game_random.zig");
const PlanetGenerator = @import("planet_generator.zig");
const c = @cImport({
    @cDefine("VK_NO_PROTOTYPES", {});
    @cInclude("vulkan/vulkan.h");
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_vulkan.h");
});

pub const VulkanLibrary = struct {
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

pub const VulkanWindow = struct {
    handle: ?*c.SDL_Window,

    pub fn init(title: [*c]const u8) !@This() {
        const handle = c.SDL_CreateWindow(title, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 800, 600, c.SDL_WINDOW_VULKAN | c.SDL_WINDOW_HIDDEN | c.SDL_WINDOW_RESIZABLE);
        if (handle == null) {
            c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
            return error.SDLCreateWindow;
        }

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

    pub fn getExtent(self: *const @This()) c.VkExtent2D {
        var width: u32 = 800;
        var height: u32 = 600;
        c.SDL_Vulkan_GetDrawableSize(self.handle, @ptrCast(&width), @ptrCast(&height));

        return c.VkExtent2D{ .width = width, .height = height };
    }
};

pub const VulkanInstance = struct {
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
    };

    handle: c.VkInstance,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    vulkan_library: *VulkanLibrary,
    dispatch: Dispatch,

    pub fn init(extensions: [][*c]const u8, vulkan_library: *VulkanLibrary, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
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

    pub fn requestPhysicalDevice(self: *const @This(), allocator: std.mem.Allocator, maybe_surface: ?*VulkanSurface) !VulkanPhysicalDevice {
        const physical_devices = try self.enumeratePhysicalDevices(allocator);
        defer allocator.free(physical_devices);

        for (physical_devices) |physical_device| {
            const queue_families_properties = try self.getPhysicalDeviceQueueFamilyProperties(physical_device, allocator);
            defer allocator.free(queue_families_properties);

            for (queue_families_properties, 0..) |queue_family_properties, index| {
                var is_surface_supported = true;
                if (maybe_surface) |surface| is_surface_supported = try surface.getPhysicalDeviceSupport(physical_device, @intCast(index));

                if (((queue_family_properties.queueFlags & c.VK_QUEUE_GRAPHICS_BIT) != 0) and is_surface_supported) {
                    return VulkanPhysicalDevice.init(physical_device, self, @intCast(index));
                }
            }
        }

        return error.NoCompatiblePhysicalDevices;
    }
};

pub const VulkanSurface = struct {
    handle: c.VkSurfaceKHR,
    instance: *VulkanInstance,

    pub fn init(instance: *VulkanInstance, window: *VulkanWindow) !@This() {
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

const VulkanPhysicalDevice = struct {
    instance: *const VulkanInstance,
    handle: c.VkPhysicalDevice,
    queue_family_index: u32,

    pub fn init(handle: c.VkPhysicalDevice, instance: *const VulkanInstance, queue_family_index: u32) !@This() {
        return .{
            .instance = instance,
            .handle = handle,
            .queue_family_index = queue_family_index,
        };
    }

    pub fn createLogicalDevice(self: *const @This(), allocation_callbacks: ?*c.VkAllocationCallbacks) !VulkanLogicalDevice {
        return VulkanLogicalDevice.init(self, allocation_callbacks);
    }

    pub fn getProperties(self: *const @This()) c.VkPhysicalDeviceProperties {
        var result: c.VkPhysicalDeviceProperties = undefined;
        self.instance.dispatch.GetPhysicalDeviceProperties(self.handle, &result);

        return result;
    }
};

const VulkanLogicalDevice = struct {
    const Dispatch = struct {
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
    };

    handle: c.VkDevice,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    physical_device: *const VulkanPhysicalDevice,
    queue: c.VkQueue,
    dispatch: Dispatch,

    pub fn init(physical_device: *const VulkanPhysicalDevice, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        const queue_priorities = [_]f32{1.0};

        const queue_create_infos = [_]c.VkDeviceQueueCreateInfo{
            std.mem.zeroInit(c.VkDeviceQueueCreateInfo, c.VkDeviceQueueCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .queueFamilyIndex = physical_device.queue_family_index,
                .queueCount = @as(u32, queue_priorities.len),
                .pQueuePriorities = &queue_priorities,
            }),
        };

        const extensions = [_][*c]const u8{
            c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
        };

        const create_info = std.mem.zeroInit(c.VkDeviceCreateInfo, c.VkDeviceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .queueCreateInfoCount = @as(u32, queue_create_infos.len),
            .pQueueCreateInfos = &queue_create_infos,
            .enabledExtensionCount = @as(u32, extensions.len),
            .ppEnabledExtensionNames = &extensions,
        });

        var handle: c.VkDevice = undefined;
        if (physical_device.instance.dispatch.CreateDevice(physical_device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateDevice;

        const dispatch = try physical_device.instance.load(Dispatch, handle);

        var queue: c.VkQueue = undefined;
        dispatch.GetDeviceQueue(handle, physical_device.queue_family_index, 0, &queue);

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .physical_device = physical_device,
            .queue = queue,
            .dispatch = dispatch,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.dispatch.DestroyDevice(self.handle, self.allocation_callbacks);
    }

    pub fn createSwapchain(self: *const @This(), surface: *VulkanSurface, image_extent: c.VkExtent2D, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !VulkanSwapchain {
        return VulkanSwapchain.init(surface, self, image_extent, allocator, allocation_callbacks);
    }

    pub fn createImageView(self: *const @This(), create_info: c.VkImageViewCreateInfo, allocation_callbacks: ?*c.VkAllocationCallbacks) !c.VkImageView {
        var handle: c.VkImageView = undefined;
        if (self.dispatch.CreateImageView(self.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateImageView;

        return handle;
    }

    pub fn createFences(self: *const @This(), allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !VulkanFences {
        return VulkanFences.init(self, allocator, allocation_callbacks);
    }

    pub fn createSemaphores(self: *const @This(), allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !VulkanSemaphores {
        return VulkanSemaphores.init(self, allocator, allocation_callbacks);
    }

    pub fn waitIdle(self: *const @This()) !void {
        if (self.dispatch.DeviceWaitIdle(self.handle) < 0) return error.VkDeviceWaitIdle;
    }

    pub fn createCommandPool(self: *const @This(), allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !VulkanCommandPool {
        return VulkanCommandPool.init(self, allocator, allocation_callbacks);
    }

    pub fn queueSubmit(self: *@This(), command_buffers: []VulkanCommandBuffer, fence: c.VkFence, semaphores: *VulkanSemaphores) !void {
        const flag: u32 = @intCast(c.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);

        const submit_info = std.mem.zeroInit(c.VkSubmitInfo, c.VkSubmitInfo{
            .sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .commandBufferCount = @intCast(command_buffers.len),
            .pCommandBuffers = @ptrCast(command_buffers.ptr),
            .waitSemaphoreCount = @intCast(semaphores.handles.items.len),
            .pWaitSemaphores = semaphores.handles.items.ptr,
            .pWaitDstStageMask = &flag,
        });

        if (self.dispatch.QueueSubmit(self.queue, 1, &submit_info, fence) < 0) return error.VkQueueSubmit;
    }
};

const VulkanSwapchain = struct {
    handle: c.VkSwapchainKHR,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    vulkan_library: *VulkanLibrary,
    device: *const VulkanLogicalDevice,
    images: []c.VkImage,
    views: []c.VkImageView,
    allocator: std.mem.Allocator,

    pub fn init(surface: *VulkanSurface, device: *const VulkanLogicalDevice, ideal_image_extent: c.VkExtent2D, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        var surface_capabilities: c.VkSurfaceCapabilitiesKHR = .{};
        if (surface.instance.dispatch.GetPhysicalDeviceSurfaceCapabilitiesKHR(device.physical_device.handle, surface.handle, &surface_capabilities) < 0) return error.VkGetPhysicalDeviceSurfaceCapabilities;

        const image_extent = if (surface_capabilities.currentExtent.width == std.math.maxInt(u32)) ideal_image_extent else surface_capabilities.currentExtent;

        const queue_family_indices = [_]u32{device.physical_device.queue_family_index};

        const create_info = std.mem.zeroInit(c.VkSwapchainCreateInfoKHR, c.VkSwapchainCreateInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
            .surface = surface.handle,
            .presentMode = c.VK_PRESENT_MODE_FIFO_KHR,
            .preTransform = surface_capabilities.currentTransform,
            .imageFormat = c.VK_FORMAT_B8G8R8A8_SRGB,
            .imageColorSpace = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
            .clipped = c.VK_TRUE,
            .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
            .queueFamilyIndexCount = @as(u32, queue_family_indices.len),
            .pQueueFamilyIndices = &queue_family_indices,
            .imageSharingMode = if (queue_family_indices.len == 1) c.VK_SHARING_MODE_EXCLUSIVE else c.VK_SHARING_MODE_CONCURRENT,
            .imageArrayLayers = 1,
            .imageExtent = image_extent,
            .minImageCount = if (surface_capabilities.maxImageCount == 0) surface_capabilities.minImageCount + 1 else @min(surface_capabilities.minImageCount + 1, surface_capabilities.maxImageCount),
        });

        var handle: c.VkSwapchainKHR = undefined;
        if (device.dispatch.CreateSwapchainKHR(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateSwapchain;
        errdefer device.dispatch.DestroySwapchainKHR(device.handle, handle, allocation_callbacks);

        var image_count: u32 = undefined;
        if (device.dispatch.GetSwapchainImagesKHR(device.handle, handle, &image_count, null) < 0) return error.VkGetSwapchainImageCount;

        const images = try allocator.alloc(c.VkImage, image_count);
        errdefer allocator.free(images);

        if (device.dispatch.GetSwapchainImagesKHR(device.handle, handle, &image_count, images.ptr) < 0) return error.VkGetSwapchainImages;

        const views = try allocator.alloc(c.VkImageView, image_count);
        errdefer allocator.free(views);

        for (images, views) |image, *view| {
            view.* = try device.createImageView(std.mem.zeroInit(c.VkImageViewCreateInfo, c.VkImageViewCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
                .image = image,
                .viewType = c.VK_IMAGE_VIEW_TYPE_2D,
                .format = create_info.imageFormat,
                .subresourceRange = c.VkImageSubresourceRange{
                    .aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT,
                    .baseArrayLayer = 0,
                    .baseMipLevel = 0,
                    .layerCount = 1,
                    .levelCount = 1,
                },
            }), null);
        }

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .vulkan_library = device.physical_device.instance.vulkan_library,
            .device = device,
            .images = images,
            .views = views,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroySwapchainKHR(self.device.handle, self.handle, self.allocation_callbacks);
        self.allocator.free(self.images);
        for (self.views) |view| {
            self.device.dispatch.DestroyImageView(self.device.handle, view, self.allocation_callbacks);
        }
        self.allocator.free(self.views);
    }

    pub fn acquireNextImage(self: *@This(), timeout_nanoseconds: ?u64, semaphore: c.VkSemaphore, fence: c.VkFence) !u32 {
        var result: u32 = undefined;
        if (self.device.dispatch.AcquireNextImageKHR(self.device.handle, self.handle, timeout_nanoseconds orelse std.math.maxInt(u64), semaphore, fence, &result) < 0) return error.VkAcquireNextImage;

        return result;
    }

    pub fn present(self: *@This(), semaphores: *VulkanSemaphores, fences: *VulkanFences, index: u32) !void {
        _ = fences;

        const present_info = std.mem.zeroInit(c.VkPresentInfoKHR, c.VkPresentInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
            .waitSemaphoreCount = @as(u32, @intCast(semaphores.handles.items.len)),
            .pWaitSemaphores = semaphores.handles.items.ptr,
            .swapchainCount = 1,
            .pSwapchains = &self.handle,
            .pImageIndices = &index,
        });

        if (self.device.dispatch.QueuePresentKHR(self.device.queue, &present_info) < 0) return error.VkQueuePresent;
    }
};

const VulkanFences = struct {
    handles: std.ArrayList(c.VkFence),
    allocator: std.mem.Allocator,
    device: *const VulkanLogicalDevice,
    allocation_callbacks: ?*c.VkAllocationCallbacks,

    pub fn init(device: *const VulkanLogicalDevice, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        return .{
            .handles = std.ArrayList(c.VkFence).init(allocator),
            .allocator = allocator,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.handles.items) |handle| {
            self.device.dispatch.DestroyFence(self.device.handle, handle, self.allocation_callbacks);
        }
        self.handles.deinit();
    }

    pub fn addFence(self: *@This(), signaled: bool, allocation_callbacks: ?*c.VkAllocationCallbacks) !void {
        const create_info = std.mem.zeroInit(c.VkFenceCreateInfo, c.VkFenceCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .flags = if (signaled) c.VK_FENCE_CREATE_SIGNALED_BIT else 0,
        });

        var handle: c.VkFence = undefined;
        if (self.device.dispatch.CreateFence(self.device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateFence;

        try self.handles.append(handle);
    }

    pub fn wait(self: *const @This(), for_all: bool, timeout_nanoseconds: ?u64) !void {
        if (self.device.dispatch.WaitForFences(self.device.handle, @as(u32, @intCast(self.handles.items.len)), self.handles.items.ptr, @intFromBool(for_all), timeout_nanoseconds orelse std.math.maxInt(u64)) < 0) return error.VkWaitForFences;
    }

    pub fn reset(self: *@This()) !void {
        if (self.device.dispatch.ResetFences(self.device.handle, @as(u32, @intCast(self.handles.items.len)), self.handles.items.ptr) < 0) return error.VkResetFences;
    }
};

const VulkanSemaphores = struct {
    handles: std.ArrayList(c.VkSemaphore),
    allocator: std.mem.Allocator,
    device: *const VulkanLogicalDevice,
    allocation_callbacks: ?*c.VkAllocationCallbacks,

    pub fn init(device: *const VulkanLogicalDevice, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        return .{
            .handles = std.ArrayList(c.VkSemaphore).init(allocator),
            .allocator = allocator,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.handles.items) |handle| {
            self.device.dispatch.DestroySemaphore(self.device.handle, handle, self.allocation_callbacks);
        }
        self.handles.deinit();
    }

    pub fn addSemaphore(self: *@This(), allocation_callbacks: ?*c.VkAllocationCallbacks) !void {
        const create_info = std.mem.zeroInit(c.VkSemaphoreCreateInfo, c.VkSemaphoreCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        });

        var handle: c.VkSemaphore = undefined;
        if (self.device.dispatch.CreateSemaphore(self.device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateSemaphore;

        try self.handles.append(handle);
    }
};

const VulkanCommandPool = struct {
    handle: c.VkCommandPool,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    allocator: std.mem.Allocator,
    device: *const VulkanLogicalDevice,

    pub fn init(device: *const VulkanLogicalDevice, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkCommandPoolCreateInfo, c.VkCommandPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .queueFamilyIndex = device.physical_device.queue_family_index,
            .flags = 0,
        });

        var handle: c.VkCommandPool = undefined;
        if (device.dispatch.CreateCommandPool(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateCommandPool;

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .allocator = allocator,
            .device = device,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyCommandPool(self.device.handle, self.handle, self.allocation_callbacks);
    }

    pub fn allocate(self: *@This(), count: u32, allocator: std.mem.Allocator) ![]VulkanCommandBuffer {
        const allocate_info = std.mem.zeroInit(c.VkCommandBufferAllocateInfo, c.VkCommandBufferAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .commandBufferCount = count,
            .commandPool = self.handle,
            .level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        });

        const handles = try allocator.alloc(VulkanCommandBuffer, count);
        errdefer allocator.free(handles);

        if (self.device.dispatch.AllocateCommandBuffers(self.device.handle, &allocate_info, @ptrCast(handles.ptr)) < 0) return error.VkAllocateCommandBuffers;

        return handles;
    }
};

const VulkanCommandBuffer = struct {
    handle: c.VkCommandBuffer,

    pub fn begin(self: *@This(), device: *VulkanLogicalDevice) !void {
        const begin_info = std.mem.zeroInit(c.VkCommandBufferBeginInfo, c.VkCommandBufferBeginInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        });

        if (device.dispatch.BeginCommandBuffer(self.handle, &begin_info) < 0) return error.VkBeginCommandBuffer;
    }

    pub fn end(self: *@This(), device: *VulkanLogicalDevice) !void {
        if (device.dispatch.EndCommandBuffer(self.handle) < 0) return error.VkEndCommandBuffer;
    }
};

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

    var gr = GameRandom.init("theoriginalgangsterjesuschrist");

    var planet_generator = try PlanetGenerator.init(@embedFile("planet_generator.json"), allocator, &gr);
    defer planet_generator.deinit();

    var planet = try planet_generator.generatePlanet();
    defer planet_generator.freePlanet(&planet);

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_LogError(c.SDL_LOG_CATEGORY_APPLICATION, "%s", c.SDL_GetError());
        return error.SDLInitVideo;
    }
    defer c.SDL_Quit();

    var vulkan_library = try VulkanLibrary.init();
    defer vulkan_library.deinit();

    var window = try VulkanWindow.init("the unqeustionable");
    defer window.deinit();

    const extensions = try window.getRequiredExtensions(allocator);
    defer allocator.free(extensions);

    var instance = try VulkanInstance.init(extensions, &vulkan_library, null);
    defer instance.deinit();

    var surface = try VulkanSurface.init(&instance, &window);
    defer surface.deinit();

    const physical_device = try instance.requestPhysicalDevice(allocator, &surface);

    var logical_device = try physical_device.createLogicalDevice(null);
    defer logical_device.deinit();

    var swapchain = try logical_device.createSwapchain(&surface, window.getExtent(), allocator, null);
    defer swapchain.deinit();

    var fences = try logical_device.createFences(allocator, null);
    defer fences.deinit();
    try fences.addFence(false, null);

    var semaphores = try logical_device.createSemaphores(allocator, null);
    defer semaphores.deinit();
    try semaphores.addSemaphore(null);

    var command_pool = try logical_device.createCommandPool(allocator, null);
    defer command_pool.deinit();

    const command_buffers = try command_pool.allocate(1, allocator);
    defer allocator.free(command_buffers);

    std.debug.print("{d}\n{s}\n", .{
        @intFromPtr(swapchain.handle),
        physical_device.getProperties().deviceName,
    });

    window.show();

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
                else => {},
            }
        }

        const image_index = try swapchain.acquireNextImage(null, semaphores.handles.items[0], fences.handles.items[0]);
        const image = swapchain.images[image_index];
        _ = image;

        var command_buffer = command_buffers[0];

        try command_buffer.begin(&logical_device);
        try command_buffer.end(&logical_device);

        std.debug.print("doesit work 2", .{});

        try logical_device.queueSubmit(command_buffers, fences.handles.items[0], &semaphores);

        std.debug.print("doesit work 3", .{});

        try swapchain.present(&semaphores, &fences, image_index);

        std.debug.print("doesit work 4", .{});

        try fences.wait(false, null);

        std.debug.print("doesit work 5", .{});

        try fences.reset();

        std.debug.print("doesit work 6", .{});

        //std.debug.print("cheese", .{});
    }
}
