const std = @import("std");
const rl = @import("raylib");

const win = std.os.windows;

extern "imm32" fn ImmAssociateContext(
    hwnd: win.HWND,
    himc: ?*anyopaque,
) callconv(.winapi) ?*anyopaque;

pub fn disableIme() void {
    const handle = rl.getWindowHandle();
    const hwnd: win.HWND = @ptrCast(handle);
    _ = ImmAssociateContext(hwnd, null);
}
