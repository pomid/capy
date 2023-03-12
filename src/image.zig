const std = @import("std");
const zigimg = @import("zigimg");
const backend = @import("backend.zig");
const internal = @import("internal.zig");
const Size = @import("data.zig").Size;
const DataWrapper = @import("data.zig").DataWrapper;

// TODO: use zigimg's structs instead of duplicating efforts
const Colorspace = @import("color.zig").Colorspace;

/// As of now, Capy UI only supports RGB and RGBA images
pub const ImageData = struct {
    width: u32,
    stride: u32,
    height: u32,
    /// Value pointing to the image data
    peer: backend.ImageData,
    data: []const u8,
    allocator: ?std.mem.Allocator = null,

    pub fn new(width: u32, height: u32, cs: Colorspace) !ImageData {
        const stride = width * cs.byteCount();
        const bytes = try internal.lasting_allocator.alloc(u8, stride * height);
        std.mem.set(u8, bytes, 0x00);
        return fromBytes(width, height, stride, cs, bytes, internal.lasting_allocator);
    }

    pub fn fromBytes(width: u32, height: u32, stride: u32, cs: Colorspace, bytes: []const u8, allocator: ?std.mem.Allocator) !ImageData {
        std.debug.assert(bytes.len >= stride * height);
        return ImageData{
            .width = width,
            .height = height,
            .stride = stride,
            .peer = try backend.ImageData.from(width, height, stride, cs, bytes),
            .data = bytes,
            .allocator = allocator,
        };
    }

    pub fn fromFile(allocator: std.mem.Allocator, path: []const u8) !ImageData {
        const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
        var stream = std.io.StreamSource{ .file = file };
        return readFromStream(allocator, &stream);
    }

    /// Load from a png file using a buffer (which can be provided by @embedFile)
    pub fn fromBuffer(allocator: std.mem.Allocator, buf: []const u8) !ImageData {
        // stage1 crashes with LLVM ERROR: Unable to expand fixed point multiplication.
        //const img = try zigimg.Image.fromMemory(allocator, buf);

        var stream = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(buf) };
        return readFromStream(allocator, &stream);
    }

    // TODO: on WASM, let the browser do the job of loading image data, so we can reduce the WASM bundle size
    // TODO: basically, use <img> on Web
    pub fn readFromStream(allocator: std.mem.Allocator, stream: *std.io.StreamSource) !ImageData {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        var plte = zigimg.png.PlteProcessor{};
        // TRNS processor isn't included as it crashed LLVM due to saturating multiplication
        var processors: [1]zigimg.png.ReaderProcessor = .{plte.processor()};
        var img = try zigimg.png.load(
            stream,
            allocator,
            zigimg.png.ReaderOptions.initWithProcessors(
                arena.allocator(),
                &processors,
            ),
        );
        //defer img.deinit();
        const bytes = img.rawBytes();
        return try ImageData.fromBytes(
            @intCast(u32, img.width),
            @intCast(u32, img.height),
            @intCast(u32, img.rowByteSize()),
            .RGBA,
            bytes,
            allocator,
        );
    }

    pub fn deinit(self: *ImageData) void {
        self.peer.deinit();
        if (self.allocator) |allocator| {
            allocator.free(self.data);
        }
        self.* = undefined;
    }
};
