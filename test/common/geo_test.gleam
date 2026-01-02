//// Geographic Utility Tests
////
//// Tests for Haversine distance, bearing, and polyline encoding/decoding

import gleam/float
import gleam/list
import gleeunit/should
import gtfs/common/geo
import gtfs/common/types.{Coordinate}

// =============================================================================
// Distance Calculation Tests
// =============================================================================

pub fn distance_same_point_test() {
  let point = Coordinate(latitude: 40.7128, longitude: -74.006)
  geo.distance_km(point, point) |> should.equal(0.0)
}

pub fn distance_new_york_to_london_test() {
  // NYC to London is approximately 5570 km
  let nyc = Coordinate(latitude: 40.7128, longitude: -74.006)
  let london = Coordinate(latitude: 51.5074, longitude: -0.1278)

  let distance = geo.distance_km(nyc, london)

  // Allow 1% tolerance
  let assert True = distance >. 5500.0
  let assert True = distance <. 5700.0
}

pub fn distance_meters_test() {
  // Short distance in meters
  let point1 = Coordinate(latitude: 40.7128, longitude: -74.006)
  let point2 = Coordinate(latitude: 40.7138, longitude: -74.006)

  let distance = geo.distance_m(point1, point2)
  // Should be approximately 111 meters (1/1000 degree lat at this location)
  let assert True = distance >. 100.0
  let assert True = distance <. 120.0
}

pub fn distance_antipodes_test() {
  // Points on opposite sides of Earth
  let point1 = Coordinate(latitude: 0.0, longitude: 0.0)
  let point2 = Coordinate(latitude: 0.0, longitude: 180.0)

  let distance = geo.distance_km(point1, point2)
  // Half Earth circumference is approximately 20015 km
  let assert True = distance >. 19_900.0
  let assert True = distance <. 20_100.0
}

pub fn distance_north_pole_to_south_pole_test() {
  let north = Coordinate(latitude: 90.0, longitude: 0.0)
  let south = Coordinate(latitude: -90.0, longitude: 0.0)

  let distance = geo.distance_km(north, south)
  // Pole to pole is approximately 20015 km
  let assert True = distance >. 19_900.0
  let assert True = distance <. 20_100.0
}

// =============================================================================
// Bearing Calculation Tests
// =============================================================================

pub fn bearing_due_north_test() {
  let from = Coordinate(latitude: 40.0, longitude: -74.0)
  let to = Coordinate(latitude: 41.0, longitude: -74.0)

  let bearing = geo.bearing(from, to)
  // Should be approximately 0 degrees (north)
  let assert True = bearing <. 1.0 || bearing >. 359.0
}

pub fn bearing_due_east_test() {
  let from = Coordinate(latitude: 0.0, longitude: 0.0)
  let to = Coordinate(latitude: 0.0, longitude: 1.0)

  let bearing = geo.bearing(from, to)
  // Should be approximately 90 degrees (east)
  let assert True = bearing >. 89.0
  let assert True = bearing <. 91.0
}

pub fn bearing_due_south_test() {
  let from = Coordinate(latitude: 41.0, longitude: -74.0)
  let to = Coordinate(latitude: 40.0, longitude: -74.0)

  let bearing = geo.bearing(from, to)
  // Should be approximately 180 degrees (south)
  let assert True = bearing >. 179.0
  let assert True = bearing <. 181.0
}

pub fn bearing_due_west_test() {
  let from = Coordinate(latitude: 0.0, longitude: 1.0)
  let to = Coordinate(latitude: 0.0, longitude: 0.0)

  let bearing = geo.bearing(from, to)
  // Should be approximately 270 degrees (west)
  let assert True = bearing >. 269.0
  let assert True = bearing <. 271.0
}

// =============================================================================
// Polyline Encoding/Decoding Tests
// =============================================================================

pub fn decode_polyline_simple_test() {
  // Google example: "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
  // Represents: (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
  let encoded = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"

  let assert Ok(coords) = geo.decode_polyline(encoded)
  list.length(coords) |> should.equal(3)

  let assert Ok(first) = list.first(coords)
  // Allow for precision differences
  let assert True = float.loosely_equals(first.latitude, 38.5, 0.001)
  let assert True = float.loosely_equals(first.longitude, -120.2, 0.001)
}

pub fn decode_polyline_empty_test() {
  let assert Ok(coords) = geo.decode_polyline("")
  list.length(coords) |> should.equal(0)
}

