# Audit Report Generator

A lightweight command-line tool written in Zig that enables blockchain security engineers to create standardized smart contract audit reports from structured input files.

## Features

- Parse findings from Ziggy format files (`.ziggy` extension)
- Generate standardized audit reports in Markdown and PDF formats
- Include code snippets with syntax highlighting
- Customizable templates and configuration

## Status

This project is under active development. Currently:

- Basic CLI framework is implemented
- Project structure is established
- Configuration loading is working
- Finding parsing is implemented
- Markdown report generation is functional

### Known Issues

- The Ziggy parser library has compatibility issues with Zig 0.14.0, showing errors related to opaque types and function pointers
- PDF export functionality is not yet implemented
- Code snippet extraction is not yet implemented

## Building

```bash
git clone https://github.com/xlittlerag/audit-report-gen.git
cd audit-report-gen
zig build
```

## Usage

```bash
./audit-report-gen [OPTIONS] <findings-dir> <output-file>

Options:
  -t, --template <template-file>       Custom template file
  -f, --format <format>                Output format (md, pdf) [default: md]
  --project-config <config-file>       Project-specific configuration file
  --report-config <config-file>        Report-specific configuration file
  -v, --verbose                        Verbose output
  -h, --help                           Print help information
```

### Example Usage

```bash
./audit-report-gen --project-config examples/project.ziggy -v examples/findings report.md
```

## Finding File Structure (Ziggy format)

```zig
{
  .title = "Reentrancy in withdraw function",
  .id = "VULN-001",
  .severity = .Critical,
  .description = 
    \\The withdraw function does not follow the checks-effects-interactions pattern,
    \\allowing potential reentrancy attacks.
  ,
  .code_refs = {
    {
      .file = "contracts/Vault.sol",
      .lines = "45-52",
    },
  },
  .recommendation = 
    \\Implement the checks-effects-interactions pattern by updating state
    \\before making external calls.
  ,
}
```

## Configuration Files

### Project Configuration (Ziggy format)
```zig
{
  .name = "Protocol X Audit",
  .client = "DeFi Labs",
  .date = "2025-03-10",
  .auditors = {
    "Alice Smith",
    "Bob Johnson",
  },
}
```

### Report Configuration (Ziggy format)
```zig
{
  .template = "default",
  .include_summary_table = true,
  .severity_levels = {
    .critical = {
      .description = "Issues that can lead to direct fund loss",
      .color = "#FF0000",
    },
    .high = {
      .description = "Issues that can lead to indirect fund loss",
      .color = "#FFA500",
    },
    .medium = {
      .description = "Issues that could cause problems with operations",
      .color = "#FFFF00", 
    },
    .low = {
      .description = "Issues that are minor or represent best practices",
      .color = "#00FF00",
    },
    .informational = {
      .description = "Suggestions and informational findings",
      .color = "#0000FF",
    },
  },
}
```

## Development Roadmap

### Phase 1: Core Functionality ✅
- Set up Zig project structure
- Implement CLI interface
- Implement configuration parsing
- Implement finding parsing
- Implement basic Markdown report generation

### Phase 2: Enhanced Functionality 🚧
- Add code snippet extraction and inclusion
- Implement template system for customized reports
- Add PDF export functionality
- Improve error handling

### Phase 3: Advanced Features 📝
- Implement finding status tracking
- Add finding categorization
- Support for cross-references between findings

## License

MIT
