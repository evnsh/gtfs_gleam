//// Parser for networks.txt
////
//// networks.txt - Network identifiers.
//// Source: GTFS reference.md - Dataset Files > networks.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type Network, Network}

// =============================================================================
// Parsing
// =============================================================================

/// Parse networks.txt CSV content into a list of Network records
pub fn parse(content: String) -> Result(List(Network), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Network),
) -> Result(List(Network), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use network <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [network, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Network, csv.ParseError) {
  // Required field
  use network_id <- result.try(csv.get_required(row, "network_id", row_num))

  // Optional fields
  let network_name = csv.get_optional(row, "network_name")

  Ok(Network(network_id: network_id, network_name: network_name))
}
