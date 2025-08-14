# Changelog

## [2.0.1] - 2025-01-14

### Fixed
- Fixed time parsing for events with timezone information (now correctly handles HHMMSS format)
- Fixed incorrect recurrence detection (RRULE from VTIMEZONE was being mistakenly applied to VEVENT)

## [2.0.0] - 2025-01-10

### Added
- Object-oriented architecture with `VcalParser` and `CalendarViewer` classes
- Multiple output formats: text (default), JSON, and compact
- Command-line options (`-f`, `-v`, `-h`)
- Support for additional VCAL fields:
  - LOCATION
  - RRULE (recurrence rules with human-readable output)
  - STATUS
  - PRIORITY
  - UID
- Comprehensive error handling and input validation
- Full test suite with RSpec
- Rakefile for common tasks
- Performance optimizations:
  - Precompiled regex patterns
  - Lazy loading of dependencies
  - Optimized string operations
  - Direct string indexing for date/time extraction

### Changed
- Refactored code into modular, maintainable structure
- Improved timezone handling with better error recovery
- Enhanced participant parsing
- Better description extraction with multiple fallback patterns
- Optimized parsing order for better performance

### Fixed
- Fixed time string handling for all-day events
- Improved handling of malformed VCAL files
- Better support for various VCAL format variations

## [1.1.1] - Previous version
- Fixed time string for All Day events
- Bug fix for Google calendar invitations

## [1.0.0] - Initial release
- Basic VCAL parsing functionality
- MUTT email client integration
- Support for basic event fields