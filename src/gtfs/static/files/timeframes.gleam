//// Parser for timeframes.txt
////
//// timeframes.txt - Date and time periods to use in fare rules for fares that depend on date and time factors.
//// Source: GTFS reference.md - Dataset Files > timeframes.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/time
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type Timeframe, Timeframe}

// =============================================================================
// Parsing
// =============================================================================

/// Parse timeframes.txt CSV content into a list of Timeframe records
pub fn parse(content: String) -> Result(List(Timeframe), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Timeframe),
) -> Result(List(Timeframe), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use timeframe <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [timeframe, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Timeframe, csv.ParseError) {
  // Required fields
  use timeframe_group_id <- result.try(csv.get_required(
    row,
    "timeframe_group_id",
    row_num,
  ))
  use service_id <- result.try(csv.get_required(row, "service_id", row_num))

  // Conditionally required fields
  let start_time =
    csv.get_optional(row, "start_time")
    |> option.then(fn(s) {
      case time.parse_time(s) {
        Ok(t) -> option.Some(t)
        Error(_) -> option.None
      }
    })
  let end_time =
    csv.get_optional(row, "end_time")
    |> option.then(fn(s) {
      case time.parse_time(s) {
        Ok(t) -> option.Some(t)
        Error(_) -> option.None
      }
    })

  Ok(Timeframe(
    timeframe_group_id: timeframe_group_id,
    start_time: start_time,
    end_time: end_time,
    service_id: service_id,
  ))
}
