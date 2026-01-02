//// Common types used across GTFS Static and Realtime
//// 
//// These foundational types represent the core data formats
//// specified in the GTFS reference documentation.

import gleam/option.{type Option}
import gleam/string

// =============================================================================
// Date Types
// =============================================================================

/// Date in YYYYMMDD format
/// Example: 20251028 represents October 28, 2025
/// Source: GTFS Static reference.md
pub type Date {
  Date(year: Int, month: Int, day: Int)
}

// =============================================================================
// Time Types
// =============================================================================

/// Time in HH:MM:SS format (H:MM:SS also accepted)
/// Can exceed 24:00:00 for overnight service on the same service day
/// Example: 25:35:00 represents 1:35 AM on the next calendar day
/// but still part of the same service day
/// Source: GTFS Static reference.md - times can exceed 24:00:00
pub type Time {
  Time(hours: Int, minutes: Int, seconds: Int)
}

/// Local time - wall-clock time in local timezone
/// Used for timeframes.txt
/// Cannot exceed 24:00:00 (unlike Time type)
/// Source: GTFS Static reference.md
pub type LocalTime {
  LocalTime(hours: Int, minutes: Int, seconds: Int)
}

// =============================================================================
// Geographic Types
// =============================================================================

/// Geographic coordinate (WGS84)
/// Latitude: -90.0 to 90.0 (decimal degrees)
/// Longitude: -180.0 to 180.0 (decimal degrees)
/// Source: GTFS Static reference.md
pub type Coordinate {
  Coordinate(latitude: Float, longitude: Float)
}

// =============================================================================
// Color Type
// =============================================================================

/// Color as RGB values
/// Stored as separate R, G, B integers (0-255 each)
/// In GTFS files, colors are represented as 6-character hex strings
/// without the # prefix (e.g., "FFFFFF" for white, "000000" for black)
/// Source: GTFS Static reference.md
pub type Color {
  Color(red: Int, green: Int, blue: Int)
}

// =============================================================================
// Currency Types
// =============================================================================

/// ISO 4217 currency code (3 letters)
/// Examples: "USD", "EUR", "JPY"
/// Source: GTFS Static reference.md
pub type CurrencyCode {
  CurrencyCode(code: String)
}

/// Currency amount with proper decimal handling
/// Uses integer arithmetic to avoid floating-point precision issues
/// decimal_places indicates where the decimal point should be placed
/// Example: amount=199, decimal_places=2 represents 1.99
/// Source: GTFS Static reference.md
pub type CurrencyAmount {
  CurrencyAmount(amount: Int, decimal_places: Int)
}

// =============================================================================
// Language and Locale Types
// =============================================================================

/// BCP-47/IETF language code
/// Examples: "en", "en-US", "fr-CA", "zh-Hant"
/// Source: GTFS Static reference.md
pub type LanguageCode {
  LanguageCode(code: String)
}

/// IANA timezone identifier
/// Examples: "America/New_York", "Europe/London", "Asia/Tokyo"
/// Source: GTFS Static reference.md
pub type Timezone {
  Timezone(name: String)
}

// =============================================================================
// Field Presence Types
// =============================================================================

/// Presence requirement level for fields
/// Used for documentation and validation purposes
pub type Presence {
  /// Field must always be provided
  Required
  /// Field is optional
  Optional
  /// Field is required when a specific condition is met
  ConditionallyRequired(condition: String)
  /// Field must not be provided when a specific condition is met
  ConditionallyForbidden(condition: String)
  /// Field is recommended but not required
  Recommended
}

// =============================================================================
// URL Type
// =============================================================================

/// A fully qualified URL including http:// or https://
/// Source: GTFS Static reference.md
pub type Url {
  Url(value: String)
}

// =============================================================================
// Email Type
// =============================================================================

/// A valid email address
/// Source: GTFS Static reference.md
pub type Email {
  Email(value: String)
}

// =============================================================================
// Phone Number Type
// =============================================================================

/// A phone number string
/// Source: GTFS Static reference.md
pub type PhoneNumber {
  PhoneNumber(value: String)
}

// =============================================================================
// ID Types
// =============================================================================

