const std = @import("std");
const ziggy = @import("ziggy");

/// Configuration for the audit report generator
pub const Config = struct {
    project: ProjectConfig,
    report: ReportConfig,

    pub fn init() Config {
        return Config{
            .project = ProjectConfig{
                .name = "Unnamed Audit",
                .client = "Unknown Client",
                .date = "Unknown Date",
                .auditors = std.ArrayList([]const u8).init(std.heap.page_allocator),
            },
            .report = ReportConfig{
                .template = "default",
                .include_summary_table = true,
                .severity_levels = SeverityLevels{
                    .critical = SeverityConfig{
                        .description = "Issues that can lead to direct fund loss",
                        .color = "#FF0000",
                    },
                    .high = SeverityConfig{
                        .description = "Issues that can lead to indirect fund loss",
                        .color = "#FFA500",
                    },
                    .medium = SeverityConfig{
                        .description = "Issues that could cause problems with operations",
                        .color = "#FFFF00",
                    },
                    .low = SeverityConfig{
                        .description = "Issues that are minor or represent best practices",
                        .color = "#00FF00",
                    },
                    .informational = SeverityConfig{
                        .description = "Suggestions and informational findings",
                        .color = "#0000FF",
                    },
                },
            },
        };
    }

    /// Load project configuration from file
    pub fn loadProjectConfig(allocator: std.mem.Allocator, file_path: []const u8) !ProjectConfig {
        // Open the file's directory
        const path = std.fs.path.dirname(file_path) orelse ".";
        const filename = std.fs.path.basename(file_path);

        var dir = try std.fs.cwd().openDir(path, .{});
        defer dir.close();

        // Read the file with null termination
        const file_content = try dir.readFileAllocOptions(allocator, filename, ziggy.max_size, null, 1, 0);
        defer allocator.free(file_content);

        // Parse config file using ziggy parser
        return try ziggy.parseLeaky(ProjectConfig, allocator, file_content, .{});
    }

    /// Load report configuration from file
    pub fn loadReportConfig(allocator: std.mem.Allocator, file_path: []const u8) !ReportConfig {
        // Open the file's directory
        const path = std.fs.path.dirname(file_path) orelse ".";
        const filename = std.fs.path.basename(file_path);

        var dir = try std.fs.cwd().openDir(path, .{});
        defer dir.close();

        // Read the file with null termination
        const file_content = try dir.readFileAllocOptions(allocator, filename, ziggy.max_size, null, 1, 0);
        defer allocator.free(file_content);

        // Parse config file using ziggy parser
        return try ziggy.parseLeaky(ReportConfig, allocator, file_content, .{});
    }
};

/// Project-specific configuration
pub const ProjectConfig = struct {
    name: []const u8,
    client: []const u8,
    date: []const u8,
    auditors: std.ArrayList([]const u8),
};

/// Report generation configuration
pub const ReportConfig = struct {
    template: []const u8,
    include_summary_table: bool,
    severity_levels: SeverityLevels,
};

/// Configuration for a specific severity level
pub const SeverityConfig = struct {
    description: []const u8,
    color: []const u8,
};

/// Configurations for all severity levels
pub const SeverityLevels = struct {
    critical: SeverityConfig,
    high: SeverityConfig,
    medium: SeverityConfig,
    low: SeverityConfig,
    informational: SeverityConfig,
};

/// Finding severity enum
pub const Severity = enum {
    Critical,
    High,
    Medium,
    Low,
    Informational,
};

test "load default config" {
    const config = Config.init();
    try std.testing.expectEqualStrings("Unnamed Audit", config.project.name);
    try std.testing.expectEqualStrings("Unknown Client", config.project.client);
    try std.testing.expectEqualStrings("default", config.report.template);
}
