const std = @import("std");
const backend = @import("backend.zig");
const Size = @import("data.zig").Size;
const DataWrapper = @import("data.zig").DataWrapper;
const Container_Impl = @import("containers.zig").Container_Impl;

pub const CheckBox_Impl = struct {
    pub usingnamespace @import("internal.zig").All(CheckBox_Impl);

    peer: ?backend.CheckBox = null,
    handlers: CheckBox_Impl.Handlers = undefined,
    dataWrappers: CheckBox_Impl.DataWrappers = .{},
    checked: DataWrapper(bool) = DataWrapper(bool).of(false),
    label: DataWrapper([:0]const u8) = DataWrapper([:0]const u8).of(""),
    enabled: DataWrapper(bool) = DataWrapper(bool).of(true),

    pub fn init() CheckBox_Impl {
        return CheckBox_Impl.init_events(CheckBox_Impl{});
    }

    pub fn _pointerMoved(self: *CheckBox_Impl) void {
        self.enabled.updateBinders();
    }

    fn wrapperCheckedChanged(newValue: bool, userdata: usize) void {
        const peer = @intToPtr(*?backend.CheckBox, userdata);
        peer.*.?.setChecked(newValue);
    }

    fn wrapperEnabledChanged(newValue: bool, userdata: usize) void {
        const peer = @intToPtr(*?backend.CheckBox, userdata);
        peer.*.?.setEnabled(newValue);
    }

    fn wrapperLabelChanged(newValue: [:0]const u8, userdata: usize) void {
        const peer = @intToPtr(*?backend.CheckBox, userdata);
        peer.*.?.setLabel(newValue);
    }

    fn onClick(self: *CheckBox_Impl) !void {
        self.checked.set(self.peer.?.isChecked());
    }

    pub fn show(self: *CheckBox_Impl) !void {
        if (self.peer == null) {
            self.peer = try backend.CheckBox.create();
            self.peer.?.setChecked(self.checked.get());
            self.peer.?.setEnabled(self.enabled.get());
            self.peer.?.setLabel(self.label.get());
            try self.show_events();

            _ = try self.checked.addChangeListener(.{ .function = wrapperCheckedChanged, .userdata = @ptrToInt(&self.peer) });
            _ = try self.enabled.addChangeListener(.{ .function = wrapperEnabledChanged, .userdata = @ptrToInt(&self.peer) });
            _ = try self.label.addChangeListener(.{ .function = wrapperLabelChanged, .userdata = @ptrToInt(&self.peer) });

            std.log.info("og: {*}", .{ self });
            try self.addClickHandler(&onClick);
        }
    }

    pub fn getPreferredSize(self: *CheckBox_Impl, available: Size) Size {
        _ = available;
        if (self.peer) |peer| {
            return peer.getPreferredSize();
        } else {
            return Size{ .width = 100.0, .height = 40.0 };
        }
    }

    pub fn setLabel(self: *CheckBox_Impl, label: [:0]const u8) void {
        self.label.set(label);
    }

    pub fn getLabel(self: *CheckBox_Impl) [:0]const u8 {
        return self.label.get();
    }

    pub fn _deinit(self: *CheckBox_Impl) void {
        self.enabled.deinit();
    }
};

pub fn CheckBox(config: CheckBox_Impl.Config) CheckBox_Impl {
    var btn = CheckBox_Impl.init();
    btn.checked.set(config.checked);
    btn.label.set(config.label);
    btn.enabled.set(config.enabled);
    btn.dataWrappers.alignX.set(config.alignX);
    btn.dataWrappers.alignY.set(config.alignY);
    btn.dataWrappers.name.set(config.name);
    if (config.onclick) |onclick| {
        btn.addClickHandler(onclick) catch unreachable; // TODO: improve
    }
    return btn;
}