pub fn encode_polyline_simple_test() {
  let coords = [
    Coordinate(latitude: 38.5, longitude: -120.2),
    Coordinate(latitude: 40.7, longitude: -120.95),
    Coordinate(latitude: 43.252, longitude: -126.453),
  ]

  let encoded = geo.encode_polyline(coords)
  // Decode and verify round-trip
  let assert Ok(decoded) = geo.decode_polyline(encoded)
  list.length(decoded) |> should.equal(3)
}

pub fn encode_decode_roundtrip_test() {
  let original = [
    Coordinate(latitude: 40.7128, longitude: -74.006),
    Coordinate(latitude: 40.758, longitude: -73.9855),
    Coordinate(latitude: 40.7484, longitude: -73.9857),
  ]

  let encoded = geo.encode_polyline(original)
  let assert Ok(decoded) = geo.decode_polyline(encoded)

  // Verify length
  list.length(decoded) |> should.equal(3)

  // Verify first coordinate (with tolerance for encoding precision)
  let assert Ok(first) = list.first(decoded)
  let assert Ok(orig_first) = list.first(original)

  let assert True =
    float.loosely_equals(first.latitude, orig_first.latitude, 0.00001)
  let assert True =
    float.loosely_equals(first.longitude, orig_first.longitude, 0.00001)
}

// =============================================================================
// Coordinate Validation Tests
// =============================================================================

pub fn valid_coordinates_test() {
  // Valid coordinate ranges
  let assert True = geo.is_valid_coordinate(Coordinate(90.0, 180.0))
  let assert True = geo.is_valid_coordinate(Coordinate(-90.0, -180.0))
  let assert True = geo.is_valid_coordinate(Coordinate(0.0, 0.0))
  let assert True = geo.is_valid_coordinate(Coordinate(40.7128, -74.006))
}

pub fn invalid_latitude_test() {
  let assert False = geo.is_valid_coordinate(Coordinate(91.0, 0.0))
  let assert False = geo.is_valid_coordinate(Coordinate(-91.0, 0.0))
}

pub fn invalid_longitude_test() {
  let assert False = geo.is_valid_coordinate(Coordinate(0.0, 181.0))
  let assert False = geo.is_valid_coordinate(Coordinate(0.0, -181.0))
}

// =============================================================================
// Bounding Box Tests
// =============================================================================

pub fn bounding_box_single_point_test() {
  let coords = [Coordinate(latitude: 40.7128, longitude: -74.006)]

  let assert Ok(#(sw, ne)) = geo.bounding_box(coords)
  sw |> should.equal(Coordinate(40.7128, -74.006))
  ne |> should.equal(Coordinate(40.7128, -74.006))
}

pub fn bounding_box_multiple_points_test() {
  let coords = [
    Coordinate(latitude: 40.0, longitude: -75.0),
    Coordinate(latitude: 41.0, longitude: -74.0),
    Coordinate(latitude: 40.5, longitude: -74.5),
  ]

  let assert Ok(#(sw, ne)) = geo.bounding_box(coords)
  sw.latitude |> should.equal(40.0)
  sw.longitude |> should.equal(-75.0)
  ne.latitude |> should.equal(41.0)
  ne.longitude |> should.equal(-74.0)
}

pub fn bounding_box_empty_test() {
  geo.bounding_box([]) |> should.be_error()
}

// =============================================================================
// Point in Polygon Tests
// =============================================================================

pub fn point_in_simple_polygon_test() {
  // Simple square polygon
  let polygon = [
    Coordinate(latitude: 0.0, longitude: 0.0),
    Coordinate(latitude: 0.0, longitude: 10.0),
    Coordinate(latitude: 10.0, longitude: 10.0),
    Coordinate(latitude: 10.0, longitude: 0.0),
    Coordinate(latitude: 0.0, longitude: 0.0),
  ]

  // Point inside
  let inside = Coordinate(latitude: 5.0, longitude: 5.0)
  geo.point_in_polygon(inside, polygon) |> should.equal(True)

  // Point outside
  let outside = Coordinate(latitude: 15.0, longitude: 5.0)
  geo.point_in_polygon(outside, polygon) |> should.equal(False)
}

pub fn point_on_edge_test() {
  let polygon = [
    Coordinate(latitude: 0.0, longitude: 0.0),
    Coordinate(latitude: 0.0, longitude: 10.0),
    Coordinate(latitude: 10.0, longitude: 10.0),
    Coordinate(latitude: 10.0, longitude: 0.0),
    Coordinate(latitude: 0.0, longitude: 0.0),
  ]

  // Point on edge (behavior may vary by implementation)
  let on_edge = Coordinate(latitude: 0.0, longitude: 5.0)
  // Just verify it doesn't crash - edge cases can go either way
  let _ = geo.point_in_polygon(on_edge, polygon)
}
