//// Parser for shapes.txt
////
//// shapes.txt - Rules for mapping vehicle travel paths,
//// sometimes referred to as route alignments.
//// Source: GTFS reference.md - Dataset Files > shapes.txt

import gleam/list
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{type ShapePoint, ShapePoint}

// =============================================================================
// Parsing
// =============================================================================

/// Parse shapes.txt CSV content into a list of ShapePoint records
pub fn parse(content: String) -> Result(List(ShapePoint), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(ShapePoint),
) -> Result(List(ShapePoint), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use shape_point <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [shape_point, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(ShapePoint, csv.ParseError) {
  // Required fields
  use shape_id <- result.try(csv.get_required(row, "shape_id", row_num))
  use shape_pt_lat <- result.try(csv.get_required_parsed(
    row,
    "shape_pt_lat",
    row_num,
    csv.parse_float,
  ))
  use shape_pt_lon <- result.try(csv.get_required_parsed(
    row,
    "shape_pt_lon",
    row_num,
    csv.parse_float,
  ))
  use shape_pt_sequence <- result.try(csv.get_required_parsed(
    row,
    "shape_pt_sequence",
    row_num,
    csv.parse_non_negative_int,
  ))

  // Optional field
  use shape_dist_traveled <- result.try(csv.get_parsed(
    row,
    "shape_dist_traveled",
    row_num,
    csv.parse_non_negative_float,
  ))

  Ok(ShapePoint(
    shape_id: shape_id,
    shape_pt_lat: shape_pt_lat,
    shape_pt_lon: shape_pt_lon,
    shape_pt_sequence: shape_pt_sequence,
    shape_dist_traveled: shape_dist_traveled,
  ))
}
