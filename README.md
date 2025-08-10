# VcalView

A robust VCAL/iCalendar viewer for terminal and MUTT email client with multiple output formats.

## Features

- **Full iCalendar Support**: Parses all major VCAL/ICS fields including events, timezones, recurrence rules, and attendees
- **Multiple Output Formats**: Text (default), JSON, and compact formats for different use cases
- **Timezone Handling**: Automatic timezone conversion with Windows timezone name support
- **Error Handling**: Graceful handling of malformed calendar files with helpful error messages
- **Recurrence Parsing**: Understands RRULE patterns and displays them in human-readable format
- **Additional Fields**: Supports LOCATION, STATUS, PRIORITY, UID, and more
- **Command-line Options**: Flexible output control via command-line flags

## Installation

### Via RubyGems
```bash
gem install calview
```

### Manual Installation
```bash
# Install optional timezone support
gem install tzinfo

# Clone the repository
git clone https://github.com/isene/calview.git
cd calview

# Make the script executable
chmod +x bin/calview.rb

# Copy to your PATH (optional)
cp bin/calview.rb ~/bin/
```

## Usage

### Command Line

```bash
# View a calendar file with default text output
calview.rb calendar.ics

# Output in JSON format
calview.rb -f json calendar.ics

# Compact one-line output
calview.rb -f compact calendar.ics

# Verbose output (includes UID)
calview.rb -v calendar.ics

# Show help
calview.rb -h
```

### MUTT Integration

Add this line to your `.mailcap` file:

```
text/calendar; /path/to/calview.rb '%s'; copiousoutput
```

MUTT will now automatically display calendar invites using calview.

## Output Formats

### Text Format (Default)
```
WHAT: Team Meeting
WHEN: 2024-01-15 (Monday of week 3), 10:00 - 11:00
WHERE: Conference Room A
RECURRENCE: Weekly (10 times)
STATUS: Confirmed
PRIORITY: High

ORGANIZER: John Doe <john@example.com>
PARTICIPANTS:
   Jane Smith <jane@example.com>
   Bob Johnson <bob@example.com>

DESCRIPTION:
Weekly team sync to discuss project progress
```

### JSON Format
Perfect for integration with other tools:
```json
{
  "summary": "Team Meeting",
  "dates": "2024-01-15",
  "times": "10:00 - 11:00",
  "location": "Conference Room A",
  "recurrence": "Weekly (10 times)",
  ...
}
```

### Compact Format
One-line summary for quick viewing:
```
Team Meeting | 2024-01-15 10:00 - 11:00
Location: Conference Room A
Organizer: John Doe <john@example.com>
```

## Development

### Running Tests
```bash
# Install development dependencies
bundle install

# Run the test suite
rake spec

# Or directly with RSpec
rspec
```

### Building the Gem
```bash
rake build
```

## Requirements

- Ruby 2.5.0 or higher
- Optional: `tzinfo` gem for timezone support

## Contributing

If you encounter any issues or errors, please open an issue in this repository. Pull requests are welcome!

## License

Released into the Public Domain under the Unlicense.
