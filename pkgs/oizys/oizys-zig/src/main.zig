const std = @import("std");
const Oizys = @import("Oizys.zig");
const Cli = @import("Cli.zig");

pub fn main() !void {
    // memory management isn't hard :P
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var cli = try Cli.init(allocator);
    const matches = try cli.app.parseProcess();

    if (!matches.containsArgs()) {
        try cli.app.displayHelp();
        return;
    }

    var oizys = try Oizys.init(allocator, matches);
    try oizys.run();
}
