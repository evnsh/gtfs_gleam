//// Time and Date Parsing Tests
////
//// Tests for GTFS time utilities including support for times > 24:00:00

import gleam/order
import gleeunit/should
import gtfs/common/time
import gtfs/common/types.{Date, LocalTime, Time}

// =============================================================================
// Time Parsing Tests
// =============================================================================

pub fn parse_standard_time_test() {
  let assert Ok(t) = time.parse_time("08:30:00")
  t |> should.equal(Time(hours: 8, minutes: 30, seconds: 0))
}

pub fn parse_midnight_test() {
  let assert Ok(t) = time.parse_time("00:00:00")
  t |> should.equal(Time(hours: 0, minutes: 0, seconds: 0))
}

pub fn parse_end_of_day_test() {
  let assert Ok(t) = time.parse_time("23:59:59")
  t |> should.equal(Time(hours: 23, minutes: 59, seconds: 59))
}

pub fn parse_time_exceeding_24_hours_test() {
  // GTFS allows times > 24:00:00 for overnight service
  let assert Ok(t) = time.parse_time("25:30:00")
  t |> should.equal(Time(hours: 25, minutes: 30, seconds: 0))
}

pub fn parse_time_26_hours_test() {
  let assert Ok(t) = time.parse_time("26:00:00")
  t |> should.equal(Time(hours: 26, minutes: 0, seconds: 0))
}

pub fn parse_time_48_hours_test() {
  // Edge case: very long overnight service
  let assert Ok(t) = time.parse_time("48:00:00")
  t |> should.equal(Time(hours: 48, minutes: 0, seconds: 0))
}

pub fn parse_single_digit_hour_test() {
  let assert Ok(t) = time.parse_time("8:30:00")
  t |> should.equal(Time(hours: 8, minutes: 30, seconds: 0))
}

pub fn parse_time_invalid_format_test() {
  time.parse_time("8:30") |> should.be_error()
  time.parse_time("08-30-00") |> should.be_error()
  time.parse_time("invalid") |> should.be_error()
}

pub fn parse_time_invalid_minutes_test() {
  time.parse_time("08:60:00") |> should.be_error()
  time.parse_time("08:99:00") |> should.be_error()
}

pub fn parse_time_invalid_seconds_test() {
  time.parse_time("08:30:60") |> should.be_error()
  time.parse_time("08:30:99") |> should.be_error()
}

pub fn parse_time_negative_test() {
  time.parse_time("-01:00:00") |> should.be_error()
}

// =============================================================================
// Local Time Parsing Tests
// =============================================================================

pub fn parse_local_time_test() {
  let assert Ok(t) = time.parse_local_time("08:30:00")
  t |> should.equal(LocalTime(hours: 8, minutes: 30, seconds: 0))
}

pub fn parse_local_time_cannot_exceed_24_test() {
  // Local time (wall-clock) cannot exceed 24:00:00
  time.parse_local_time("25:00:00") |> should.be_error()
}

pub fn parse_local_time_23_59_59_test() {
  let assert Ok(t) = time.parse_local_time("23:59:59")
  t |> should.equal(LocalTime(hours: 23, minutes: 59, seconds: 59))
}

// =============================================================================
// Date Parsing Tests
// =============================================================================

pub fn parse_date_test() {
  let assert Ok(d) = time.parse_date("20251028")
  d |> should.equal(Date(year: 2025, month: 10, day: 28))
}

pub fn parse_date_january_test() {
  let assert Ok(d) = time.parse_date("20250101")
  d |> should.equal(Date(year: 2025, month: 1, day: 1))
}

pub fn parse_date_december_test() {
  let assert Ok(d) = time.parse_date("20251231")
  d |> should.equal(Date(year: 2025, month: 12, day: 31))
}

pub fn parse_date_invalid_format_test() {
  time.parse_date("2025-10-28") |> should.be_error()
  time.parse_date("10/28/2025") |> should.be_error()
  time.parse_date("invalid") |> should.be_error()
}

pub fn parse_date_invalid_month_test() {
  time.parse_date("20251328") |> should.be_error()
  time.parse_date("20250028") |> should.be_error()
}

pub fn parse_date_invalid_day_test() {
  time.parse_date("20251032") |> should.be_error()
  time.parse_date("20251000") |> should.be_error()
}

pub fn parse_date_too_short_test() {
  time.parse_date("2025102") |> should.be_error()
}

// =============================================================================
// Time to Seconds Conversion Tests
// =============================================================================

