const std = @import("std");
const parser = @import("parser.zig");
const report = @import("report.zig");
const config = @import("config.zig");

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Options = struct {
    template_file: ?[]const u8,
    format: report.Format,
    project_config_file: ?[]const u8, // Project-specific config file
    report_config_file: ?[]const u8, // Report-specific config file
    verbose: bool,
    findings_dir: ?[]const u8,
    output_file: ?[]const u8,
};

pub fn main() !void {
    // Initialize general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try printUsage();
        return error.InvalidArguments;
    }

    var options = Options{
        .template_file = null,
        .format = .md,
        .project_config_file = null,
        .report_config_file = null,
        .verbose = false,
        .findings_dir = null,
        .output_file = null,
    };

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            try printUsage();
            return;
        } else if (std.mem.eql(u8, arg, "-t") or std.mem.eql(u8, arg, "--template")) {
            if (i + 1 >= args.len) {
                try stderr.print("Error: Missing argument for {s}\n", .{arg});
                return error.MissingArgument;
            }
            options.template_file = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--format")) {
            if (i + 1 >= args.len) {
                try stderr.print("Error: Missing argument for {s}\n", .{arg});
                return error.MissingArgument;
            }
            if (std.mem.eql(u8, args[i + 1], "pdf")) {
                options.format = .pdf;
            }
            i += 1;
        } else if (std.mem.eql(u8, arg, "--project-config")) {
            if (i + 1 >= args.len) {
                try stderr.print("Error: Missing argument for {s}\n", .{arg});
                return error.MissingArgument;
            }
            options.project_config_file = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "--report-config")) {
            if (i + 1 >= args.len) {
                try stderr.print("Error: Missing argument for {s}\n", .{arg});
                return error.MissingArgument;
            }
            options.report_config_file = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            options.verbose = true;
        } else if (options.findings_dir == null) {
            options.findings_dir = arg;
        } else if (options.output_file == null) {
            options.output_file = arg;
        } else {
            try stderr.print("Error: Unexpected argument: {s}\n", .{arg});
            try printUsage();
            return error.UnexpectedArgument;
        }
    }

    // Validate required arguments
    if (options.findings_dir == null or options.output_file == null) {
        try stderr.print("Error: Missing required arguments\n", .{});
        try printUsage();
        return error.MissingRequiredArguments;
    }

    if (options.verbose) {
        try stdout.print("Running with options:\n", .{});
        try stdout.print("  Findings directory: {s}\n", .{options.findings_dir.?});
        try stdout.print("  Output file: {s}\n", .{options.output_file.?});
        try stdout.print("  Format: {}\n", .{options.format});
        if (options.template_file) |tf| {
            try stdout.print("  Template file: {s}\n", .{tf});
        }
        if (options.project_config_file) |pcf| {
            try stdout.print("  Project config file: {s}\n", .{pcf});
        }
        if (options.report_config_file) |rcf| {
            try stdout.print("  Report config file: {s}\n", .{rcf});
        }
    }

    // Load configuration
    var cfg = config.Config.init();

    // Handle project configuration
    if (options.project_config_file) |project_config_path| {
        if (options.verbose) {
            try stdout.print("Loading project configuration from {s}...\n", .{project_config_path});
        }

        cfg.project = try config.Config.loadProjectConfig(allocator, project_config_path);
    }

    // Handle report configuration
    if (options.report_config_file) |report_config_path| {
        if (options.verbose) {
            try stdout.print("Loading report configuration from {s}...\n", .{report_config_path});
        }

        cfg.report = try config.Config.loadReportConfig(allocator, report_config_path);
    }

    if (options.verbose) {
        try stdout.print("Configuration loaded:\n", .{});
        try stdout.print("  Project: {s}\n", .{cfg.project.name});
        try stdout.print("  Client: {s}\n", .{cfg.project.client});
        try stdout.print("  Template: {s}\n", .{cfg.report.template});
    }

    // Parse findings
    if (options.verbose) {
        try stdout.print("Parsing findings from {s}...\n", .{options.findings_dir.?});
    }

    var findings = parser.parseFindings(allocator, options.findings_dir.?, options.verbose) catch |err| {
        try stderr.print("Error parsing findings: {}\n", .{err});
        return err;
    };
    defer {
        for (findings.items) |*finding| {
            finding.deinit(allocator);
        }
        findings.deinit();
    }

    if (options.verbose) {
        try stdout.print("Found {} findings\n", .{findings.items.len});
    }

    // Generate report
    if (options.verbose) {
        try stdout.print("Generating report to {s}...\n", .{options.output_file.?});
    }

    try report.generateReport(findings, cfg, options.output_file.?, options.format, options.verbose);

    try stdout.print("Report generated successfully: {s}\n", .{options.output_file.?});
}

fn printUsage() !void {
    try stdout.print(
        \\audit-report-gen [OPTIONS] <findings-dir> <output-file>
        \\
        \\Options:
        \\  -t, --template <template-file>       Custom template file
        \\  -f, --format <format>                Output format (md, pdf) [default: md]
        \\  --project-config <config-file>       Project-specific configuration file
        \\  --report-config <config-file>        Report-specific configuration file
        \\  -v, --verbose                        Verbose output
        \\  -h, --help                           Print help information
        \\
    , .{});
}

test "simple test" {
    try std.testing.expectEqual(true, true);
}
