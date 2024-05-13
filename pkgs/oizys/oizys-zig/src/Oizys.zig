const Oizys = @This();
const std = @import("std");
const ArgMatches = @import("yazap").ArgMatches;
const Allocator = std.mem.Allocator;
const Donuts = @import("donuts").Donuts;

allocator: Allocator,
flake: []const u8,
host: []const u8,
cache_name: []const u8,
output: []const u8,
cmd: OizysCmd,
debug: bool = false,
forward: ?[][]const u8,

pub const OizysCmd = enum {
    dry,
    @"switch",
    boot,
    cache,
    output,
    build,
};

pub fn init(allocator: std.mem.Allocator, matches: *const ArgMatches, forward: ?[][]const u8) !Oizys {
    const cmd = matches.subcommand.?.name;
    const flags = matches.subcommandMatches(cmd).?;
    var oizys = Oizys{
        .allocator = allocator,
        .host = undefined,
        .flake = undefined,
        .output = undefined,
        .cmd = std.meta.stringToEnum(OizysCmd, cmd).?,
        .cache_name = flags.getSingleValue("cache") orelse "daylin",
        .forward = forward,
    };
    if (flags.getSingleValue("host")) |host| {
        oizys.host = try allocator.dupe(u8, host);
    } else {
        oizys.host = try Oizys.getDefaultHostName(allocator);
    }
    if (flags.getSingleValue("flake")) |flake| {
        oizys.flake = try allocator.dupe(u8, flake);
    } else {
        oizys.flake = try Oizys.getDefaultFlake(allocator);
    }

    oizys.output = try std.fmt.allocPrint(
        allocator,
        "{s}#nixosConfigurations.{s}.config.system.build.toplevel",
        .{ oizys.flake, oizys.host },
    );

    return oizys;
    // return Oizys{
    //     .allocator = allocator,
    //     .host = host,
    //     .flake = flake,
    //     .output = try std.fmt.allocPrint(
    //         allocator,
    //         "{s}#nixosConfigurations.{s}.config.system.build.toplevel",
    //         .{ flake, host },
    //     ),
    //     .cmd = std.meta.stringToEnum(OizysCmd, cmd).?,
    //     .cache_name = flags.getSingleValue("cache") orelse "daylin",
    //     .forward = forward,
    // };
}

pub fn deinit(self: *Oizys) void {
    self.allocator.free(self.flake);
    self.allocator.free(self.output);
    self.allocator.free(self.host);
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
    return std.fmt.allocPrint(
        self.allocator,
        "{s}#nixosConfigurations.{s}.config.system.build.toplevel",
        .{ self.flake, self.host },
    );
}

pub const NixCmd = enum { Nix, NixosRebuild };

pub fn runNixCmd(self: *Oizys, cmd: NixCmd, argv: []const []const u8) !void {
    var args = std.ArrayList([]const u8).init(self.allocator);
    defer args.deinit();

    switch (cmd) {
        NixCmd.Nix => try args.append("nix"),
        NixCmd.NixosRebuild => try args.appendSlice(&.{ "sudo", "nixos-rebuild" }),
    }
    try args.appendSlice(argv);
    if (self.forward) |fwd| try args.appendSlice(fwd);
    var p = std.ChildProcess.init(args.items, self.allocator);
    _ = try p.spawnAndWait();
}

pub fn cache(self: *Oizys) !void {
    var p = std.ChildProcess.init(
        &.{
            "cachix",
            "watch-exec",
            self.cache_name,
            "--verbose",
            "--",
            "nix",
            "build",
            self.output,
            "--print-build-logs",
            "--accept-flake-config",
        },
        self.allocator,
    );
    _ = try p.spawnAndWait();
}

const DryResult = struct {
    allocator: Allocator,
    fetch: [][]const u8,
    build: [][]const u8,

    pub fn parse(allocator: Allocator, output: []const u8) !DryResult {
        var it = std.mem.splitSequence(u8, output, ":\n");
        _ = it.next();
        var fetch = std.ArrayList([]const u8).init(allocator);
        var build = std.ArrayList([]const u8).init(allocator);

        if (it.next()) |x| {
            try parseLines(x, &fetch);
        } else {
            return error.DryParseError;
        }

        if (it.next()) |x| {
            try parseLines(x, &build);
        } else {
            return error.DryParseError;
        }

        return .{
            .allocator = allocator,
            .fetch = try fetch.toOwnedSlice(),
            .build = try build.toOwnedSlice(),
        };
    }

    pub fn deinit(self: *DryResult) void {
        self.allocator.free(self.fetch);
        self.allocator.free(self.build);
        // for (self.fetch) |item| {
        // self.allocator.free(item);
        // }
        // for (self.build) |item| {
        //     self.allocator.free(item);
        // }
    }
    fn parseLines(buffer: []const u8, list: *std.ArrayList([]const u8)) !void {
        var lines = std.mem.splitSequence(u8, buffer, "\n");
        while (lines.next()) |line| {
            try list.append(line);
        }
    }
};

pub fn dry(self: *Oizys) !void {
    var sp = Donuts(std.io.getStdOut()).init(
        "evaluating...",
        .{ .style = .dots },
        .{},
    );
    try sp.start();
    const cmd_output = try std.ChildProcess.run(.{
        .allocator = self.allocator,
        .argv = &.{ "nix", "build", self.output, "--dry-run" },
    });
    try sp.stop(.{ .message = "done." });
    defer self.allocator.free(cmd_output.stdout);
    defer self.allocator.free(cmd_output.stderr);
    var result = try DryResult.parse(self.allocator, cmd_output.stderr);
    defer result.deinit();

    std.debug.print(
        "to fetch: {d}\nto build: {d}\n",
        .{ result.fetch.len, result.build.len },
    );
}

pub fn run(self: *Oizys) !void {
    switch (self.cmd) {
        .@"switch" => try self.runNixCmd(.NixosRebuild, &.{ "switch", "--flake", self.flake }),

        .boot => try self.runNixCmd(.NixosRebuild, &.{ "boot", "--flake", self.flake }),
        .dry => try self.dry(),
        .build => try self.runNixCmd(.Nix, &.{ "build", self.output }),
        .output => {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("{s}\n", .{self.output});
        },
        .cache => try self.cache(),
    }
}