pub fn time_to_seconds_midnight_test() {
  let t = Time(hours: 0, minutes: 0, seconds: 0)
  time.time_to_seconds(t) |> should.equal(0)
}

pub fn time_to_seconds_one_hour_test() {
  let t = Time(hours: 1, minutes: 0, seconds: 0)
  time.time_to_seconds(t) |> should.equal(3600)
}

pub fn time_to_seconds_complex_test() {
  let t = Time(hours: 8, minutes: 30, seconds: 45)
  // 8*3600 + 30*60 + 45 = 28800 + 1800 + 45 = 30645
  time.time_to_seconds(t) |> should.equal(30_645)
}

pub fn time_to_seconds_overnight_test() {
  let t = Time(hours: 25, minutes: 30, seconds: 0)
  // 25*3600 + 30*60 = 90000 + 1800 = 91800
  time.time_to_seconds(t) |> should.equal(91_800)
}

// =============================================================================
// Seconds to Time Conversion Tests
// =============================================================================

pub fn seconds_to_time_zero_test() {
  time.seconds_to_time(0)
  |> should.equal(Time(hours: 0, minutes: 0, seconds: 0))
}

pub fn seconds_to_time_one_hour_test() {
  time.seconds_to_time(3600)
  |> should.equal(Time(hours: 1, minutes: 0, seconds: 0))
}

pub fn seconds_to_time_complex_test() {
  time.seconds_to_time(30_645)
  |> should.equal(Time(hours: 8, minutes: 30, seconds: 45))
}

pub fn seconds_to_time_overnight_test() {
  // Should handle > 86400 seconds (more than 24 hours)
  time.seconds_to_time(91_800)
  |> should.equal(Time(hours: 25, minutes: 30, seconds: 0))
}

// =============================================================================
// Time Comparison Tests
// =============================================================================

pub fn compare_time_equal_test() {
  let t1 = Time(hours: 8, minutes: 30, seconds: 0)
  let t2 = Time(hours: 8, minutes: 30, seconds: 0)
  time.compare_time(t1, t2) |> should.equal(order.Eq)
}

pub fn compare_time_less_test() {
  let t1 = Time(hours: 8, minutes: 30, seconds: 0)
  let t2 = Time(hours: 9, minutes: 0, seconds: 0)
  time.compare_time(t1, t2) |> should.equal(order.Lt)
}

pub fn compare_time_greater_test() {
  let t1 = Time(hours: 10, minutes: 0, seconds: 0)
  let t2 = Time(hours: 9, minutes: 30, seconds: 0)
  time.compare_time(t1, t2) |> should.equal(order.Gt)
}

pub fn compare_time_overnight_test() {
  let t1 = Time(hours: 25, minutes: 0, seconds: 0)
  let t2 = Time(hours: 24, minutes: 30, seconds: 0)
  time.compare_time(t1, t2) |> should.equal(order.Gt)
}

// =============================================================================
// Add Seconds Tests
// =============================================================================

pub fn add_seconds_simple_test() {
  let t = Time(hours: 8, minutes: 30, seconds: 0)
  time.add_seconds(t, 60)
  |> should.equal(Time(hours: 8, minutes: 31, seconds: 0))
}

pub fn add_seconds_hour_rollover_test() {
  let t = Time(hours: 8, minutes: 59, seconds: 0)
  time.add_seconds(t, 120)
  |> should.equal(Time(hours: 9, minutes: 1, seconds: 0))
}

pub fn add_seconds_overnight_test() {
  let t = Time(hours: 23, minutes: 30, seconds: 0)
  time.add_seconds(t, 7200)
  |> should.equal(Time(hours: 25, minutes: 30, seconds: 0))
}

// =============================================================================
// Date Formatting Tests
// =============================================================================

pub fn format_date_test() {
  let d = Date(year: 2025, month: 10, day: 28)
  time.format_date(d) |> should.equal("20251028")
}

pub fn format_date_january_test() {
  let d = Date(year: 2025, month: 1, day: 5)
  time.format_date(d) |> should.equal("20250105")
}

// =============================================================================
// Time Formatting Tests
// =============================================================================

pub fn format_time_test() {
  let t = Time(hours: 8, minutes: 30, seconds: 0)
  time.format_time(t) |> should.equal("08:30:00")
}

pub fn format_time_overnight_test() {
  let t = Time(hours: 25, minutes: 5, seconds: 9)
  time.format_time(t) |> should.equal("25:05:09")
}
