//// Time and Date parsing utilities for GTFS
////
//// GTFS uses special time handling where times can exceed 24:00:00
//// to indicate service that continues past midnight into the next
//// calendar day but is still part of the same "service day".
////
//// Source: GTFS reference.md - Field Types

import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import gtfs/common/types.{
  type Date, type LocalTime, type Time, Date, LocalTime, Time,
}

// =============================================================================
// Time Parsing
// =============================================================================

/// Parse a GTFS time string (HH:MM:SS or H:MM:SS format)
/// Times can exceed 24:00:00 for overnight service
/// Examples: "08:30:00", "25:35:00" (1:35 AM next day, same service day)
pub fn parse_time(value: String) -> Result(Time, String) {
  case string.split(value, ":") {
    [hours_str, minutes_str, seconds_str] -> {
      use hours <- result.try(
        int.parse(hours_str) |> result.replace_error("invalid hours"),
      )
      use minutes <- result.try(
        int.parse(minutes_str) |> result.replace_error("invalid minutes"),
      )
      use seconds <- result.try(
        int.parse(seconds_str) |> result.replace_error("invalid seconds"),
      )

      // Validate ranges (hours can exceed 24, minutes/seconds must be 0-59)
      case
        hours >= 0
        && minutes >= 0
        && minutes < 60
        && seconds >= 0
        && seconds < 60
      {
        True -> Ok(Time(hours: hours, minutes: minutes, seconds: seconds))
        False -> Error("time values out of range")
      }
    }
    _ -> Error("time format HH:MM:SS")
  }
}

/// Parse an optional GTFS time string
pub fn parse_time_optional(value: String) -> Result(Option(Time), String) {
  case value {
    "" -> Ok(None)
    v -> parse_time(v) |> result.map(Some)
  }
}

/// Parse a local time (wall-clock time that cannot exceed 24:00:00)
pub fn parse_local_time(value: String) -> Result(LocalTime, String) {
  case string.split(value, ":") {
    [hours_str, minutes_str, seconds_str] -> {
      use hours <- result.try(
        int.parse(hours_str) |> result.replace_error("invalid hours"),
      )
      use minutes <- result.try(
        int.parse(minutes_str) |> result.replace_error("invalid minutes"),
      )
      use seconds <- result.try(
        int.parse(seconds_str) |> result.replace_error("invalid seconds"),
      )

      // Local time cannot exceed 24:00:00
      case
        hours >= 0
        && hours < 24
        && minutes >= 0
        && minutes < 60
        && seconds >= 0
        && seconds < 60
      {
        True -> Ok(LocalTime(hours: hours, minutes: minutes, seconds: seconds))
        False -> Error("local time values out of range (must be < 24:00:00)")
      }
    }
    _ -> Error("time format HH:MM:SS")
  }
}

// =============================================================================
// Date Parsing
// =============================================================================

/// Parse a GTFS date string (YYYYMMDD format)
/// Example: "20251028" -> Date(year: 2025, month: 10, day: 28)
pub fn parse_date(value: String) -> Result(Date, String) {
  case string.length(value) {
    8 -> {
      use year <- result.try(
        int.parse(string.slice(value, 0, 4))
        |> result.replace_error("invalid year"),
      )
      use month <- result.try(
        int.parse(string.slice(value, 4, 2))
        |> result.replace_error("invalid month"),
      )
      use day <- result.try(
        int.parse(string.slice(value, 6, 2))
        |> result.replace_error("invalid day"),
      )

      // Basic validation
      case month >= 1 && month <= 12 && day >= 1 && day <= 31 {
        True -> Ok(Date(year: year, month: month, day: day))
        False -> Error("date values out of range")
      }
    }
    _ -> Error("date format YYYYMMDD")
  }
}

/// Parse an optional GTFS date string
pub fn parse_date_optional(value: String) -> Result(Option(Date), String) {
  case value {
    "" -> Ok(None)
    v -> parse_date(v) |> result.map(Some)
  }
}

