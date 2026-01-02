//// GeoJSON Parser for locations.geojson
////
//// Parses GeoJSON files according to RFC 7946.
//// Used for GTFS-Flex locations.geojson file.
//// Source: GTFS reference.md - Dataset Files > locations.geojson

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gtfs/common/types.{type Coordinate, Coordinate}

// =============================================================================
// Error Types
// =============================================================================

/// Errors that can occur during GeoJSON parsing
pub type GeoJsonError {
  /// Invalid JSON syntax
  InvalidJson(reason: String)
  /// Missing required field
  MissingField(field: String)
  /// Invalid geometry type
  InvalidGeometryType(got: String, expected: String)
  /// Invalid coordinates
  InvalidCoordinates(reason: String)
  /// Invalid polygon (not closed, wrong winding, etc.)
  InvalidPolygon(reason: String)
  /// Invalid feature
  InvalidFeature(reason: String)
}

// =============================================================================
// GeoJSON Types (simplified for GTFS use)
// =============================================================================

/// A GeoJSON FeatureCollection
pub type FeatureCollection {
  FeatureCollection(features: List(Feature))
}

/// A GeoJSON Feature
pub type Feature {
  Feature(
    id: Option(String),
    properties: Dict(String, String),
    geometry: Geometry,
  )
}

/// GeoJSON Geometry types supported for GTFS
pub type Geometry {
  Polygon(rings: List(List(Coordinate)))
  MultiPolygon(polygons: List(List(List(Coordinate))))
}

// =============================================================================
// JSON Tokenizer
// =============================================================================

type JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(Float)
  JsonString(String)
  JsonArray(List(JsonValue))
  JsonObject(Dict(String, JsonValue))
}

/// Parse a GeoJSON string into a FeatureCollection
pub fn parse(content: String) -> Result(FeatureCollection, GeoJsonError) {
  use json <- result.try(parse_json(string.trim(content)))
  use fc <- result.try(parse_feature_collection(json))
  Ok(fc)
}

