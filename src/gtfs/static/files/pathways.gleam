//// Parser for pathways.txt
////
//// pathways.txt - Pathways linking together locations within stations.
//// Source: GTFS reference.md - Dataset Files > pathways.txt

import gleam/list
import gleam/option
import gleam/result
import gtfs/internal/csv.{type CsvRow}
import gtfs/static/types.{
  type Pathway, type PathwayMode, Elevator, Escalator, ExitGate, FareGate,
  MovingSidewalk, Pathway, Stairs, Walkway,
}

// =============================================================================
// Parsing
// =============================================================================

/// Parse pathways.txt CSV content into a list of Pathway records
pub fn parse(content: String) -> Result(List(Pathway), csv.ParseError) {
  use rows <- result.try(csv.parse(content))
  parse_rows(rows, 2, [])
}

fn parse_rows(
  rows: List(CsvRow),
  row_num: Int,
  acc: List(Pathway),
) -> Result(List(Pathway), csv.ParseError) {
  case rows {
    [] -> Ok(list.reverse(acc))
    [row, ..rest] -> {
      use pathway <- result.try(parse_row(row, row_num))
      parse_rows(rest, row_num + 1, [pathway, ..acc])
    }
  }
}

fn parse_row(row: CsvRow, row_num: Int) -> Result(Pathway, csv.ParseError) {
  // Required fields
  use pathway_id <- result.try(csv.get_required(row, "pathway_id", row_num))
  use from_stop_id <- result.try(csv.get_required(row, "from_stop_id", row_num))
  use to_stop_id <- result.try(csv.get_required(row, "to_stop_id", row_num))
  use pathway_mode <- result.try(csv.get_required_parsed(
    row,
    "pathway_mode",
    row_num,
    parse_pathway_mode,
  ))
  use is_bidirectional <- result.try(csv.get_required_parsed(
    row,
    "is_bidirectional",
    row_num,
    parse_bidirectional,
  ))

  // Optional fields
  let length = parse_optional_float(row, "length")
  let traversal_time = parse_optional_int(row, "traversal_time")
  let stair_count = parse_optional_int(row, "stair_count")
  let max_slope = parse_optional_float(row, "max_slope")
  let min_width = parse_optional_float(row, "min_width")
  let signposted_as = csv.get_optional(row, "signposted_as")
  let reversed_signposted_as = csv.get_optional(row, "reversed_signposted_as")

  Ok(Pathway(
    pathway_id: pathway_id,
    from_stop_id: from_stop_id,
    to_stop_id: to_stop_id,
    pathway_mode: pathway_mode,
    is_bidirectional: is_bidirectional,
    length: length,
    traversal_time: traversal_time,
    stair_count: stair_count,
    max_slope: max_slope,
    min_width: min_width,
    signposted_as: signposted_as,
    reversed_signposted_as: reversed_signposted_as,
  ))
}

fn parse_pathway_mode(s: String) -> Result(PathwayMode, String) {
  case s {
    "1" -> Ok(Walkway)
    "2" -> Ok(Stairs)
    "3" -> Ok(MovingSidewalk)
    "4" -> Ok(Escalator)
    "5" -> Ok(Elevator)
    "6" -> Ok(FareGate)
    "7" -> Ok(ExitGate)
    _ -> Error("Invalid pathway_mode value: " <> s)
  }
}

fn parse_bidirectional(s: String) -> Result(Bool, String) {
  case s {
    "0" -> Ok(False)
    "1" -> Ok(True)
    _ -> Error("Invalid is_bidirectional value: " <> s)
  }
}

fn parse_optional_float(row: CsvRow, field: String) -> option.Option(Float) {
  csv.get_optional(row, field)
  |> option.then(fn(s) {
    case csv.parse_float(s) {
      Ok(f) -> option.Some(f)
      Error(_) -> option.None
    }
  })
}

fn parse_optional_int(row: CsvRow, field: String) -> option.Option(Int) {
  csv.get_optional(row, field)
  |> option.then(fn(s) {
    case csv.parse_int(s) {
      Ok(i) -> option.Some(i)
      Error(_) -> option.None
    }
  })
}
