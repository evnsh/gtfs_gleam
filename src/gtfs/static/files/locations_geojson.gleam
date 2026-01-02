//// Parser for locations.geojson
////
//// locations.geojson - GeoJSON file defining zones for flexible routing.
//// Source: GTFS reference.md - Dataset Files > locations.geojson

import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gtfs/internal/geojson
import gtfs/static/types as static_types

// =============================================================================
// Error Type
// =============================================================================

pub type ParseError {
  GeoJsonError(geojson.GeoJsonError)
  MissingId(index: Int)
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse locations.geojson content into LocationsGeoJson
pub fn parse(
  content: String,
) -> Result(static_types.LocationsGeoJson, ParseError) {
  use fc <- result.try(
    geojson.parse(content)
    |> result.map_error(GeoJsonError),
  )
  use features <- result.try(convert_features(fc.features, 0, []))
  Ok(static_types.LocationsGeoJson(features))
}

fn convert_features(
  features: List(geojson.Feature),
  index: Int,
  acc: List(static_types.GeoJsonFeature),
) -> Result(List(static_types.GeoJsonFeature), ParseError) {
  case features {
    [] -> Ok(list.reverse(acc))
    [f, ..rest] -> {
      use converted <- result.try(convert_feature(f, index))
      convert_features(rest, index + 1, [converted, ..acc])
    }
  }
}

fn convert_feature(
  feature: geojson.Feature,
  index: Int,
) -> Result(static_types.GeoJsonFeature, ParseError) {
  // ID is required for GTFS
  case feature.id {
    option.Some(id) -> {
      // Convert properties
      let props =
        static_types.GeoJsonProperties(
          stop_name: dict.get(feature.properties, "stop_name")
            |> option.from_result,
          stop_desc: dict.get(feature.properties, "stop_desc")
            |> option.from_result,
        )

      // Convert geometry
      let geometry = convert_geometry(feature.geometry)

      Ok(static_types.GeoJsonFeature(
        id: id,
        properties: props,
        geometry: geometry,
      ))
    }
    option.None -> Error(MissingId(index))
  }
}

fn convert_geometry(geom: geojson.Geometry) -> static_types.GeoJsonGeometry {
  case geom {
    geojson.Polygon(rings) -> static_types.Polygon(rings)
    geojson.MultiPolygon(polygons) -> static_types.MultiPolygon(polygons)
  }
}
