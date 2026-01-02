//// Parser for calendar.txt
////
//// calendar.txt - Service dates specified using a weekly schedule
//// with start and end dates.
//// Source: GTFS reference.md - Dataset Files > calendar.txt

import gleam/list
import gleam/result
import gtfs/common/time
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type Calendar, Calendar}

// =============================================================================
// Parsing
// =============================================================================

/// Parse calendar.txt CSV content into a list of Calendar records
pub fn parse(content: String) -> Result(List(Calendar), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Calendar),
) -> Result(List(Calendar), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use calendar <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [calendar, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Calendar, csv.ParseError) {
  // Required fields
  use service_id <- result.try(csv.get_required(row, "service_id", row_num))

  // Parse day of week fields (required, 0 or 1)
  use monday <- result.try(csv.get_required_parsed(
    row,
    "monday",
    row_num,
    csv.parse_bool,
  ))
  use tuesday <- result.try(csv.get_required_parsed(
    row,
    "tuesday",
    row_num,
    csv.parse_bool,
  ))
  use wednesday <- result.try(csv.get_required_parsed(
    row,
    "wednesday",
    row_num,
    csv.parse_bool,
  ))
  use thursday <- result.try(csv.get_required_parsed(
    row,
    "thursday",
    row_num,
    csv.parse_bool,
  ))
  use friday <- result.try(csv.get_required_parsed(
    row,
    "friday",
    row_num,
    csv.parse_bool,
  ))
  use saturday <- result.try(csv.get_required_parsed(
    row,
    "saturday",
    row_num,
    csv.parse_bool,
  ))
  use sunday <- result.try(csv.get_required_parsed(
    row,
    "sunday",
    row_num,
    csv.parse_bool,
  ))

  // Parse dates (required)
  use start_date <- result.try(csv.get_required_parsed(
    row,
    "start_date",
    row_num,
    time.parse_date,
  ))
  use end_date <- result.try(csv.get_required_parsed(
    row,
    "end_date",
    row_num,
    time.parse_date,
  ))

  Ok(Calendar(
    service_id: service_id,
    monday: monday,
    tuesday: tuesday,
    wednesday: wednesday,
    thursday: thursday,
    friday: friday,
    saturday: saturday,
    sunday: sunday,
    start_date: start_date,
    end_date: end_date,
  ))
}
