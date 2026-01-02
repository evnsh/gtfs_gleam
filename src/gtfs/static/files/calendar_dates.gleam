//// Parser for calendar_dates.txt
////
//// calendar_dates.txt - Exceptions for the services defined in
//// calendar.txt. Used to add or remove service on specific dates.
//// Source: GTFS reference.md - Dataset Files > calendar_dates.txt

import gleam/list
import gleam/result
import gtfs/common/time
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type CalendarDate, type ExceptionType, CalendarDate, ServiceAdded,
  ServiceRemoved,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse calendar_dates.txt CSV content into a list of CalendarDate records
pub fn parse(content: String) -> Result(List(CalendarDate), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(CalendarDate),
) -> Result(List(CalendarDate), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use calendar_date <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [calendar_date, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(CalendarDate, csv.ParseError) {
  // All fields are required
  use service_id <- result.try(csv.get_required(row, "service_id", row_num))
  use date <- result.try(csv.get_required_parsed(
    row,
    "date",
    row_num,
    time.parse_date,
  ))
  use exception_type <- result.try(csv.get_required_parsed(
    row,
    "exception_type",
    row_num,
    parse_exception_type,
  ))

  Ok(CalendarDate(
    service_id: service_id,
    date: date,
    exception_type: exception_type,
  ))
}

// =============================================================================
// Enum Parsers
// =============================================================================

fn parse_exception_type(value: String) -> Result(ExceptionType, String) {
  case value {
    "1" -> Ok(ServiceAdded)
    "2" -> Ok(ServiceRemoved)
    _ -> Error("exception_type (1 or 2)")
  }
}
