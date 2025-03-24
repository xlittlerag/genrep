const std = @import("std");
const config = @import("config.zig");
const parser = @import("parser.zig");

pub const Format = enum { pdf, md };

/// Generate a report from findings
pub fn generateReport(
    allocator: std.mem.Allocator,
    findings: std.ArrayList(parser.Finding),
    cfg: config.Config,
    output_path: []const u8,
    format: Format,
    verbose: bool,
) !void {
    if (verbose) {
        std.debug.print("Generating report with {} findings\n", .{findings.items.len});
    }

    // Sort findings by severity
    sortFindingsBySeverity(findings);

    if (format == .md) {
        try generateMarkdownReport(allocator, findings, cfg, output_path, verbose);
    } else if (format == .pdf) {
        // PDF generation is not implemented yet
        return error.PdfGenerationNotImplemented;
    } else {
        return error.UnsupportedOutputFormat;
    }
}

/// Sort findings by severity (Critical first, Informational last)
fn sortFindingsBySeverity(findings: std.ArrayList(parser.Finding)) void {
    std.sort.sort(parser.Finding, findings.items, {}, compareFindingsBySeverity);
}

/// Comparison function for sorting findings by severity
fn compareFindingsBySeverity(context: void, a: parser.Finding, b: parser.Finding) bool {
    _ = context;
    return @intFromEnum(a.severity) < @intFromEnum(b.severity);
}

/// Generate a report in Markdown format
fn generateMarkdownReport(
    // allocator: std.mem.Allocator,
    findings: std.ArrayList(parser.Finding),
    cfg: config.Config,
    output_path: []const u8,
    verbose: bool,
) !void {
    if (verbose) {
        std.debug.print("Generating Markdown report to {s}\n", .{output_path});
    }

    var file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();

    // Write report header
    try file.writer().print("# {s} Audit Report\n\n", .{cfg.project.name});
    try file.writer().print("**Client:** {s}\n\n", .{cfg.project.client});
    try file.writer().print("**Date:** {s}\n\n", .{cfg.project.date});

    // Write auditors if any
    if (cfg.project.auditors.items.len > 0) {
        try file.writer().print("**Auditors:**\n\n", .{});
        for (cfg.project.auditors.items) |auditor| {
            try file.writer().print("- {s}\n", .{auditor});
        }
        try file.writer().print("\n", .{});
    }

    // Write executive summary
    try file.writer().print("## Executive Summary\n\n", .{});
    try file.writer().print("This report presents the findings of a security audit of the {s} project.\n\n", .{cfg.project.name});

    // Write findings summary table if enabled
    if (cfg.report.include_summary_table) {
        try file.writer().print("### Findings Summary\n\n", .{});
        try file.writer().print("| ID | Title | Severity |\n", .{});
        try file.writer().print("|:---|:------|:---------|\n", .{});

        for (findings.items) |finding| {
            try file.writer().print("| {s} | {s} | {s} |\n", .{
                finding.id,
                finding.title,
                @tagName(finding.severity),
            });
        }
        try file.writer().print("\n", .{});
    }

    // Write detailed findings
    try file.writer().print("## Detailed Findings\n\n", .{});

    for (findings.items) |finding| {
        try file.writer().print("### [{s}] {s}\n\n", .{
            @tagName(finding.severity),
            finding.title,
        });

        try file.writer().print("**ID:** {s}\n\n", .{finding.id});
        try file.writer().print("**Description:**\n\n{s}\n\n", .{finding.description});

        if (finding.code_refs.items.len > 0) {
            try file.writer().print("**Affected Code:**\n\n", .{});
            for (finding.code_refs.items) |code_ref| {
                try file.writer().print("File: `{s}`, Lines: {s}\n\n", .{
                    code_ref.file,
                    code_ref.lines,
                });

                // Include code snippets if enabled
                // if (cfg.report.include_code_snippets) {
                //     // TODO: Implement code snippet extraction
                //     try file.writer().print("```solidity\n// Code snippet will be included here\n```\n\n", .{});
                // }
            }
        }

        try file.writer().print("**Recommendation:**\n\n{s}\n\n", .{finding.recommendation});
        try file.writer().print("---\n\n", .{});
    }

    // Write report footer
    try file.writer().print("## Conclusion\n\n", .{});
    try file.writer().print("This audit was conducted to identify potential security issues in the {s} project. " ++
        "The findings presented in this report should be addressed to improve the security posture of the project.\n", .{cfg.project.name});
}

test "sort findings" {
    var allocator = std.testing.allocator;

    var findings = std.ArrayList(parser.Finding).init(allocator);
    defer {
        for (findings.items) |*finding| {
            finding.deinit(allocator);
        }
        findings.deinit();
    }

    // Create some test findings
    var finding1 = parser.Finding.init(allocator);
    finding1.id = try allocator.dupe(u8, "VULN-001");
    finding1.title = try allocator.dupe(u8, "Medium Severity Issue");
    finding1.severity = config.Severity.Medium;
    try findings.append(finding1);

    var finding2 = parser.Finding.init(allocator);
    finding2.id = try allocator.dupe(u8, "VULN-002");
    finding2.title = try allocator.dupe(u8, "Critical Severity Issue");
    finding2.severity = config.Severity.Critical;
    try findings.append(finding2);

    // Sort findings
    sortFindingsBySeverity(findings);

    // Verify order (Critical should come before Medium)
    try std.testing.expectEqual(config.Severity.Critical, findings.items[0].severity);
    try std.testing.expectEqual(config.Severity.Medium, findings.items[1].severity);
}
