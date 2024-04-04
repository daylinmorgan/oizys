const Oizys = @This();
const std = @import("std");
const ArgMatches = @import("yazap").ArgMatches;
const Allocator = std.mem.Allocator;

allocator: Allocator,
flake: []const u8,
host: []const u8,
cache_name: []const u8,
output: []const u8,
cmd: OizysCmd,
no_pinix: bool,
debug: bool = false,

pub const OizysCmd = enum {
    dry,
    @"switch",
    boot,
    cache,
    output,
    build,
};

pub fn init(allocator: std.mem.Allocator, matches: *const ArgMatches) !Oizys {
    const cmd = matches.subcommand.?.name;
    const flags = matches.subcommandMatches(cmd).?;
    const host = flags.getSingleValue("host") orelse try Oizys.getDefaultHostName(allocator);
    const flake = flags.getSingleValue("flake") orelse try Oizys.getDefaultFlake(allocator);

    return Oizys{
        .allocator = allocator,
        .host = host,
        .flake = flake,
        .output = try std.fmt.allocPrint(allocator, "{s}#nixosConfigurations.{s}.config.system.build.toplevel", .{ flake, host }),
        .cmd = std.meta.stringToEnum(OizysCmd, cmd).?,
        .cache_name = flags.getSingleValue("cache") orelse "daylin",
        .no_pinix = flags.containsArg("no-pinix"),
    };
}

pub fn deinit(self: *Oizys) void {
    self.allocator.free(self.flake);
    self.allocator.free(self.host);
    self.allocator.free(self.output);
}

pub fn nix(self: *Oizys) []const u8 {
    return if (self.no_pinix) "nix" else "pix";
}

pub fn nixos_rebuild(self: *Oizys) []const u8 {
    return if (self.no_pinix) "nixos-rebuild" else "pixos-rebuild";
}

pub fn getDefaultHostName(allocator: Allocator) ![]const u8 {
    var name_buffer: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostname = try std.posix.gethostname(&name_buffer);
    return std.fmt.allocPrint(allocator, "{s}", .{hostname});
}

pub fn getDefaultFlake(allocator: Allocator) ![]const u8 {
    return std.process.getEnvVarOwned(allocator, "OIZYS_DIR") catch {
        const homedir = try std.process.getEnvVarOwned(allocator, "HOME");
        defer allocator.free(homedir);
        return try std.fmt.allocPrint(allocator, "{s}/oizys", .{homedir});
    };
}

pub fn getOutputPath(self: *Oizys) ![]const u8 {
    return std.fmt.allocPrint(self.allocator, "{s}#nixosConfigurations.{s}.config.system.build.toplevel", .{ self.flake, self.host });
}

pub const NixCmd = enum { Nix, NixosRebuild };

pub fn runNixCmd(self: *Oizys, cmd: NixCmd, argv: []const []const u8) !void {
    var args = std.ArrayList([]const u8).init(self.allocator);
    defer args.deinit();

    switch (cmd) {
        NixCmd.Nix => try args.append(self.nix()),
        NixCmd.NixosRebuild => try args.appendSlice(&.{ "sudo", self.nixos_rebuild() }),
    }
    try args.appendSlice(argv);
    var p = std.ChildProcess.init(args.items, self.allocator);
    _ = try p.spawnAndWait();
}

pub fn cache(self: *Oizys) !void {
    var p = std.ChildProcess.init(&.{ "cachix", "watch-exec", self.cache_name, "--verbose", "--", "nix", "build", self.flake, "--print-build-logs", "--accept-flake-config" }, self.allocator);
    _ = try p.spawnAndWait();
}

pub fn run(self: *Oizys) !void {
    switch (self.cmd) {
        .@"switch" => {
            try self.runNixCmd(NixCmd.NixosRebuild, &.{ "switch", "--flake", self.flake });
        },
        .boot => {
            try self.runNixCmd(NixCmd.NixosRebuild, &.{ "boot", "--flake", self.flake });
        },
        .dry => {
            try self.runNixCmd(NixCmd.Nix, &.{ "build", self.output, "--dry-run" });
        },
        .build => {
            try self.runNixCmd(NixCmd.Nix, &.{ "build", self.output });
        },
        .output => {
            std.debug.print("{s}", .{self.output});
        },
        .cache => {
            try self.cache();
        },
    }
}