const std = @import("std");
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
        GetPhysicalDeviceFormatProperties: std.meta.Child(c.PFN_vkGetPhysicalDeviceFormatProperties) = undefined,
        GetPhysicalDeviceSurfaceFormatsKHR: std.meta.Child(c.PFN_vkGetPhysicalDeviceSurfaceFormatsKHR) = undefined,
        GetPhysicalDeviceSurfacePresentModesKHR: std.meta.Child(c.PFN_vkGetPhysicalDeviceSurfacePresentModesKHR) = undefined,
        GetPhysicalDeviceMemoryProperties: std.meta.Child(c.PFN_vkGetPhysicalDeviceMemoryProperties) = undefined,
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

pub const VulkanPhysicalDevice = struct {
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

    pub fn getSwapchainSupport(self: *const @This(), surface: *const VulkanSurface, allocator: std.mem.Allocator) !SwapChainSupportDetails {
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
            if ((filter & (1 << i)) and (mem_properties.memoryTypes[i].propertyFlags & properties) == properties) return i;
        }

        return error.NoSuitableMemoryType;
    }
};

pub const VulkanLogicalDevice = struct {
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

    pub fn waitIdle(self: *const @This()) !void {
        if (self.dispatch.DeviceWaitIdle(self.handle) < 0) return error.VkDeviceWaitIdle;
    }

    pub fn createCommandPool(self: *const @This(), allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !VulkanCommandPool {
        return VulkanCommandPool.init(self, allocator, allocation_callbacks);
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

    pub fn allocateMemory(self: *const @This(), properties: c.VkMemoryPropertyFlags, requirements: c.VkMemoryRequirements, allocation_callbacks: ?*c.VkAllocationCallbacks) !c.VkDeviceMemory {
        const allocate_info = std.mem.zeroInit(c.VkMemoryAllocateInfo, c.VkMemoryAllocateInfo{
            .sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .allocationSize = requirements.size,
            .memoryTypeIndex = self.physical_device.findMemoryType(requirements.memoryTypeBits, properties),
        });

        var handle: c.VkDeviceMemory = undefined;
        if (self.dispatch.AllocateMemory(self.handle, &allocate_info, allocation_callbacks, &handle) < 0) return error.VkAllocateMemory;

        return handle;
    }

    pub fn freeMemory(self: *const @This(), memory: c.VkDeviceMemory, allocation_callbacks: ?*c.VkAllocationCallbacks) void {
        self.dispatch.FreeMemory(self.handle, memory, allocation_callbacks);
    }
};

pub const VulkanImage = struct {
    handle: c.VkImage,
    view: ?c.VkImageView,
    memory: ?c.VkDeviceMemory,
    device: *const VulkanLogicalDevice,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    should_destroy_image: bool,

    pub fn init(device: *const VulkanLogicalDevice, create_info: *c.VkImageCreateInfo, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        var handle: c.VkImage = undefined;
        if (device.dispatch.CreateImage(device.handle, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateImage;

        return .{
            .handle = handle,
            .view = null,
            .memory = null,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
            .should_destroy_image = true,
        };
    }

    pub fn fromHandle(device: *const VulkanLogicalDevice, handle: c.VkImage, allocation_callbacks: ?*c.VkAllocationCallbacks) @This() {
        return .{
            .handle = handle,
            .view = null,
            .memory = null,
            .device = device,
            .allocation_callbacks = allocation_callbacks,
            .should_destroy_image = false,
        };
    }

    pub fn deinit(self: *@This()) void {
        if (self.should_destroy_image) self.device.dispatch.DestroyImage(self.device.handle, self.handle, self.allocation_callbacks);
        if (self.view) |view| self.device.dispatch.DestroyImageView(self.device.handle, view, self.allocation_callbacks);
        if (self.memory) |memory| self.device.freeMemory(memory, self.allocation_callbacks);
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
        var requirements: c.VkMemoryRequirements = undefined;
        self.device.dispatch.GetImageMemoryRequirements(self.device.handle, self.handle, &requirements);

        self.memory = try self.device.allocateMemory(properties, requirements, self.allocation_callbacks);

        if (self.device.dispatch.BindImageMemory(self.device.handle, self.handle, self.memory, 0) < 0) return error.VkBindImageMemory;
    }
};

pub const VulkanSwapchain = struct {
    handle: c.VkSwapchainKHR,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    vulkan_library: *VulkanLibrary,
    device: *const VulkanLogicalDevice,
    color_images: []VulkanImage,
    depth_images: []VulkanImage,
    render_pass: c.VkRenderPass,
    allocator: std.mem.Allocator,

    pub fn init(surface: *VulkanSurface, device: *const VulkanLogicalDevice, window_extent: c.VkExtent2D, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
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
        std.debug.print("Present mode: {s}\n", .{if (present_mode == c.VK_PRESENT_MODE_MAILBOX_KHR) "Mailbox" else "V-Sync"});

        var extent: c.VkExtent2D = undefined;
        if (swapchain_support.capabilities.currentExtent.width != std.math.maxInt(u32)) {
            extent = swapchain_support.capabilities.currentExtent;
        } else {
            var actual_extent: c.VkExtent2D = window_extent;
            actual_extent.width = @max(swapchain_support.capabilities.minImageExtent.width, @min(swapchain_support.capabilities.maxImageExtent.width, actual_extent.width));
            actual_extent.height = @max(swapchain_support.capabilities.minImageExtent.height, @min(swapchain_support.capabilities.maxImageExtent.height, actual_extent.height));

            extent = actual_extent;
        }

        const queue_family_indices = [_]u32{device.physical_device.queue_family_index};

        const create_info = std.mem.zeroInit(c.VkSwapchainCreateInfoKHR, c.VkSwapchainCreateInfoKHR{
            .sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
            .surface = surface.handle,
            .presentMode = c.VK_PRESENT_MODE_FIFO_KHR,
            .preTransform = swapchain_support.capabilities.currentTransform,
            .imageFormat = c.VK_FORMAT_B8G8R8A8_SRGB,
            .imageColorSpace = c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
            .clipped = c.VK_TRUE,
            .imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            .compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
            .queueFamilyIndexCount = @as(u32, queue_family_indices.len),
            .pQueueFamilyIndices = &queue_family_indices,
            .imageSharingMode = if (queue_family_indices.len == 1) c.VK_SHARING_MODE_EXCLUSIVE else c.VK_SHARING_MODE_CONCURRENT,
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

        const color_images = try allocator.alloc(VulkanImage, image_count);
        errdefer allocator.free(color_images);

        for (color_image_handles, color_images) |color_image_handle, *color_image| {
            color_image.* = VulkanImage.fromHandle(device, color_image_handle, allocation_callbacks);
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

        const depth_attachment = std.mem.zeroInit(c.VkAttachmentDescription, c.VkAttachmentDescription{
            .format = depth_format,
            .samples = c.VK_SAMPLE_COUNT_1_BIT,
            .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
            .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
            .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
            .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .finalLayout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        });

        const depth_attachment_ref = std.mem.zeroInit(c.VkAttachmentReference, c.VkAttachmentReference{
            .attachment = 1,
            .layout = c.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
        });

        const color_attachment = std.mem.zeroInit(c.VkAttachmentDescription, c.VkAttachmentDescription{
            .format = surface_format.format,
            .samples = c.VK_SAMPLE_COUNT_1_BIT,
            .loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
            .storeOp = c.VK_ATTACHMENT_STORE_OP_STORE,
            .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
            .stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
            .initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED,
            .finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
        });

        const color_attachment_ref = std.mem.zeroInit(c.VkAttachmentReference, c.VkAttachmentReference{
            .attachment = 0,
            .layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        });

        const subpass = std.mem.zeroInit(c.VkSubpassDescription, c.VkSubpassDescription{
            .pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
            .colorAttachmentCount = 1,
            .pColorAttachments = &color_attachment_ref,
            .pDepthStencilAttachment = &depth_attachment_ref,
        });

        const dependency = std.mem.zeroInit(c.VkSubpassDependency, c.VkSubpassDependency{
            .dstSubpass = 0,
            .dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT | c.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
            .dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
            .srcSubpass = c.VK_SUBPASS_EXTERNAL,
            .srcAccessMask = 0,
            .srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT | c.VK_PIPELINE_STAGE_EARLY_FRAGMENT_TESTS_BIT,
        });

        const attachments = [_]c.VkAttachmentDescription{ color_attachment, depth_attachment };

        const render_pass_info = std.mem.zeroInit(c.VkRenderPassCreateInfo, c.VkRenderPassCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
            .attachmentCount = attachments.len,
            .pAttachments = &attachments,
            .subpassCount = 1,
            .pSubpasses = &subpass,
            .dependencyCount = 1,
            .pDependencies = &dependency,
        });

        var render_pass: c.VkRenderPass = undefined;
        if (device.dispatch.CreateRenderPass(device.handle, &render_pass_info, null, &render_pass) < 0) return error.VkCreateRenderPass;

        var depth_images = allocator.alloc(VulkanImage, image_count);

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

            depth_images[i] = VulkanImage.init(device, &image_create_info, allocation_callbacks);
            depth_images[i].createMemory(c.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
            depth_images[i].createView(
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
            const frame_buffer_attachments = [_]c.VkImageView{ color_image.view, depth_image.view };

            const frame_buffer_create_info = std.mem.zeroInit(c.VkFramebufferCreateInfo, c.VkFramebufferCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
                .renderPass = render_pass,
                .attachmentCount = @intCast(frame_buffer_attachments.len),
                .pAttachments = &frame_buffer_attachments,
                .width = extent.width,
                .height = extent.height,
                .layers = 1,
            });

            if (device.CreateFramebuffer(device.handle, &frame_buffer_create_info, null, &frame_buffers[i]) < 0) return error.VkCreateFrameBuffer;
        }

        return .{
            .handle = handle,
            .allocation_callbacks = allocation_callbacks,
            .vulkan_library = device.physical_device.instance.vulkan_library,
            .device = device,
            .color_images = color_images,
            .depth_images = depth_images,
            .render_pass = render_pass,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroySwapchainKHR(self.device.handle, self.handle, self.allocation_callbacks);
        for (self.color_images) |*color_image| {
            color_image.deinit();
        }
        self.allocator.free(self.color_images);
    }

    pub fn acquireNextImage(self: *@This(), timeout_nanoseconds: ?u64, semaphore: c.VkSemaphore, fence: c.VkFence) !u32 {
        var result: u32 = undefined;
        if (self.device.dispatch.AcquireNextImageKHR(self.device.handle, self.handle, timeout_nanoseconds orelse std.math.maxInt(u64), semaphore, fence, &result) < 0) return error.VkAcquireNextImage;

        return result;
    }
};

pub const VulkanCommandPool = struct {
    handle: c.VkCommandPool,
    allocation_callbacks: ?*c.VkAllocationCallbacks,
    allocator: std.mem.Allocator,
    device: *const VulkanLogicalDevice,

    pub fn init(device: *const VulkanLogicalDevice, allocator: std.mem.Allocator, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        const create_info = std.mem.zeroInit(c.VkCommandPoolCreateInfo, c.VkCommandPoolCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .queueFamilyIndex = device.physical_device.queue_family_index,
            .flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
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

pub const VulkanCommandBuffer = struct {
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

pub const VulkanShaderModule = struct {
    handle: c.VkShaderModule,
    device: *const VulkanLogicalDevice,
    allocation_callbacks: ?*c.VkAllocationCallbacks,

    pub fn init(device: *const VulkanLogicalDevice, shader_code: []u8, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
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

pub const VulkanPipeline = struct {
    pub const ConfigInfo = struct {
        viewport: c.VkViewport,
        scissor: c.VkRect2D,
        viewport_info: c.VkPipelineViewportStateCreateInfo,
        input_assembly_info: c.VkPipelineInputAssemblyStateCreateInfo,
        rasterization_info: c.VkPipelineRasterizationStateCreateInfo,
        multisample_info: c.VkPipelineMultisampleStateCreateInfo,
        color_blend_attachment: c.VkPipelineColorBlendAttachmentState,
        color_blend_info: c.VkPipelineColorBlendStateCreateInfo,
        depth_stencil_info: c.VkPipelineDepthStencilStateCreateInfo,
        pipeline_layout: c.VkPipelineLayout,
        render_pass: c.VkRenderPass,
        subpass: u32,

        pub fn init(width: u32, height: u32) @This() {
            const input_assembly_info = std.mem.zeroInit(c.VkPipelineInputAssemblyStateCreateInfo, c.VkPipelineInputAssemblyStateCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
                .topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
                .primitiveRestartEnable = c.VK_FALSE,
            });

            const viewport = std.mem.zeroInit(c.VkViewport, c.VkViewport{
                .x = 0.0,
                .y = 0.0,
                .width = @floatFromInt(width),
                .height = @floatFromInt(height),
                .minDepth = 0.0,
                .maxDepth = 1.0,
            });

            const scissor = std.mem.zeroInit(c.VkRect2D, c.VkRect2D{
                .offset = std.mem.zeroes(c.VkOffset2D),
                .extent = .{ .width = width, .height = height },
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
                .polygonMode = c.VK_POLYGON_MODE_FILL,
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

            const color_blend_attachment = std.mem.zeroInit(c.VkPipelineColorBlendAttachmentState, c.VkPipelineColorBlendAttachmentState{
                .colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT | c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
                .blendEnable = c.VK_FALSE,
            });

            const color_blend_info = std.mem.zeroInit(c.VkPipelineColorBlendStateCreateInfo, c.VkPipelineColorBlendStateCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
                .logicOpEnable = c.VK_FALSE,
                .attachmentCount = 1,
                .pAttachments = &color_blend_attachment,
            });

            const depth_stencil_info = std.mem.zeroInit(c.VkPipelineDepthStencilStateCreateInfo, c.VkPipelineDepthStencilStateCreateInfo{
                .sType = c.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
                .depthTestEnable = c.VK_TRUE,
                .depthWriteEnable = c.VK_TRUE,
                .depthCompareOp = c.VK_COMPARE_OP_LESS,
                .depthBoundsTestEnable = c.VK_FALSE,
            });

            return std.mem.zeroInit(@This(), @This(){
                .input_assembly_info = input_assembly_info,
                .viewport = viewport,
                .scissor = scissor,
                .viewport_info = viewport_info,
                .rasterization_info = rasterization_info,
                .multisample_info = multisample_info,
                .color_blend_attachment = color_blend_attachment,
                .color_blend_info = color_blend_info,
                .depth_stencil_info = depth_stencil_info,
                .pipeline_layout = null,
                .render_pass = null,
                .subpass = 0,
            });
        }
    };

    handle: c.VkPipeline,
    device: *const VulkanLogicalDevice,
    frag_shader: *const VulkanShaderModule,
    vert_shader: *const VulkanShaderModule,
    allocation_callbacks: ?*c.VkAllocationCallbacks,

    pub fn init(device: *const VulkanLogicalDevice, config_info: *const ConfigInfo, frag_shader: *const VulkanShaderModule, vert_shader: *const VulkanShaderModule, allocation_callbacks: ?*c.VkAllocationCallbacks) !@This() {
        if (config_info.pipeline_layout == null) return error.PipelineLayoutIsNull;
        if (config_info.render_pass == null) return error.RenderPassIsNull;

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

        const vertex_input_info = std.mem.zeroInit(c.VkPipelineVertexInputStateCreateInfo, c.VkPipelineVertexInputStateCreateInfo{ .sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO });

        const create_info = std.mem.zeroInit(c.VkGraphicsPipelineCreateInfo, c.VkGraphicsPipelineCreateInfo{
            .sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .stageCount = 2,
            .pStages = &shader_stages,
            .pVertexInputState = &vertex_input_info,
            .pInputAssemblyState = &config_info.input_assembly_info,
            .pViewportState = &config_info.viewport_info,
            .pRasterizationState = &config_info.rasterization_info,
            .pColorBlendState = &config_info.color_blend_info,
            .pDepthStencilState = &config_info.depth_stencil_info,
            .pDynamicState = null,
            .layout = config_info.pipeline_layout,
            .renderPass = config_info.render_pass,
            .subpass = config_info.subpass,
            .basePipelineIndex = -1,
            .basePipelineHandle = @ptrCast(c.VK_NULL_HANDLE),
        });

        var handle: c.VkPipeline = undefined;
        if (device.dispatch.CreateGraphicsPipelines(device.handle, @ptrCast(c.VK_NULL_HANDLE), 1, &create_info, allocation_callbacks, &handle) < 0) return error.VkCreateGraphicsPipelines;

        return .{
            .handle = undefined,
            .device = device,
            .frag_shader = frag_shader,
            .vert_shader = vert_shader,
            .allocation_callbacks = allocation_callbacks,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.device.dispatch.DestroyPipeline(self.device.handle, self.handle, self.allocation_callbacks);
    }
};

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{ .verbose_log = true }){};
    defer std.debug.assert(general_purpose_allocator.deinit() == .ok);
    const allocator = general_purpose_allocator.allocator();

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

    var command_pool = try logical_device.createCommandPool(allocator, null);
    defer command_pool.deinit();

    const command_buffers = try command_pool.allocate(1, allocator);
    defer allocator.free(command_buffers);

    const window_extent = window.getExtent();
    const pipeline_config = VulkanPipeline.ConfigInfo.init(window_extent.width, window_extent.height);

    var frag_shader = try VulkanShaderModule.init(&logical_device, @constCast(@embedFile("shaders/simple_shader.frag.spv")), null);
    defer frag_shader.deinit();

    var vert_shader = try VulkanShaderModule.init(&logical_device, @constCast(@embedFile("shaders/simple_shader.vert.spv")), null);
    defer vert_shader.deinit();

    var pipeline = try VulkanPipeline.init(&logical_device, &pipeline_config, &frag_shader, &vert_shader, null);
    defer pipeline.deinit();

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
    }
}
