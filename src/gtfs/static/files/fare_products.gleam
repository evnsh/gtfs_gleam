//// Parser for fare_products.txt
////
//// fare_products.txt - Fare products that can be purchased.
//// Source: GTFS reference.md - Dataset Files > fare_products.txt

import gleam/list
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type FareProduct, FareProduct}

// =============================================================================
// Parsing
// =============================================================================

/// Parse fare_products.txt CSV content into a list of FareProduct records
pub fn parse(content: String) -> Result(List(FareProduct), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(FareProduct),
) -> Result(List(FareProduct), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use fare_product <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [fare_product, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(FareProduct, csv.ParseError) {
  // Required fields
  use fare_product_id <- result.try(csv.get_required(
    row,
    "fare_product_id",
    row_num,
  ))
  use amount <- result.try(csv.get_required_parsed(
    row,
    "amount",
    row_num,
    parse_amount,
  ))
  use currency <- result.try(csv.get_required(row, "currency", row_num))

  // Optional fields
  let fare_product_name = csv.get_optional(row, "fare_product_name")
  let fare_media_id = csv.get_optional(row, "fare_media_id")

  Ok(FareProduct(
    fare_product_id: fare_product_id,
    fare_product_name: fare_product_name,
    fare_media_id: fare_media_id,
    amount: amount,
    currency: common.CurrencyCode(currency),
  ))
}

fn parse_amount(s: String) -> Result(common.CurrencyAmount, String) {
  case csv.parse_float(s) {
    Ok(f) -> {
      let cents = float_to_cents(f)
      Ok(common.CurrencyAmount(cents, 2))
    }
    Error(_) -> Error("Invalid amount format")
  }
}

fn float_to_cents(f: Float) -> Int {
  let scaled = f *. 100.0
  float_round(scaled)
}

@external(erlang, "erlang", "round")
fn float_round(f: Float) -> Int
