//// Parser for booking_rules.txt
////
//// booking_rules.txt - Defines booking rules for flex trips.
//// Source: GTFS reference.md - Dataset Files > booking_rules.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/time
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type BookingRule, type BookingType, BookingRule, PriorDayBooking,
  RealTimeBooking, SameDayBooking,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse booking_rules.txt CSV content into a list of BookingRule records
pub fn parse(content: String) -> Result(List(BookingRule), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(BookingRule),
) -> Result(List(BookingRule), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use rule <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [rule, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(BookingRule, csv.ParseError) {
  // Required fields
  use booking_rule_id <- result.try(csv.get_required(
    row,
    "booking_rule_id",
    row_num,
  ))
  use booking_type <- result.try(csv.get_required_parsed(
    row,
    "booking_type",
    row_num,
    parse_booking_type,
  ))

  // Conditionally required/forbidden fields
  let prior_notice_duration_min =
    parse_optional_int(row, "prior_notice_duration_min")
  let prior_notice_duration_max =
    parse_optional_int(row, "prior_notice_duration_max")
  let prior_notice_last_day = parse_optional_int(row, "prior_notice_last_day")
  let prior_notice_last_time =
    csv.get_optional(row, "prior_notice_last_time")
    |> option.then(fn(s) {
      case time.parse_time(s) {
        Ok(t) -> option.Some(t)
        Error(_) -> option.None
      }
    })
  let prior_notice_start_day = parse_optional_int(row, "prior_notice_start_day")
  let prior_notice_start_time =
    csv.get_optional(row, "prior_notice_start_time")
    |> option.then(fn(s) {
      case time.parse_time(s) {
        Ok(t) -> option.Some(t)
        Error(_) -> option.None
      }
    })
  let prior_notice_service_id = csv.get_optional(row, "prior_notice_service_id")

  // Optional fields
  let message = csv.get_optional(row, "message")
  let pickup_message = csv.get_optional(row, "pickup_message")
  let drop_off_message = csv.get_optional(row, "drop_off_message")
  let phone_number =
    csv.get_optional(row, "phone_number") |> option.map(common.PhoneNumber)
  let info_url = csv.get_optional(row, "info_url") |> option.map(common.Url)
  let booking_url =
    csv.get_optional(row, "booking_url") |> option.map(common.Url)

  Ok(BookingRule(
    booking_rule_id: booking_rule_id,
    booking_type: booking_type,
    prior_notice_duration_min: prior_notice_duration_min,
    prior_notice_duration_max: prior_notice_duration_max,
    prior_notice_last_day: prior_notice_last_day,
    prior_notice_last_time: prior_notice_last_time,
    prior_notice_start_day: prior_notice_start_day,
    prior_notice_start_time: prior_notice_start_time,
    prior_notice_service_id: prior_notice_service_id,
    message: message,
    pickup_message: pickup_message,
    drop_off_message: drop_off_message,
    phone_number: phone_number,
    info_url: info_url,
    booking_url: booking_url,
  ))
}

fn parse_booking_type(s: String) -> Result(BookingType, String) {
  case s {
    "0" -> Ok(RealTimeBooking)
    "1" -> Ok(SameDayBooking)
    "2" -> Ok(PriorDayBooking)
    _ -> Error("Invalid booking_type value: " <> s)
  }
}

fn parse_optional_int(row: CsvRow, field: String) -> option.Option(Int) {
  csv.get_optional(row, field)
  |> option.then(fn(s) {
    case csv.parse_int(s) {
      Ok(i) -> option.Some(i)
      Error(_) -> option.None
    }
  })
}
