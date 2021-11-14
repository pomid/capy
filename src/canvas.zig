const backend = @import("backend.zig");
const Size = @import("data.zig").Size;

pub const DrawContext = backend.Canvas.DrawContext;

pub const Canvas_Impl = struct {
    pub usingnamespace @import("internal.zig").All(Canvas_Impl);

    peer: ?backend.Canvas = null,
    handlers: Canvas_Impl.Handlers = undefined,
    dataWrappers: Canvas_Impl.DataWrappers = .{},
    preferredSize: ?Size = null,

    pub const DrawContext = backend.Canvas.DrawContext;

    pub fn init() Canvas_Impl {
        return Canvas_Impl.init_events(Canvas_Impl{});
    }

    pub fn getPreferredSize(self: *Canvas_Impl, available: Size) Size {
        _ = self;
        _ = available;

        // As it's a canvas, by default it should take the available space
        return self.preferredSize orelse available;
    }

    pub fn setPreferredSize(self: *Canvas_Impl, preferred: Size) Canvas_Impl {
        self.preferredSize = preferred;
        return self.*;
    }

    pub fn show(self: *Canvas_Impl) !void {
        if (self.peer == null) {
            self.peer = try backend.Canvas.create();
            try self.show_events();
        }
    }
};

pub fn Canvas(config: struct { onclick: ?Canvas_Impl.Callback = null }) Canvas_Impl {
    var btn = Canvas_Impl.init();
    if (config.onclick) |onclick| {
        btn.addClickHandler(onclick) catch unreachable; // TODO: improve
    }
    return btn;
}

const Color = @import("color.zig").Color;

pub const Rect_Impl = struct {
    pub usingnamespace @import("internal.zig").All(Rect_Impl);

    peer: ?backend.Canvas = null,
    handlers: Rect_Impl.Handlers = undefined,
    dataWrappers: Rect_Impl.DataWrappers = .{},
    preferredSize: ?Size = null,
    color: Color = Color.black,

    pub fn init() Rect_Impl {
        return Rect_Impl.init_events(Rect_Impl{});
    }

    pub fn getPreferredSize(self: *Rect_Impl, available: Size) Size {
        return self.preferredSize orelse
            available.intersect(Size.init(0, 0));
    }

    pub fn setPreferredSize(self: *Rect_Impl, preferred: Size) Rect_Impl {
        self.preferredSize = preferred;
        return self.*;
    }

    pub fn draw(self: *Rect_Impl, ctx: Canvas_Impl.DrawContext) !void {
        ctx.setColorByte(self.color);
        ctx.rectangle(0, 0, self.getWidth(), self.getHeight());
        ctx.fill();
    }

    pub fn show(self: *Rect_Impl) !void {
        if (self.peer == null) {
            self.peer = try backend.Canvas.create();
            try self.show_events();
        }
    }
};

pub fn Rect(config: struct { size: ?Size = null, color: Color = Color.black }) Rect_Impl {
    var btn = Rect_Impl.init();
    _ = btn.addDrawHandler(Rect_Impl.draw) catch unreachable;
    btn.preferredSize = config.size;
    btn.color = config.color;
    return btn;
}
