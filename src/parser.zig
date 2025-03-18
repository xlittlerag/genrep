const std = @import("std");
const ziggy = @import("ziggy");
const config = @import("config.zig");

/// Represents a code reference in a finding
pub const CodeReference = struct {
    file: []const u8,
    lines: []const u8,

    pub fn deinit(self: *CodeReference, allocator: std.mem.Allocator) void {
        allocator.free(self.file);
        allocator.free(self.lines);
    }
};

/// Represents a security finding
pub const Finding = struct {
    id: []const u8,
    title: []const u8,
    severity: config.Severity,
    code_refs: std.ArrayList(CodeReference),
    description: []const u8,
    recommendation: []const u8,

    pub fn init(allocator: std.mem.Allocator) Finding {
        return Finding{
            .id = "",
            .title = "",
            .severity = config.Severity.Medium,
            .code_refs = std.ArrayList(CodeReference).init(allocator),
            .description = "",
            .recommendation = "",
        };
    }

    pub fn deinit(self: *Finding, allocator: std.mem.Allocator) void {
        allocator.free(self.title);
        allocator.free(self.id);
        allocator.free(self.description);

        for (self.code_refs.items) |*code_ref| {
            code_ref.deinit(allocator);
        }
        self.code_refs.deinit();

        allocator.free(self.recommendation);
    }
};

/// Parse findings from a directory
pub fn parseFindings(allocator: std.mem.Allocator, dir_path: []const u8, verbose: bool) !std.ArrayList(Finding) {
    var findings = std.ArrayList(Finding).init(allocator);

    var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;

        // Skip files that don't end with .ziggy
        if (!std.mem.endsWith(u8, entry.name, ".ziggy")) continue;

        if (verbose) {
            std.log.info("Parsing finding file: {s}\n", .{entry.name});
        }

        const finding_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir_path, entry.name });
        defer allocator.free(finding_path);

        if (parseFindingFile(allocator, finding_path, verbose)) |finding| {
            try findings.append(finding);
        } else |err| {
            if (verbose) {
                std.log.info("Error parsing finding file '{s}': {}\n", .{ entry.name, err });
            }
        }
    }

    return findings;
}

/// Parse a single finding file
pub fn parseFindingFile(allocator: std.mem.Allocator, file_path: []const u8) !Finding {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_content = try file.readToEndAlloc(allocator, 1024 * 1024); // 1MB max
    defer allocator.free(file_content);

    // Basic validation that this is a Ziggy format file
    if (!std.mem.containsAtLeast(u8, file_content, 1, "{")) {
        return error.InvalidFindingFormat;
    }

    return try ziggy.parseLeaky(Finding, allocator, file_content, .{});
}

test "parse finding file" {
    // TODO: Add tests for parsing finding files
    try std.testing.expectEqual(true, true);
}
