const Cli = @This();
const std = @import("std");
const yazap = @import("yazap");
const App = yazap.App;
const Arg = yazap.Arg;
const Allocator = std.mem.Allocator;

allocator: Allocator,
app: App,
forward: ?[][]const u8 = null,
matches: *const yazap.ArgMatches = undefined,

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

fn get_forward_args(self: *Cli, args: [][]const u8) !usize {
    var forward = std.ArrayList([]const u8).init(self.allocator);
    var delim_idx: usize = args.len;

    for (args, 0..) |arg, i|
        if (std.mem.eql(u8, "--", arg)) {
            for (args[i + 1 ..]) |fwd|
                try forward.append(try self.allocator.dupe(u8, fwd));
            delim_idx = i;
            break;
        };

    self.forward = try forward.toOwnedSlice();
    return delim_idx;
}

pub fn parse(self: *Cli) !void {
    const args = try std.process.argsAlloc(self.allocator);
    defer std.process.argsFree(self.allocator, args);
    const delim_idx = try self.get_forward_args(args);
    self.matches = try self.app.parseFrom(args[1..delim_idx]);
}

pub fn deinit(self: *Cli) void {
    self.app.deinit();
    for (self.forward) |arg| self.allocator.free(arg);
    self.allocator.free(self.forward);
}
