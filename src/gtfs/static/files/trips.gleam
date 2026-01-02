//// Parser for trips.txt
////
//// trips.txt - Trips for each route. A trip is a sequence of
//// two or more stops that occur during a specific time period.
//// Source: GTFS reference.md - Dataset Files > trips.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type BikesAllowed, type DirectionId, type Trip, type WheelchairAccessible,
  AccessibleVehicle, BikesAllowedOnVehicle, Inbound, NoAccessibilityInfo,
  NoBikeInfo, NoBikesAllowed, NotAccessibleVehicle, Outbound, Trip,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse trips.txt CSV content into a list of Trip records
pub fn parse(content: String) -> Result(List(Trip), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Trip),
) -> Result(List(Trip), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use trip <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [trip, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Trip, csv.ParseError) {
  // Required fields
  use route_id <- result.try(csv.get_required(row, "route_id", row_num))
  use service_id <- result.try(csv.get_required(row, "service_id", row_num))
  use trip_id <- result.try(csv.get_required(row, "trip_id", row_num))

  // Optional fields
  let trip_headsign = csv.get_optional(row, "trip_headsign")
  let trip_short_name = csv.get_optional(row, "trip_short_name")

  // Parse direction_id
  use direction_id <- result.try(csv.get_parsed(
    row,
    "direction_id",
    row_num,
    parse_direction_id,
  ))

  let block_id = csv.get_optional(row, "block_id")
  let shape_id = csv.get_optional(row, "shape_id")

  // Parse wheelchair_accessible with default
  let wheelchair_accessible =
    csv.get_with_default(
      row,
      "wheelchair_accessible",
      NoAccessibilityInfo,
      parse_wheelchair_accessible,
    )

  // Parse bikes_allowed with default
  let bikes_allowed =
    csv.get_with_default(row, "bikes_allowed", NoBikeInfo, parse_bikes_allowed)

  Ok(Trip(
    route_id: route_id,
    service_id: service_id,
    trip_id: trip_id,
    trip_headsign: trip_headsign,
    trip_short_name: trip_short_name,
    direction_id: direction_id,
    block_id: block_id,
    shape_id: shape_id,
    wheelchair_accessible: wheelchair_accessible,
    bikes_allowed: bikes_allowed,
  ))
}

// =============================================================================
// Enum Parsers
// =============================================================================

fn parse_direction_id(value: String) -> Result(DirectionId, String) {
  case value {
    "0" -> Ok(Outbound)
    "1" -> Ok(Inbound)
    _ -> Error("direction_id (0 or 1)")
  }
}

fn parse_wheelchair_accessible(
  value: String,
) -> Result(WheelchairAccessible, String) {
  case value {
    "" | "0" -> Ok(NoAccessibilityInfo)
    "1" -> Ok(AccessibleVehicle)
    "2" -> Ok(NotAccessibleVehicle)
    _ -> Error("wheelchair_accessible (0-2)")
  }
}

fn parse_bikes_allowed(value: String) -> Result(BikesAllowed, String) {
  case value {
    "" | "0" -> Ok(NoBikeInfo)
    "1" -> Ok(BikesAllowedOnVehicle)
    "2" -> Ok(NoBikesAllowed)
    _ -> Error("bikes_allowed (0-2)")
  }
}
