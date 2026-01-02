//// Parser for fare_attributes.txt
////
//// fare_attributes.txt - Fare information for the agency's routes.
//// Source: GTFS reference.md - Dataset Files > fare_attributes.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type FareAttribute, type PaymentMethod, type TransferPolicy, FareAttribute,
  NoTransfers, OneTransfer, PayBeforeBoarding, PayOnBoard, TwoTransfers,
  UnlimitedTransfers,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_attributes.txt CSV content into a list of FareAttribute records
pub fn parse(content: String) -> Result(List(FareAttribute), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareAttribute),
) -> Result(List(FareAttribute), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use fare <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [fare, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(FareAttribute, csv.ParseError) {
  // Required fields
  use fare_id <- result.try(csv.get_required(row, "fare_id", row_num))
  use price <- result.try(csv.get_required_parsed(
    row,
    "price",
    row_num,
    parse_currency_amount,
  ))
  use currency_type <- result.try(csv.get_required(
    row,
    "currency_type",
    row_num,
  ))
  use payment_method <- result.try(csv.get_required_parsed(
    row,
    "payment_method",
    row_num,
    parse_payment_method,
  ))
  use transfers <- result.try(csv.get_parsed(
    row,
    "transfers",
    row_num,
    parse_transfer_policy,
  ))

  // Optional fields
  let agency_id = csv.get_optional(row, "agency_id")
  let transfer_duration =
    csv.get_optional(row, "transfer_duration")
    |> option.then(fn(s) {
      case csv.parse_int(s) {
        Ok(i) -> option.Some(i)
        Error(_) -> option.None
      }
    })

  Ok(FareAttribute(
    fare_id: fare_id,
    price: price,
    currency_type: common.CurrencyCode(currency_type),
    payment_method: payment_method,
    transfers: option.unwrap(transfers, UnlimitedTransfers),
    agency_id: agency_id,
    transfer_duration: transfer_duration,
  ))
}

fn parse_currency_amount(s: String) -> Result(common.CurrencyAmount, String) {
  // Parse price string like "2.50" into CurrencyAmount
  case csv.parse_float(s) {
    Ok(f) -> {
      // Convert float to integer representation (cents)
      let cents = float_to_cents(f)
      Ok(common.CurrencyAmount(cents, 2))
    }
    Error(_) -> Error("Invalid price format")
  }
}

fn float_to_cents(f: Float) -> Int {
  // Multiply by 100 and round to nearest integer
  let scaled = f *. 100.0
  float_round(scaled)
}

@external(erlang, "erlang", "round")
fn float_round(f: Float) -> Int

fn parse_payment_method(s: String) -> Result(PaymentMethod, String) {
  case s {
    "0" -> Ok(PayOnBoard)
    "1" -> Ok(PayBeforeBoarding)
    _ -> Error("Invalid payment_method value: " <> s)
  }
}

fn parse_transfer_policy(s: String) -> Result(TransferPolicy, String) {
  case s {
    "" -> Ok(UnlimitedTransfers)
    "0" -> Ok(NoTransfers)
    "1" -> Ok(OneTransfer)
    "2" -> Ok(TwoTransfers)
    _ -> Error("Invalid transfers value: " <> s)
  }
}
