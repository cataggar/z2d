// SPDX-License-Identifier: 0BSD

//! Temporary directories shared by the spec runner and reference-image generator.
const TmpDir = @This();
const std = @import("std");

dir: std.Io.Dir,
parent_dir: std.Io.Dir,
sub_path: [sub_path_len]u8,

const random_bytes_count = 12;
const sub_path_len = std.base64.url_safe.Encoder.calcSize(random_bytes_count);

pub fn cleanup(self: *TmpDir, io: std.Io) void {
    self.dir.close(io);
    self.parent_dir.deleteTree(io, &self.sub_path) catch |err|
        std.debug.panic("unable to remove spec temporary directory: {}", .{err});
    self.parent_dir.close(io);
    self.* = undefined;
}

pub fn init(io: std.Io, opts: std.Io.Dir.OpenOptions) TmpDir {
    var random_bytes: [random_bytes_count]u8 = undefined;
    io.random(&random_bytes);
    var sub_path: [sub_path_len]u8 = undefined;
    _ = std.base64.url_safe.Encoder.encode(&sub_path, &random_bytes);
    var cache_dir = std.Io.Dir.cwd().createDirPathOpen(io, ".zig-cache", .{}) catch |err|
        std.debug.panic("unable to open spec cache directory: {}", .{err});
    defer cache_dir.close(io);
    const parent_dir = cache_dir.createDirPathOpen(io, "tmp", .{}) catch |err|
        std.debug.panic("unable to open spec temporary directory parent: {}", .{err});
    const dir = parent_dir.createDirPathOpen(io, &sub_path, .{ .open_options = opts }) catch |err|
        std.debug.panic("unable to create spec temporary directory: {}", .{err});
    return .{ .dir = dir, .parent_dir = parent_dir, .sub_path = sub_path };
}