/// Parse JSON string to JsonValue
fn parse_json(s: String) -> Result(JsonValue, GeoJsonError) {
  case parse_value(string.trim(s)) {
    Ok(#(value, "")) -> Ok(value)
    Ok(#(_, remaining)) ->
      Error(InvalidJson("Unexpected characters after JSON: " <> remaining))
    Error(e) -> Error(e)
  }
}

fn parse_value(s: String) -> Result(#(JsonValue, String), GeoJsonError) {
  let s = skip_whitespace(s)
  case s {
    "" -> Error(InvalidJson("Unexpected end of input"))
    "null" <> rest -> Ok(#(JsonNull, rest))
    "true" <> rest -> Ok(#(JsonBool(True), rest))
    "false" <> rest -> Ok(#(JsonBool(False), rest))
    "\"" <> _ -> parse_string(s)
    "[" <> rest -> parse_array(rest, [])
    "{" <> rest -> parse_object(rest, dict.new())
    _ -> parse_number(s)
  }
}

fn skip_whitespace(s: String) -> String {
  case s {
    " " <> rest -> skip_whitespace(rest)
    "\t" <> rest -> skip_whitespace(rest)
    "\n" <> rest -> skip_whitespace(rest)
    "\r" <> rest -> skip_whitespace(rest)
    _ -> s
  }
}

fn parse_string(s: String) -> Result(#(JsonValue, String), GeoJsonError) {
  case s {
    "\"" <> rest -> {
      use #(str, remaining) <- result.try(parse_string_content(rest, ""))
      Ok(#(JsonString(str), remaining))
    }
    _ -> Error(InvalidJson("Expected string"))
  }
}

fn parse_string_content(
  s: String,
  acc: String,
) -> Result(#(String, String), GeoJsonError) {
  case s {
    "" -> Error(InvalidJson("Unterminated string"))
    "\"" <> rest -> Ok(#(acc, rest))
    "\\" <> rest -> {
      case rest {
        "\"" <> r -> parse_string_content(r, acc <> "\"")
        "\\" <> r -> parse_string_content(r, acc <> "\\")
        "/" <> r -> parse_string_content(r, acc <> "/")
        "b" <> r -> parse_string_content(r, acc <> "\u{08}")
        "f" <> r -> parse_string_content(r, acc <> "\u{0C}")
        "n" <> r -> parse_string_content(r, acc <> "\n")
        "r" <> r -> parse_string_content(r, acc <> "\r")
        "t" <> r -> parse_string_content(r, acc <> "\t")
        _ -> Error(InvalidJson("Invalid escape sequence"))
      }
    }
    _ -> {
      case string.pop_grapheme(s) {
        Ok(#(c, rest)) -> parse_string_content(rest, acc <> c)
        Error(_) -> Error(InvalidJson("Invalid string"))
      }
    }
  }
}

fn parse_number(s: String) -> Result(#(JsonValue, String), GeoJsonError) {
  let #(num_str, rest) = take_number_chars(s, "")
  case float.parse(num_str) {
    Ok(f) -> Ok(#(JsonNumber(f), rest))
    Error(_) ->
      case int.parse(num_str) {
        Ok(i) -> Ok(#(JsonNumber(int.to_float(i)), rest))
        Error(_) -> Error(InvalidJson("Invalid number: " <> num_str))
      }
  }
}

fn take_number_chars(s: String, acc: String) -> #(String, String) {
  case s {
    "-" <> rest -> take_number_chars(rest, acc <> "-")
    "+" <> rest -> take_number_chars(rest, acc <> "+")
    "0" <> rest -> take_number_chars(rest, acc <> "0")
    "1" <> rest -> take_number_chars(rest, acc <> "1")
    "2" <> rest -> take_number_chars(rest, acc <> "2")
    "3" <> rest -> take_number_chars(rest, acc <> "3")
    "4" <> rest -> take_number_chars(rest, acc <> "4")
    "5" <> rest -> take_number_chars(rest, acc <> "5")
    "6" <> rest -> take_number_chars(rest, acc <> "6")
    "7" <> rest -> take_number_chars(rest, acc <> "7")
    "8" <> rest -> take_number_chars(rest, acc <> "8")
    "9" <> rest -> take_number_chars(rest, acc <> "9")
    "." <> rest -> take_number_chars(rest, acc <> ".")
    "e" <> rest -> take_number_chars(rest, acc <> "e")
    "E" <> rest -> take_number_chars(rest, acc <> "E")
    _ -> #(acc, s)
  }
}

fn parse_array(
  s: String,
  acc: List(JsonValue),
) -> Result(#(JsonValue, String), GeoJsonError) {
  let s = skip_whitespace(s)
  case s {
    "]" <> rest -> Ok(#(JsonArray(list.reverse(acc)), rest))
    _ -> {
      use #(value, rest) <- result.try(parse_value(s))
      let rest = skip_whitespace(rest)
      case rest {
        "," <> rest2 -> parse_array(rest2, [value, ..acc])
        "]" <> rest2 -> Ok(#(JsonArray(list.reverse([value, ..acc])), rest2))
        _ -> Error(InvalidJson("Expected ',' or ']' in array"))
      }
    }
  }
}

fn parse_object(
  s: String,
  acc: Dict(String, JsonValue),
) -> Result(#(JsonValue, String), GeoJsonError) {
  let s = skip_whitespace(s)
  case s {
    "}" <> rest -> Ok(#(JsonObject(acc), rest))
    "\"" <> _ -> {
      use #(key_value, rest) <- result.try(parse_string(s))
      let key = case key_value {
        JsonString(k) -> k
        _ -> ""
      }
      let rest = skip_whitespace(rest)
      case rest {
        ":" <> rest2 -> {
          use #(value, rest3) <- result.try(parse_value(rest2))
          let rest3 = skip_whitespace(rest3)
          let new_acc = dict.insert(acc, key, value)
          case rest3 {
            "," <> rest4 -> parse_object(rest4, new_acc)
            "}" <> rest4 -> Ok(#(JsonObject(new_acc), rest4))
            _ -> Error(InvalidJson("Expected ',' or '}' in object"))
          }
        }
        _ -> Error(InvalidJson("Expected ':' after object key"))
      }
    }
    _ -> Error(InvalidJson("Expected string key or '}' in object"))
  }
}

// =============================================================================
// GeoJSON Parsing
// =============================================================================

fn parse_feature_collection(
  json: JsonValue,
) -> Result(FeatureCollection, GeoJsonError) {
  case json {
    JsonObject(obj) -> {
      // Check type field
      use type_val <- result.try(get_string_field(obj, "type"))
      case type_val {
        "FeatureCollection" -> {
          use features_val <- result.try(get_field(obj, "features"))
          use features <- result.try(parse_features(features_val))
          Ok(FeatureCollection(features))
        }
        _ ->
          Error(InvalidGeometryType(
            got: type_val,
            expected: "FeatureCollection",
          ))
      }
    }
    _ -> Error(InvalidJson("Expected object"))
  }
}

fn parse_features(json: JsonValue) -> Result(List(Feature), GeoJsonError) {
  case json {
    JsonArray(items) -> {
      list.try_map(items, parse_feature)
    }
    _ -> Error(InvalidJson("Expected array of features"))
  }
}

fn parse_feature(json: JsonValue) -> Result(Feature, GeoJsonError) {
  case json {
    JsonObject(obj) -> {
      // Check type
      use type_val <- result.try(get_string_field(obj, "type"))
      case type_val {
        "Feature" -> {
          // Get id (optional but required for GTFS)
          let id = get_id_field(obj)

          // Get properties
          let props = get_properties(obj)

          // Get geometry
          use geom_val <- result.try(get_field(obj, "geometry"))
          use geometry <- result.try(parse_geometry(geom_val))

          Ok(Feature(id: id, properties: props, geometry: geometry))
        }
        _ -> Error(InvalidFeature("Expected Feature type, got " <> type_val))
      }
    }
    _ -> Error(InvalidFeature("Expected object"))
  }
}

fn get_id_field(obj: Dict(String, JsonValue)) -> Option(String) {
  case dict.get(obj, "id") {
    Ok(JsonString(s)) -> Some(s)
    Ok(JsonNumber(n)) -> Some(float.to_string(n))
    _ -> None
  }
}

fn get_properties(obj: Dict(String, JsonValue)) -> Dict(String, String) {
  case dict.get(obj, "properties") {
    Ok(JsonObject(props)) -> {
      dict.fold(props, dict.new(), fn(acc, key, value) {
        case value {
          JsonString(s) -> dict.insert(acc, key, s)
          JsonNumber(n) -> dict.insert(acc, key, float.to_string(n))
          JsonBool(True) -> dict.insert(acc, key, "true")
          JsonBool(False) -> dict.insert(acc, key, "false")
          _ -> acc
        }
      })
    }
    _ -> dict.new()
  }
}

fn parse_geometry(json: JsonValue) -> Result(Geometry, GeoJsonError) {
  case json {
    JsonObject(obj) -> {
      use type_val <- result.try(get_string_field(obj, "type"))
      use coords_val <- result.try(get_field(obj, "coordinates"))

      case type_val {
        "Polygon" -> {
          use rings <- result.try(parse_polygon_coordinates(coords_val))
          Ok(Polygon(rings))
        }
        "MultiPolygon" -> {
          use polygons <- result.try(parse_multipolygon_coordinates(coords_val))
          Ok(MultiPolygon(polygons))
        }
        _ ->
          Error(InvalidGeometryType(
            got: type_val,
            expected: "Polygon or MultiPolygon",
          ))
      }
    }
    _ -> Error(InvalidJson("Expected geometry object"))
  }
}

fn parse_polygon_coordinates(
  json: JsonValue,
) -> Result(List(List(Coordinate)), GeoJsonError) {
  case json {
    JsonArray(rings) -> {
      list.try_map(rings, parse_ring)
    }
    _ -> Error(InvalidCoordinates("Expected array of rings"))
  }
}

fn parse_multipolygon_coordinates(
  json: JsonValue,
) -> Result(List(List(List(Coordinate))), GeoJsonError) {
  case json {
    JsonArray(polygons) -> {
      list.try_map(polygons, parse_polygon_coordinates)
    }
    _ -> Error(InvalidCoordinates("Expected array of polygons"))
  }
}

fn parse_ring(json: JsonValue) -> Result(List(Coordinate), GeoJsonError) {
  case json {
    JsonArray(points) -> {
      list.try_map(points, parse_coordinate)
    }
    _ -> Error(InvalidCoordinates("Expected array of coordinates"))
  }
}

fn parse_coordinate(json: JsonValue) -> Result(Coordinate, GeoJsonError) {
  case json {
    JsonArray(nums) -> {
      case nums {
        [JsonNumber(lon), JsonNumber(lat), ..] -> {
          // GeoJSON is [longitude, latitude]
          Ok(Coordinate(latitude: lat, longitude: lon))
        }
        _ -> Error(InvalidCoordinates("Expected [longitude, latitude] array"))
      }
    }
    _ -> Error(InvalidCoordinates("Expected coordinate array"))
  }
}

fn get_field(
  obj: Dict(String, JsonValue),
  field: String,
) -> Result(JsonValue, GeoJsonError) {
  case dict.get(obj, field) {
    Ok(v) -> Ok(v)
    Error(_) -> Error(MissingField(field))
  }
}

fn get_string_field(
  obj: Dict(String, JsonValue),
  field: String,
) -> Result(String, GeoJsonError) {
  case dict.get(obj, field) {
    Ok(JsonString(s)) -> Ok(s)
    Ok(_) -> Error(InvalidJson("Expected string for field: " <> field))
    Error(_) -> Error(MissingField(field))
  }
}
