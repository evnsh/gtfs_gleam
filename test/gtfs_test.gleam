import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import gtfs/common/types
import gtfs/static/types as static_types

pub fn main() -> Nil {
  gleeunit.main()
}

// =============================================================================
// Common Types Tests
// =============================================================================

pub fn time_creation_test() {
  let t = types.time(8, 30, 0)
  t.hours |> should.equal(8)
  t.minutes |> should.equal(30)
  t.seconds |> should.equal(0)
}

pub fn time_to_seconds_test() {
  let t = types.time(1, 30, 45)
  // 1*3600 + 30*60 + 45 = 3600 + 1800 + 45 = 5445
  types.time_to_seconds(t) |> should.equal(5445)
}

pub fn date_creation_test() {
  let d = types.date(2025, 10, 28)
  d.year |> should.equal(2025)
  d.month |> should.equal(10)
  d.day |> should.equal(28)
}

pub fn coordinate_creation_test() {
  let c = types.coordinate(40.7128, -74.006)
  c.latitude |> should.equal(40.7128)
  c.longitude |> should.equal(-74.006)
}

pub fn coordinate_validation_test() {
  // Valid coordinates
  types.is_valid_coordinate(types.coordinate(0.0, 0.0)) |> should.be_true()
  types.is_valid_coordinate(types.coordinate(90.0, 180.0)) |> should.be_true()
  types.is_valid_coordinate(types.coordinate(-90.0, -180.0)) |> should.be_true()

  // Invalid coordinates
  types.is_valid_coordinate(types.coordinate(91.0, 0.0)) |> should.be_false()
  types.is_valid_coordinate(types.coordinate(0.0, 181.0)) |> should.be_false()
}

pub fn color_from_hex_test() {
  // Valid hex colors
  let assert Some(white) = types.color_from_hex("FFFFFF")
  white.red |> should.equal(255)
  white.green |> should.equal(255)
  white.blue |> should.equal(255)

  let assert Some(black) = types.color_from_hex("000000")
  black.red |> should.equal(0)
  black.green |> should.equal(0)
  black.blue |> should.equal(0)

  let assert Some(red) = types.color_from_hex("FF0000")
  red.red |> should.equal(255)
  red.green |> should.equal(0)
  red.blue |> should.equal(0)

  // With # prefix
  let assert Some(blue) = types.color_from_hex("#0000FF")
  blue.blue |> should.equal(255)

  // Lowercase
  let assert Some(green) = types.color_from_hex("00ff00")
  green.green |> should.equal(255)
}

pub fn color_from_hex_invalid_test() {
  types.color_from_hex("FFF") |> should.equal(None)
  types.color_from_hex("GGGGGG") |> should.equal(None)
  types.color_from_hex("") |> should.equal(None)
}

pub fn color_validation_test() {
  types.is_valid_color(types.color(0, 0, 0)) |> should.be_true()
  types.is_valid_color(types.color(255, 255, 255)) |> should.be_true()
  types.is_valid_color(types.color(256, 0, 0)) |> should.be_false()
  types.is_valid_color(types.color(-1, 0, 0)) |> should.be_false()
}

// =============================================================================
// Static Types Tests
// =============================================================================

pub fn route_type_enum_test() {
  // Verify all route types are available
  let _tram = static_types.Tram
  let _subway = static_types.Subway
  let _rail = static_types.Rail
  let _bus = static_types.Bus
  let _ferry = static_types.Ferry
  let _cable = static_types.CableTram
  let _gondola = static_types.AerialLift
  let _funicular = static_types.Funicular
  let _trolleybus = static_types.Trolleybus
  let _monorail = static_types.Monorail
  Nil
}

pub fn location_type_enum_test() {
  let _stop = static_types.StopOrPlatform
  let _station = static_types.Station
  let _entrance = static_types.EntranceExit
  let _node = static_types.GenericNode
  let _boarding = static_types.BoardingArea
  Nil
}

pub fn cemv_support_enum_test() {
  let _none = static_types.NoCemvInfo
  let _supported = static_types.CemvSupported
  let _not_supported = static_types.CemvNotSupported
  Nil
}

pub fn stop_access_enum_test() {
  let _pathways = static_types.MustUsePathways
  let _direct = static_types.DirectStreetAccess
  Nil
}
