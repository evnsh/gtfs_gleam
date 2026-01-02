//// Parser for fare_leg_join_rules.txt
////
//// fare_leg_join_rules.txt - Rules for defining effective fare legs.
//// Defines when two or more legs should be considered as a single
//// effective fare leg for matching against fare_leg_rules.txt.
//// Source: GTFS reference.md - Dataset Files > fare_leg_join_rules.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type FareLegJoinRule, FareLegJoinRule}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_leg_join_rules.txt CSV content into a list of FareLegJoinRule records
pub fn parse(content: String) -> Result(List(FareLegJoinRule), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareLegJoinRule),
) -> Result(List(FareLegJoinRule), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use rule <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [rule, ..acc])
    }
  }
}

fn parse_row(
  row: CsvRow,
  row_num: Int,
) -> Result(FareLegJoinRule, csv.ParseError) {
  // Required fields
  use from_network_id <- result.try(csv.get_required(
    row,
    "from_network_id",
    row_num,
  ))
  use to_network_id <- result.try(csv.get_required(
    row,
    "to_network_id",
    row_num,
  ))

  // Conditionally required / optional fields
  let from_stop_id = csv.get_optional(row, "from_stop_id")
  let to_stop_id = csv.get_optional(row, "to_stop_id")

  Ok(FareLegJoinRule(
    from_network_id: from_network_id,
    to_network_id: to_network_id,
    from_stop_id: from_stop_id,
    to_stop_id: to_stop_id,
  ))
}
