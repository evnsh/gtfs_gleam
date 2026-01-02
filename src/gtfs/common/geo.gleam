//// Geographic Utilities
////
//// Provides geographic calculations for GTFS data including:
//// - Haversine distance calculation
//// - Bearing calculation
//// - Google Polyline encoding/decoding
//// - Point-in-polygon testing
////
//// # Example
////
//// ```gleam
//// import gtfs/common/geo
//// import gtfs/common/types.{Coordinate}
////
//// pub fn main() {
////   let nyc = Coordinate(40.7128, -74.0060)
////   let la = Coordinate(34.0522, -118.2437)
////
////   let km = geo.distance_km(nyc, la)
//// }
//// ```

import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gtfs/common/types.{type Coordinate, Coordinate}

// =============================================================================
// Constants
// =============================================================================

/// Earth's radius in kilometers
const earth_radius_km = 6371.0

/// Earth's radius in meters
const earth_radius_m = 6_371_000.0

/// Pi constant
const pi = 3.141592653589793

// =============================================================================
// Distance Calculations
// =============================================================================

/// Calculate the great-circle distance between two coordinates using the Haversine formula.
/// Returns distance in kilometers.
pub fn distance_km(from: Coordinate, to: Coordinate) -> Float {
  haversine_distance(from, to, earth_radius_km)
}

/// Calculate the great-circle distance between two coordinates using the Haversine formula.
/// Returns distance in meters.
pub fn distance_m(from: Coordinate, to: Coordinate) -> Float {
  haversine_distance(from, to, earth_radius_m)
}

fn haversine_distance(from: Coordinate, to: Coordinate, radius: Float) -> Float {
  let lat1_rad = degrees_to_radians(from.latitude)
  let lat2_rad = degrees_to_radians(to.latitude)
  let delta_lat = degrees_to_radians(to.latitude -. from.latitude)
  let delta_lon = degrees_to_radians(to.longitude -. from.longitude)

  let a =
    sin_squared(delta_lat /. 2.0)
    +. float_cos(lat1_rad)
    *. float_cos(lat2_rad)
    *. sin_squared(delta_lon /. 2.0)

  let c = 2.0 *. float_atan2(float_sqrt(a), float_sqrt(1.0 -. a))

  radius *. c
}

// =============================================================================
// Bearing Calculation
// =============================================================================

/// Calculate the initial bearing from one coordinate to another.
/// Returns bearing in degrees (0-360, where 0 is north).
pub fn bearing(from: Coordinate, to: Coordinate) -> Float {
  let lat1_rad = degrees_to_radians(from.latitude)
  let lat2_rad = degrees_to_radians(to.latitude)
  let delta_lon = degrees_to_radians(to.longitude -. from.longitude)

  let x = float_sin(delta_lon) *. float_cos(lat2_rad)
  let y =
    float_cos(lat1_rad)
    *. float_sin(lat2_rad)
    -. float_sin(lat1_rad)
    *. float_cos(lat2_rad)
    *. float_cos(delta_lon)

  let bearing_rad = float_atan2(x, y)
  let bearing_deg = radians_to_degrees(bearing_rad)

  // Normalize to 0-360
  case bearing_deg <. 0.0 {
    True -> bearing_deg +. 360.0
    False -> bearing_deg
  }
}

// =============================================================================
// Google Polyline Algorithm
// =============================================================================

/// Decode a Google encoded polyline string into a list of coordinates.
/// Used for GTFS Realtime shapes and static shapes.txt visualization.
pub fn decode_polyline(encoded: String) -> Result(List(Coordinate), String) {
  decode_polyline_impl(string.to_graphemes(encoded), 0, 0, [])
}

fn decode_polyline_impl(
  chars: List(String),
  lat: Int,
  lon: Int,
  acc: List(Coordinate),
) -> Result(List(Coordinate), String) {
  case chars {
    [] -> Ok(list.reverse(acc))
    _ -> {
      use #(d_lat, remaining) <- result.try(decode_polyline_value(chars, 0, 0))
      use #(d_lon, remaining2) <- result.try(decode_polyline_value(
        remaining,
        0,
        0,
      ))

      let new_lat = lat + d_lat
      let new_lon = lon + d_lon

      let coord =
        Coordinate(
          latitude: int.to_float(new_lat) /. 100_000.0,
          longitude: int.to_float(new_lon) /. 100_000.0,
        )

      decode_polyline_impl(remaining2, new_lat, new_lon, [coord, ..acc])
    }
  }
}

