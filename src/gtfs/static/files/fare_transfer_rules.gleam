//// Parser for fare_transfer_rules.txt
////
//// fare_transfer_rules.txt - Fare rules for transfers between legs of travel.
//// Source: GTFS reference.md - Dataset Files > fare_transfer_rules.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type DurationLimitType, type FareTransferRule, type FareTransferType,
  BetweenLegs, BetweenStartAndEnd, BetweenStartTimes, FareTransferRule,
  SumOfLegs, SumPlusTransfer, SumPlusTransferCapped,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_transfer_rules.txt CSV content into a list of FareTransferRule records
pub fn parse(content: String) -> Result(List(FareTransferRule), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareTransferRule),
) -> Result(List(FareTransferRule), csv.ParseError) {
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
) -> Result(FareTransferRule, csv.ParseError) {
  // Required field
  use fare_transfer_type <- result.try(csv.get_required_parsed(
    row,
    "fare_transfer_type",
    row_num,
    parse_fare_transfer_type,
  ))

  // Optional fields
  let from_leg_group_id = csv.get_optional(row, "from_leg_group_id")
  let to_leg_group_id = csv.get_optional(row, "to_leg_group_id")
  let transfer_count = parse_optional_int(row, "transfer_count")
  let duration_limit = parse_optional_int(row, "duration_limit")
  let duration_limit_type =
    csv.get_optional(row, "duration_limit_type")
    |> option.then(fn(s) {
      case parse_duration_limit_type(s) {
        Ok(t) -> option.Some(t)
        Error(_) -> option.None
      }
    })
  let fare_product_id = csv.get_optional(row, "fare_product_id")

  Ok(FareTransferRule(
    from_leg_group_id: from_leg_group_id,
    to_leg_group_id: to_leg_group_id,
    transfer_count: transfer_count,
    duration_limit: duration_limit,
    duration_limit_type: duration_limit_type,
    fare_transfer_type: fare_transfer_type,
    fare_product_id: fare_product_id,
  ))
}

fn parse_fare_transfer_type(s: String) -> Result(FareTransferType, String) {
  case s {
    "0" -> Ok(SumPlusTransfer)
    "1" -> Ok(SumPlusTransferCapped)
    "2" -> Ok(SumOfLegs)
    _ -> Error("Invalid fare_transfer_type value: " <> s)
  }
}

fn parse_duration_limit_type(s: String) -> Result(DurationLimitType, String) {
  case s {
    "0" -> Ok(BetweenLegs)
    "1" -> Ok(BetweenStartTimes)
    "2" -> Ok(BetweenStartAndEnd)
    _ -> Error("Invalid duration_limit_type value: " <> s)
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
