//// Parser for fare_leg_rules.txt
////
//// fare_leg_rules.txt - Fare rules for individual legs of travel.
//// Source: GTFS reference.md - Dataset Files > fare_leg_rules.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type FareLegRule, FareLegRule}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_leg_rules.txt CSV content into a list of FareLegRule records
pub fn parse(content: String) -> Result(List(FareLegRule), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareLegRule),
) -> Result(List(FareLegRule), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use rule <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [rule, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(FareLegRule, csv.ParseError) {
  // Required field
  use fare_product_id <- result.try(csv.get_required(
    row,
    "fare_product_id",
    row_num,
  ))

  // Optional fields
  let leg_group_id = csv.get_optional(row, "leg_group_id")
  let network_id = csv.get_optional(row, "network_id")
  let from_area_id = csv.get_optional(row, "from_area_id")
  let to_area_id = csv.get_optional(row, "to_area_id")
  let from_timeframe_group_id = csv.get_optional(row, "from_timeframe_group_id")
  let to_timeframe_group_id = csv.get_optional(row, "to_timeframe_group_id")
  let rule_priority = parse_optional_int(row, "rule_priority")

  Ok(FareLegRule(
    leg_group_id: leg_group_id,
    network_id: network_id,
    from_area_id: from_area_id,
    to_area_id: to_area_id,
    from_timeframe_group_id: from_timeframe_group_id,
    to_timeframe_group_id: to_timeframe_group_id,
    fare_product_id: fare_product_id,
    rule_priority: rule_priority,
  ))
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
