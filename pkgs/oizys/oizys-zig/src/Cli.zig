const Cli = @This();
const std = @import("std");
const yazap = @import("yazap");
const App = yazap.App;
const Arg = yazap.Arg;
const Allocator = std.mem.Allocator;

allocator: Allocator,
app: App,
matches: *const yazap.ArgMatches = undefined,
forward: ?[][]const u8 = null,
process_args: ?[]const [:0]u8 = null,

pub fn init(allocator: Allocator) !Cli {
    var app = App.init(allocator, "oizys", "nix begat oizys");

    const oizys = app.rootCommand();
    var cmd_dry = app.createCommand("dry", "poor man's nix flake check");
    var cmd_build = app.createCommand("build", "build nixos (w/nix build)");
    var cmd_cache = app.createCommand("cache", "build and push to cachix");
    var cmd_output = app.createCommand("output", "show system flake output path");
    var cmd_boot = app.createCommand("boot", "nixos rebuild boot");
    var cmd_switch = app.createCommand("switch", "nixos rebuild switch");

    try cmd_cache.addArg(Arg.singleValueOption("name", 'n', "name of cachix cache"));
    inline for (.{
        &cmd_dry,
        &cmd_build,
        &cmd_cache,
        &cmd_output,
        &cmd_switch,
        &cmd_boot,
    }) |subcmd| {
        try subcmd.addArg(Arg.positional("forward", null, null));
        try subcmd.addArg(Arg.singleValueOption("flake", 'f', "path to flake"));
        try subcmd.addArg(Arg.singleValueOption("host", null, "hostname (default: current host)"));
        try subcmd.addArg(Arg.booleanOption("no-pinix", null, "don't use pinix"));
        try oizys.addSubcommand(subcmd.*);
    }

    return Cli{
        .allocator = allocator,
        .app = app,
    };
}

fn get_forward_args(self: *Cli, args: []const [:0]u8) !usize {
    var forward = std.ArrayList([]const u8).init(self.allocator);

    const delim_idx: usize = delim_lookup: for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, "--", arg)) break :delim_lookup i;
    } else args.len;

    if (args.len > delim_idx)
        for (args[delim_idx + 1 ..]) |fwd|
            try forward.append(fwd);

    self.forward = try forward.toOwnedSlice();
    return delim_idx;
}

pub fn parse(self: *Cli) !void {
    self.process_args = try std.process.argsAlloc(self.allocator);
    const delim_idx = try self.get_forward_args(self.process_args.?);
    self.matches = try self.app.parseFrom(self.process_args.?[1..delim_idx]);
}

pub fn deinit(self: *Cli) void {
    std.process.argsFree(self.allocator, self.process_args.?);
    if (self.forward) |fwd| {
        for (fwd) |arg| self.allocator.free(arg);
        self.allocator.free(fwd);
    }
    self.app.deinit();
}
