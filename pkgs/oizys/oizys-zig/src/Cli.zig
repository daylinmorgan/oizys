const Cli = @This();
const std = @import("std");
const yazap = @import("yazap");
const App = yazap.App;
const Arg = yazap.Arg;

const Allocator = std.mem.Allocator;
app: App,

pub fn init(allocator: Allocator) !Cli {
    var app = App.init(allocator, "oizys", "nix begat oizys");

    const oizys = app.rootCommand();
    var cmd_dry = app.createCommand("dry", "poor man's nix flake check");
    var cmd_build = app.createCommand("build", "build nixos (w/nix build)");
    var cmd_cache = app.createCommand("cache", "build and push to cachix");
    var cmd_output = app.createCommand("output", "show system flake output path");
    var cmd_boot = app.createCommand("boot", "nixos rebuild boot");
    var cmd_switch = app.createCommand("switch", "nixos rebuild switch");
    const commands = .{ &cmd_dry, &cmd_build, &cmd_cache, &cmd_output, &cmd_switch, &cmd_boot };

    try cmd_cache.addArg(Arg.singleValueOption("name", 'n', "name of cachix cache"));
    inline for (commands) |subcmd| {
        try subcmd.addArg(Arg.singleValueOption("flake", 'f', "path to flake"));
        try subcmd.addArg(Arg.singleValueOption("host", null, "hostname (default: current host)"));
        try subcmd.addArg(Arg.booleanOption("no-pinix", null, "don't use pinix"));
        try oizys.addSubcommand(subcmd.*);
    }

    return Cli{ .app = app };
}

pub fn deinit(self: *Cli) void {
    self.app.deinit();
}