/// A unique identifier string
/// Used for agency_id, route_id, trip_id, stop_id, etc.
pub type Id {
  Id(value: String)
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Create a new Date from year, month, and day components
pub fn date(year: Int, month: Int, day: Int) -> Date {
  Date(year: year, month: month, day: day)
}

/// Create a new Time from hours, minutes, and seconds
pub fn time(hours: Int, minutes: Int, seconds: Int) -> Time {
  Time(hours: hours, minutes: minutes, seconds: seconds)
}

/// Create a new LocalTime from hours, minutes, and seconds
pub fn local_time(hours: Int, minutes: Int, seconds: Int) -> LocalTime {
  LocalTime(hours: hours, minutes: minutes, seconds: seconds)
}

/// Create a new Coordinate from latitude and longitude
pub fn coordinate(latitude: Float, longitude: Float) -> Coordinate {
  Coordinate(latitude: latitude, longitude: longitude)
}

/// Create a new Color from red, green, and blue components (0-255)
pub fn color(red: Int, green: Int, blue: Int) -> Color {
  Color(red: red, green: green, blue: blue)
}

/// Create a Color from a hex string (with or without # prefix)
/// Returns None if the string is not a valid hex color
pub fn color_from_hex(hex: String) -> Option(Color) {
  let hex = case hex {
    "#" <> rest -> rest
    other -> other
  }

  case string.length(hex) {
    6 -> {
      let chars = string.to_graphemes(hex)
      case chars {
        [r1, r2, g1, g2, b1, b2] -> {
          case
            hex_char_to_int(r1),
            hex_char_to_int(r2),
            hex_char_to_int(g1),
            hex_char_to_int(g2),
            hex_char_to_int(b1),
            hex_char_to_int(b2)
          {
            Ok(r1v), Ok(r2v), Ok(g1v), Ok(g2v), Ok(b1v), Ok(b2v) -> {
              let r = r1v * 16 + r2v
              let g = g1v * 16 + g2v
              let b = b1v * 16 + b2v
              option.Some(Color(red: r, green: g, blue: b))
            }
            _, _, _, _, _, _ -> option.None
          }
        }
        _ -> option.None
      }
    }
    _ -> option.None
  }
}

fn hex_char_to_int(char: String) -> Result(Int, Nil) {
  case char {
    "0" -> Ok(0)
    "1" -> Ok(1)
    "2" -> Ok(2)
    "3" -> Ok(3)
    "4" -> Ok(4)
    "5" -> Ok(5)
    "6" -> Ok(6)
    "7" -> Ok(7)
    "8" -> Ok(8)
    "9" -> Ok(9)
    "A" | "a" -> Ok(10)
    "B" | "b" -> Ok(11)
    "C" | "c" -> Ok(12)
    "D" | "d" -> Ok(13)
    "E" | "e" -> Ok(14)
    "F" | "f" -> Ok(15)
    _ -> Error(Nil)
  }
}

/// Create a new CurrencyCode
pub fn currency_code(code: String) -> CurrencyCode {
  CurrencyCode(code: code)
}

/// Create a new CurrencyAmount
pub fn currency_amount(amount: Int, decimal_places: Int) -> CurrencyAmount {
  CurrencyAmount(amount: amount, decimal_places: decimal_places)
}

/// Create a new LanguageCode
pub fn language_code(code: String) -> LanguageCode {
  LanguageCode(code: code)
}

/// Create a new Timezone
pub fn timezone(name: String) -> Timezone {
  Timezone(name: name)
}

/// Create a new Url
pub fn url(value: String) -> Url {
  Url(value: value)
}

/// Create a new Email
pub fn email(value: String) -> Email {
  Email(value: value)
}

/// Create a new PhoneNumber
pub fn phone_number(value: String) -> PhoneNumber {
  PhoneNumber(value: value)
}

/// Create a new Id
pub fn id(value: String) -> Id {
  Id(value: value)
}

/// Convert a Time to total seconds from midnight
/// Useful for comparing times or calculating durations
pub fn time_to_seconds(t: Time) -> Int {
  t.hours * 3600 + t.minutes * 60 + t.seconds
}

/// Convert seconds from midnight to a Time
pub fn seconds_to_time(seconds: Int) -> Time {
  let hours = seconds / 3600
  let remaining = seconds % 3600
  let minutes = remaining / 60
  let secs = remaining % 60
  Time(hours: hours, minutes: minutes, seconds: secs)
}

/// Check if a coordinate is within valid WGS84 bounds
pub fn is_valid_coordinate(coord: Coordinate) -> Bool {
  coord.latitude >=. -90.0
  && coord.latitude <=. 90.0
  && coord.longitude >=. -180.0
  && coord.longitude <=. 180.0
}

/// Check if a color has valid RGB values (0-255)
pub fn is_valid_color(c: Color) -> Bool {
  c.red >= 0
  && c.red <= 255
  && c.green >= 0
  && c.green <= 255
  && c.blue >= 0
  && c.blue <= 255
}
