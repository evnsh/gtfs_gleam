//// Parser for route_networks.txt
////
//// route_networks.txt - Rules to assign routes to networks.
//// Source: GTFS reference.md - Dataset Files > route_networks.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type RouteNetwork, RouteNetwork}

// =============================================================================
// Parsing
// =============================================================================

/// Parse route_networks.txt CSV content into a list of RouteNetwork records
pub fn parse(content: String) -> Result(List(RouteNetwork), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(RouteNetwork),
) -> Result(List(RouteNetwork), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use route_network <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [route_network, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(RouteNetwork, csv.ParseError) {
  // Required fields
  use network_id <- result.try(csv.get_required(row, "network_id", row_num))
  use route_id <- result.try(csv.get_required(row, "route_id", row_num))

  Ok(RouteNetwork(network_id: network_id, route_id: route_id))
}
