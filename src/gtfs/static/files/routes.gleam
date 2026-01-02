//// Parser for routes.txt
////
//// routes.txt - Transit routes. A route is a group of trips
//// displayed to riders as a single service.
//// Source: GTFS reference.md - Dataset Files > routes.txt

import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gtfs/common/types as common
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type ContinuousDropOff, type ContinuousPickup, type Route, type RouteType,
  AerialLift, Bus, CableTram, ContinuousStoppingDropOff,
  ContinuousStoppingPickup, CoordinateWithDriverForDropOff,
  CoordinateWithDriverForPickup, Extended, Ferry, Funicular, Monorail,
  NoContinuousStoppingDropOff, NoContinuousStoppingPickup, PhoneAgencyForDropOff,
  PhoneAgencyForPickup, Rail, Route, Subway, Tram, Trolleybus,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse routes.txt CSV content into a list of Route records
pub fn parse(content: String) -> Result(List(Route), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Route),
) -> Result(List(Route), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use route <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [route, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Route, csv.ParseError) {
  // Required fields
  use route_id <- result.try(csv.get_required(row, "route_id", row_num))
  use route_type <- result.try(csv.get_required_parsed(
    row,
    "route_type",
    row_num,
    parse_route_type,
  ))

  // Conditionally required fields (at least one of short_name or long_name required)
  let route_short_name = csv.get_optional(row, "route_short_name")
  let route_long_name = csv.get_optional(row, "route_long_name")

  // Optional fields
  let agency_id = csv.get_optional(row, "agency_id")
  let route_desc = csv.get_optional(row, "route_desc")
  let route_url = csv.get_optional(row, "route_url") |> option.map(common.Url)

  // Parse colors
  let route_color =
    csv.get_optional(row, "route_color") |> option.then(common.color_from_hex)
  let route_text_color =
    csv.get_optional(row, "route_text_color")
    |> option.then(common.color_from_hex)

  // Parse sort order
  use route_sort_order <- result.try(csv.get_parsed(
    row,
    "route_sort_order",
    row_num,
    csv.parse_non_negative_int,
  ))

  // Parse continuous pickup/drop-off with defaults
  let continuous_pickup =
    csv.get_with_default(
      row,
      "continuous_pickup",
      NoContinuousStoppingPickup,
      parse_continuous_pickup,
    )
  let continuous_drop_off =
    csv.get_with_default(
      row,
      "continuous_drop_off",
      NoContinuousStoppingDropOff,
      parse_continuous_drop_off,
    )

  let network_id = csv.get_optional(row, "network_id")

  Ok(Route(
    route_id: route_id,
    agency_id: agency_id,
    route_short_name: route_short_name,
    route_long_name: route_long_name,
    route_desc: route_desc,
    route_type: route_type,
    route_url: route_url,
    route_color: route_color,
    route_text_color: route_text_color,
    route_sort_order: route_sort_order,
    continuous_pickup: continuous_pickup,
    continuous_drop_off: continuous_drop_off,
    network_id: network_id,
  ))
}

// =============================================================================
// Enum Parsers
// =============================================================================

fn parse_route_type(value: String) -> Result(RouteType, String) {
  case value {
    "0" -> Ok(Tram)
    "1" -> Ok(Subway)
    "2" -> Ok(Rail)
    "3" -> Ok(Bus)
    "4" -> Ok(Ferry)
    "5" -> Ok(CableTram)
    "6" -> Ok(AerialLift)
    "7" -> Ok(Funicular)
    "11" -> Ok(Trolleybus)
    "12" -> Ok(Monorail)
    _ -> {
      // Try to parse as extended route type (100-1799)
      case int.parse(value) {
        Ok(n) if n >= 100 && n <= 1799 -> Ok(Extended(n))
        Ok(n) if n >= 8 && n <= 10 || n >= 13 && n <= 99 ->
          Error("route_type value " <> value <> " is reserved")
        _ -> Error("route_type must be 0-7, 11-12, or 100-1799")
      }
    }
  }
}

fn parse_continuous_pickup(value: String) -> Result(ContinuousPickup, String) {
  case value {
    "0" -> Ok(ContinuousStoppingPickup)
    "" | "1" -> Ok(NoContinuousStoppingPickup)
    "2" -> Ok(PhoneAgencyForPickup)
    "3" -> Ok(CoordinateWithDriverForPickup)
    _ -> Error("continuous_pickup (0-3)")
  }
}

fn parse_continuous_drop_off(value: String) -> Result(ContinuousDropOff, String) {
  case value {
    "0" -> Ok(ContinuousStoppingDropOff)
    "" | "1" -> Ok(NoContinuousStoppingDropOff)
    "2" -> Ok(PhoneAgencyForDropOff)
    "3" -> Ok(CoordinateWithDriverForDropOff)
    _ -> Error("continuous_drop_off (0-3)")
  }
}