fn decode_polyline_value(
  chars: List(String),
  result_val: Int,
  shift: Int,
) -> Result(#(Int, List(String)), String) {
  case chars {
    [] -> Error("Unexpected end of polyline")
    [c, ..rest] -> {
      case string.to_utf_codepoints(c) {
        [cp] -> {
          let b = string.utf_codepoint_to_int(cp) - 63
          let result_val =
            int.bitwise_or(
              result_val,
              int.bitwise_shift_left(int.bitwise_and(b, 0x1f), shift),
            )
          case int.bitwise_and(b, 0x20) != 0 {
            True -> decode_polyline_value(rest, result_val, shift + 5)
            False -> {
              // Apply zigzag decoding
              let decoded = case int.bitwise_and(result_val, 1) != 0 {
                True -> int.negate(int.bitwise_shift_right(result_val, 1)) - 1
                False -> int.bitwise_shift_right(result_val, 1)
              }
              Ok(#(decoded, rest))
            }
          }
        }
        _ -> Error("Invalid polyline character")
      }
    }
  }
}

/// Encode a list of coordinates into a Google encoded polyline string.
pub fn encode_polyline(coords: List(Coordinate)) -> String {
  encode_polyline_impl(coords, 0, 0, "")
}

fn encode_polyline_impl(
  coords: List(Coordinate),
  prev_lat: Int,
  prev_lon: Int,
  acc: String,
) -> String {
  case coords {
    [] -> acc
    [coord, ..rest] -> {
      let lat = float.round(coord.latitude *. 100_000.0)
      let lon = float.round(coord.longitude *. 100_000.0)

      let d_lat = lat - prev_lat
      let d_lon = lon - prev_lon

      let encoded_lat = encode_polyline_value(d_lat)
      let encoded_lon = encode_polyline_value(d_lon)

      encode_polyline_impl(rest, lat, lon, acc <> encoded_lat <> encoded_lon)
    }
  }
}

fn encode_polyline_value(value: Int) -> String {
  // Apply zigzag encoding
  let encoded = case value < 0 {
    True -> int.bitwise_not(int.bitwise_shift_left(value, 1))
    False -> int.bitwise_shift_left(value, 1)
  }
  encode_chunks(encoded, "")
}

fn encode_chunks(value: Int, acc: String) -> String {
  let chunk = int.bitwise_and(value, 0x1f)
  let remaining = int.bitwise_shift_right(value, 5)

  case remaining > 0 {
    True -> {
      let char_code = int.bitwise_or(chunk, 0x20) + 63
      let char = char_from_code(char_code)
      encode_chunks(remaining, acc <> char)
    }
    False -> {
      let char_code = chunk + 63
      let char = char_from_code(char_code)
      acc <> char
    }
  }
}

fn char_from_code(code: Int) -> String {
  case string.utf_codepoint(code) {
    Ok(cp) -> string.from_utf_codepoints([cp])
    Error(_) -> "?"
  }
}

// =============================================================================
// Point in Polygon
// =============================================================================

/// Check if a coordinate is inside a polygon using the ray casting algorithm.
/// The polygon is defined as a list of coordinates forming a closed ring.
pub fn point_in_polygon(point: Coordinate, polygon: List(Coordinate)) -> Bool {
  ray_cast_count(point, polygon, False)
}

fn ray_cast_count(
  point: Coordinate,
  polygon: List(Coordinate),
  inside: Bool,
) -> Bool {
  case polygon {
    [] -> inside
    [_] -> inside
    [p1, p2, ..rest] -> {
      let crosses = ray_intersects_segment(point, p1, p2)
      let new_inside = case crosses {
        True -> !inside
        False -> inside
      }
      ray_cast_count(point, [p2, ..rest], new_inside)
    }
  }
}

fn ray_intersects_segment(
  point: Coordinate,
  p1: Coordinate,
  p2: Coordinate,
) -> Bool {
  let px = point.longitude
  let py = point.latitude
  let p1x = p1.longitude
  let p1y = p1.latitude
  let p2x = p2.longitude
  let p2y = p2.latitude

  // Check if the ray from point going right intersects the segment
  case { p1y >. py } != { p2y >. py } {
    False -> False
    True -> {
      let slope =
        { px -. p1x } *. { p2y -. p1y } -. { p2x -. p1x } *. { py -. p1y }
      case slope <. 0.0 {
        True -> p2y <. p1y
        False -> p2y >. p1y
      }
    }
  }
}

// =============================================================================
// Coordinate Validation
// =============================================================================

/// Check if a coordinate is valid (within WGS84 bounds)
pub fn is_valid_coordinate(coord: Coordinate) -> Bool {
  coord.latitude >=. -90.0
  && coord.latitude <=. 90.0
  && coord.longitude >=. -180.0
  && coord.longitude <=. 180.0
}

/// Calculate the bounding box for a list of coordinates
pub fn bounding_box(
  coords: List(Coordinate),
) -> Result(#(Coordinate, Coordinate), String) {
  case coords {
    [] -> Error("Empty coordinate list")
    [first, ..rest] -> {
      let #(min_lat, max_lat, min_lon, max_lon) =
        list.fold(
          rest,
          #(first.latitude, first.latitude, first.longitude, first.longitude),
          fn(acc, coord) {
            let #(min_lat, max_lat, min_lon, max_lon) = acc
            #(
              float_min(min_lat, coord.latitude),
              float_max(max_lat, coord.latitude),
              float_min(min_lon, coord.longitude),
              float_max(max_lon, coord.longitude),
            )
          },
        )

      Ok(#(
        Coordinate(latitude: min_lat, longitude: min_lon),
        Coordinate(latitude: max_lat, longitude: max_lon),
      ))
    }
  }
}

// =============================================================================
// Math Helpers
// =============================================================================

fn degrees_to_radians(degrees: Float) -> Float {
  degrees *. pi /. 180.0
}

fn radians_to_degrees(radians: Float) -> Float {
  radians *. 180.0 /. pi
}

fn sin_squared(x: Float) -> Float {
  let s = float_sin(x)
  s *. s
}

fn float_min(a: Float, b: Float) -> Float {
  case a <. b {
    True -> a
    False -> b
  }
}

fn float_max(a: Float, b: Float) -> Float {
  case a >. b {
    True -> a
    False -> b
  }
}

@external(erlang, "math", "sin")
fn float_sin(x: Float) -> Float

@external(erlang, "math", "cos")
fn float_cos(x: Float) -> Float

@external(erlang, "math", "sqrt")
fn float_sqrt(x: Float) -> Float

@external(erlang, "math", "atan2")
fn float_atan2(y: Float, x: Float) -> Float
