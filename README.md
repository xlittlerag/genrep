# genrep - Audit Report Generator

A lightweight command-line tool written in Zig that enables blockchain security engineers to create standardized smart contract audit reports from structured input files.

## Features

- Parse findings from Ziggy format files
- Generate standardized audit reports in Markdown and PDF formats
- Include code snippets with syntax highlighting
- Customizable templates and configuration

## Status

This project is under active development.

## Building

```bash
git clone https://github.com/xlittlrag/genrep.git
cd genrep
zig build
```

## Usage

```bash
./genrep [OPTIONS] <findings-dir> <output-file>

Options:
  -t, --template <template-file>   Custom template file
  -f, --format <format>            Output format (md, pdf) [default: md]
  -c, --config <config-file>       Configuration file
  -v, --verbose                    Verbose output
  -h, --help                       Print help information
```

## Example

```bash
./genrep -c config.zig examples/findings report.md
```

## License

MIT
