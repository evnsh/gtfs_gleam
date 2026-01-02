//// Parser for frequencies.txt
////
//// frequencies.txt - Headway (time between trips) for routes with variable frequency.
//// Source: GTFS reference.md - Dataset Files > frequencies.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/time
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type ExactTimes, type Frequency, Frequency, FrequencyBased, ScheduleBased,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse frequencies.txt CSV content into a list of Frequency records
pub fn parse(content: String) -> Result(List(Frequency), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Frequency),
) -> Result(List(Frequency), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use freq <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [freq, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Frequency, csv.ParseError) {
  // Required fields
  use trip_id <- result.try(csv.get_required(row, "trip_id", row_num))
  use start_time <- result.try(csv.get_required_parsed(
    row,
    "start_time",
    row_num,
    time.parse_time,
  ))
  use end_time <- result.try(csv.get_required_parsed(
    row,
    "end_time",
    row_num,
    time.parse_time,
  ))
  use headway_secs <- result.try(csv.get_required_parsed(
    row,
    "headway_secs",
    row_num,
    csv.parse_int,
  ))

  // Optional fields
  let exact_times =
    csv.get_optional(row, "exact_times")
    |> option.map(parse_exact_times)
    |> option.flatten
    |> option.unwrap(FrequencyBased)

  Ok(Frequency(
    trip_id: trip_id,
    start_time: start_time,
    end_time: end_time,
    headway_secs: headway_secs,
    exact_times: exact_times,
  ))
}

fn parse_exact_times(s: String) -> option.Option(ExactTimes) {
  case s {
    "" | "0" -> option.Some(FrequencyBased)
    "1" -> option.Some(ScheduleBased)
    _ -> option.None
  }
}