// =============================================================================
// Time Operations
// =============================================================================

/// Convert a Time to total seconds from midnight
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

/// Compare two times, returning:
/// - Lt if a < b
/// - Eq if a == b
/// - Gt if a > b
pub fn compare_time(a: Time, b: Time) -> order.Order {
  int.compare(time_to_seconds(a), time_to_seconds(b))
}

/// Check if time a is before time b
pub fn is_before(a: Time, b: Time) -> Bool {
  time_to_seconds(a) < time_to_seconds(b)
}

/// Check if time a is after time b
pub fn is_after(a: Time, b: Time) -> Bool {
  time_to_seconds(a) > time_to_seconds(b)
}

/// Calculate the difference between two times in seconds
/// Returns a positive value if a > b, negative if a < b
pub fn time_difference(a: Time, b: Time) -> Int {
  time_to_seconds(a) - time_to_seconds(b)
}

/// Add seconds to a time
pub fn add_seconds(t: Time, seconds: Int) -> Time {
  seconds_to_time(time_to_seconds(t) + seconds)
}

/// Normalize a time to within a 24-hour period
/// Example: 25:30:00 -> 01:30:00
pub fn normalize_time(t: Time) -> Time {
  let total_seconds = time_to_seconds(t)
  let normalized = total_seconds % { 24 * 3600 }
  seconds_to_time(normalized)
}

/// Check if a time crosses midnight (hours >= 24)
pub fn crosses_midnight(t: Time) -> Bool {
  t.hours >= 24
}

/// Get the calendar day offset for a time
/// Returns 0 for times < 24:00:00, 1 for 24:00:00-47:59:59, etc.
pub fn day_offset(t: Time) -> Int {
  t.hours / 24
}

// =============================================================================
// Time Formatting
// =============================================================================

/// Format a Time as HH:MM:SS string
pub fn format_time(t: Time) -> String {
  pad_int(t.hours, 2)
  <> ":"
  <> pad_int(t.minutes, 2)
  <> ":"
  <> pad_int(t.seconds, 2)
}

/// Format a LocalTime as HH:MM:SS string
pub fn format_local_time(t: LocalTime) -> String {
  pad_int(t.hours, 2)
  <> ":"
  <> pad_int(t.minutes, 2)
  <> ":"
  <> pad_int(t.seconds, 2)
}

/// Format a Date as YYYYMMDD string
pub fn format_date(d: Date) -> String {
  pad_int(d.year, 4) <> pad_int(d.month, 2) <> pad_int(d.day, 2)
}

/// Format a Date in human-readable ISO format (YYYY-MM-DD)
pub fn format_date_iso(d: Date) -> String {
  pad_int(d.year, 4) <> "-" <> pad_int(d.month, 2) <> "-" <> pad_int(d.day, 2)
}

// =============================================================================
// Date Operations
// =============================================================================

/// Compare two dates
pub fn compare_date(a: Date, b: Date) -> order.Order {
  case int.compare(a.year, b.year) {
    order.Eq -> {
      case int.compare(a.month, b.month) {
        order.Eq -> int.compare(a.day, b.day)
        other -> other
      }
    }
    other -> other
  }
}

/// Check if date a is before date b
pub fn date_is_before(a: Date, b: Date) -> Bool {
  compare_date(a, b) == order.Lt
}

/// Check if date a is after date b
pub fn date_is_after(a: Date, b: Date) -> Bool {
  compare_date(a, b) == order.Gt
}

/// Check if a date is within a range (inclusive)
pub fn date_in_range(date: Date, start: Date, end: Date) -> Bool {
  !date_is_before(date, start) && !date_is_after(date, end)
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Pad an integer with leading zeros to the specified width
fn pad_int(n: Int, width: Int) -> String {
  let s = int.to_string(n)
  let len = string.length(s)
  case len < width {
    True -> string.repeat("0", width - len) <> s
    False -> s
  }
}
