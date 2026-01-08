//// GTFS Static Feed
////
//// This module provides functionality to load and work with
//// complete GTFS Static feeds from ZIP archives or directories.
////
//// # Example
////
//// ```gleam
//// import gtfs/static/feed
//// import gleam/list
////
//// pub fn main() {
////   // Load a feed from a ZIP file
////   case feed.load("path/to/gtfs.zip") {
////     Ok(my_feed) -> {
////       // Access feed data
////       let stop_count = list.length(my_feed.stops)
////     }
////     Error(err) -> {
////       // Handle error
////     }
////   }
//// }
//// ```

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string
import gtfs/internal/csv.{type ParseError}
import gtfs/internal/profile
import gtfs/internal/zip
import gtfs/static/files/agency
import gtfs/static/files/areas
import gtfs/static/files/attributions
import gtfs/static/files/booking_rules
import gtfs/static/files/calendar
import gtfs/static/files/calendar_dates
import gtfs/static/files/fare_attributes
import gtfs/static/files/fare_leg_join_rules
import gtfs/static/files/fare_leg_rules
import gtfs/static/files/fare_media
import gtfs/static/files/fare_products
import gtfs/static/files/fare_rules
import gtfs/static/files/fare_transfer_rules
import gtfs/static/files/feed_info
import gtfs/static/files/frequencies
import gtfs/static/files/levels
import gtfs/static/files/location_group_stops
import gtfs/static/files/location_groups
import gtfs/static/files/locations_geojson
import gtfs/static/files/networks
import gtfs/static/files/pathways
import gtfs/static/files/route_networks
import gtfs/static/files/routes
import gtfs/static/files/shapes
import gtfs/static/files/stop_areas
import gtfs/static/files/stop_times
import gtfs/static/files/stops
import gtfs/static/files/timeframes
import gtfs/static/files/transfers
import gtfs/static/files/translations
import gtfs/static/files/trips
import gtfs/static/types.{
  type Agency, type Area, type Attribution, type BookingRule, type Calendar,
  type CalendarDate, type FareAttribute, type FareLegJoinRule, type FareLegRule,
  type FareMedia, type FareProduct, type FareRule, type FareTransferRule,
  type FeedInfo, type Frequency, type Level, type LocationGroup,
  type LocationGroupStop, type LocationsGeoJson, type Network, type Pathway,
  type Route, type RouteNetwork, type ShapePoint, type Stop, type StopArea,
  type StopTime, type Timeframe, type Transfer, type Translation, type Trip,
}
import gtfs/static/validation
import simplifile

// =============================================================================
// Feed Type
// =============================================================================

/// A complete GTFS Static feed containing all parsed data
pub type Feed {
  Feed(
    // Required files
    /// Transit agencies (required file)
    agencies: List(Agency),
    /// Routes (required file)
    routes: List(Route),
    /// Trips (required file)
    trips: List(Trip),
    /// Stop times (required file)
    stop_times: List(StopTime),
    // Conditionally required files
    /// Stops and stations (conditionally required - either this or locations)
    stops: List(Stop),
    /// Weekly service schedule (conditionally required - either this or calendar_dates)
    calendar: Option(List(Calendar)),
    /// Service exceptions (conditionally required - either this or calendar)
    calendar_dates: Option(List(CalendarDate)),
    /// Feed metadata (conditionally required if translations provided)
    feed_info: Option(FeedInfo),
    /// Multi-level station levels (conditionally required if pathways use levels)
    levels: Option(List(Level)),
    // Optional files
    /// Shape points for trip paths (optional)
    shapes: Option(List(ShapePoint)),
    /// Frequency-based service (optional)
    frequencies: Option(List(Frequency)),
    /// Transfer rules (optional)
    transfers: Option(List(Transfer)),
    /// Station pathways (optional)
    pathways: Option(List(Pathway)),
    /// Fare attributes - legacy v1 (optional)
    fare_attributes: Option(List(FareAttribute)),
    /// Fare rules - legacy v1 (optional)
    fare_rules: Option(List(FareRule)),
    /// Translations (optional)
    translations: Option(List(Translation)),
    /// Attributions (optional)
    attributions: Option(List(Attribution)),
    // GTFS-Fares v2
    /// Areas for fare calculations (optional)
    areas: Option(List(Area)),
    /// Stop-area assignments (optional)
    stop_areas: Option(List(StopArea)),
    /// Networks for fare calculations (optional)
    networks: Option(List(Network)),
    /// Route-network assignments (optional)
    route_networks: Option(List(RouteNetwork)),
    /// Timeframes for fare calculations (optional)
    timeframes: Option(List(Timeframe)),
    /// Fare media types (optional)
    fare_media: Option(List(FareMedia)),
    /// Fare products (optional)
    fare_products: Option(List(FareProduct)),
    /// Fare leg rules (optional)
    fare_leg_rules: Option(List(FareLegRule)),
    /// Fare leg join rules (optional)
    fare_leg_join_rules: Option(List(FareLegJoinRule)),
    /// Fare transfer rules (optional)
    fare_transfer_rules: Option(List(FareTransferRule)),
    // GTFS-Flex
    /// Location groups for flexible routing (optional)
    location_groups: Option(List(LocationGroup)),
    /// Location group stop assignments (optional)
    location_group_stops: Option(List(LocationGroupStop)),
    /// GeoJSON locations for flexible routing (optional)
    locations: Option(LocationsGeoJson),
    /// Booking rules for flexible service (optional)
    booking_rules: Option(List(BookingRule)),
  )
}

// =============================================================================
// Error Types
// =============================================================================

/// Errors that can occur when loading a feed
pub type LoadError {
  /// File system error
  FileError(path: String, reason: String)
  /// CSV parsing error
  CsvParseError(file: String, error: ParseError)
  /// Required file is missing
  MissingRequiredFile(filename: String)
  /// Invalid feed structure
  InvalidFeed(reason: String)
  /// ZIP archive error
  ZipError(error: zip.ZipError)
  /// GeoJSON parsing error
  GeoJsonError(file: String, reason: String)
  /// Validation errors (when validation is enabled)
  ValidationErrors(errors: List(validation.ValidationError))
  /// Multiple parse errors (when error recovery is enabled)
  MultipleErrors(errors: List(LoadError))
}

/// Options for loading a feed
pub type LoadOptions {
  LoadOptions(
    /// Whether to validate the feed after loading (default: True)
    validate: Bool,
    /// Whether to collect all errors instead of failing on first (default: False)
    collect_errors: Bool,
    /// Whether to use streaming/lazy loading for large feeds (default: False)
    streaming: Bool,
  )
}

/// Default load options
pub fn default_options() -> LoadOptions {
  LoadOptions(validate: True, collect_errors: False, streaming: False)
}

/// Load options without validation
pub fn no_validation_options() -> LoadOptions {
  LoadOptions(validate: False, collect_errors: False, streaming: False)
}

/// Load options with error collection
pub fn error_collection_options() -> LoadOptions {
  LoadOptions(validate: True, collect_errors: True, streaming: False)
}

// =============================================================================
// Feed Loading
// =============================================================================

/// Load a GTFS feed from a path (ZIP file or directory)
/// Automatically detects whether the path is a ZIP archive or directory
pub fn load(path: String) -> Result(Feed, LoadError) {
  load_with_options(path, default_options())
}

/// Load a GTFS feed with custom options
pub fn load_with_options(
  path: String,
  options: LoadOptions,
) -> Result(Feed, LoadError) {
  case profile.enabled() {
    True -> {
      let start = profile.now_ms()

      let result = case string.ends_with(path, ".zip") {
        True -> load_from_zip_with_options(path, options)
        False -> load_from_directory_with_options(path, options)
      }

      let finish = profile.now_ms()
      profile.log("static.load.total", finish - start)
      result
    }
    False ->
      case string.ends_with(path, ".zip") {
        True -> load_from_zip_with_options(path, options)
        False -> load_from_directory_with_options(path, options)
      }
  }
}

/// Load a GTFS feed from a ZIP archive
pub fn load_from_zip(path: String) -> Result(Feed, LoadError) {
  load_from_zip_with_options(path, default_options())
}

/// Load a GTFS feed from a ZIP archive with options
pub fn load_from_zip_with_options(
  path: String,
  options: LoadOptions,
) -> Result(Feed, LoadError) {
  use zip_data <- result.try(
    profile.time_result("static.zip.read_bits", fn() {
      simplifile.read_bits(path)
      |> result.map_error(fn(_) { FileError(path, "Failed to read ZIP file") })
    }),
  )

  use archive <- result.try(
    profile.time_result("static.zip.open", fn() {
      zip.open(zip_data) |> result.map_error(ZipError)
    }),
  )

  use feed <- result.try(
    profile.time_result("static.zip.load_from_archive", fn() {
      load_from_archive_with_options(archive, options)
    }),
  )

  case options.validate {
    True -> profile.time_result("static.validate", fn() { validate_feed(feed) })
    False -> Ok(feed)
  }
}

/// Load a GTFS feed from an opened ZIP archive with options
fn load_from_archive_with_options(
  archive: zip.ZipArchive,
  options: LoadOptions,
) -> Result(Feed, LoadError) {
  case options.collect_errors {
    True -> load_from_archive_collect_errors(archive)
    False -> load_from_archive_fail_fast(archive)
  }
}

/// Load from archive, failing on first error (default behavior)
fn load_from_archive_fail_fast(
  archive: zip.ZipArchive,
) -> Result(Feed, LoadError) {
  // Load required files
  use agencies <- result.try(load_zip_file(archive, "agency.txt", agency.parse))
  use stops <- result.try(load_zip_file(archive, "stops.txt", stops.parse))
  use routes_data <- result.try(load_zip_file(
    archive,
    "routes.txt",
    routes.parse,
  ))
  use trips_data <- result.try(load_zip_file(archive, "trips.txt", trips.parse))
  use stop_times_data <- result.try(load_zip_file(
    archive,
    "stop_times.txt",
    stop_times.parse,
  ))

  // Load conditionally required files
  let calendar_data = load_zip_optional(archive, "calendar.txt", calendar.parse)
  let calendar_dates_data =
    load_zip_optional(archive, "calendar_dates.txt", calendar_dates.parse)
  let feed_info_data =
    load_zip_optional_single(archive, "feed_info.txt", feed_info.parse)
  let levels_data = load_zip_optional(archive, "levels.txt", levels.parse)

  // Load optional files
  let shapes_data = load_zip_optional(archive, "shapes.txt", shapes.parse)
  let frequencies_data =
    load_zip_optional(archive, "frequencies.txt", frequencies.parse)
  let transfers_data =
    load_zip_optional(archive, "transfers.txt", transfers.parse)
  let pathways_data = load_zip_optional(archive, "pathways.txt", pathways.parse)
  let fare_attributes_data =
    load_zip_optional(archive, "fare_attributes.txt", fare_attributes.parse)
  let fare_rules_data =
    load_zip_optional(archive, "fare_rules.txt", fare_rules.parse)
  let translations_data =
    load_zip_optional(archive, "translations.txt", translations.parse)
  let attributions_data =
    load_zip_optional(archive, "attributions.txt", attributions.parse)

  // GTFS-Fares v2
  let areas_data = load_zip_optional(archive, "areas.txt", areas.parse)
  let stop_areas_data =
    load_zip_optional(archive, "stop_areas.txt", stop_areas.parse)
  let networks_data = load_zip_optional(archive, "networks.txt", networks.parse)
  let route_networks_data =
    load_zip_optional(archive, "route_networks.txt", route_networks.parse)
  let timeframes_data =
    load_zip_optional(archive, "timeframes.txt", timeframes.parse)
  let fare_media_data =
    load_zip_optional(archive, "fare_media.txt", fare_media.parse)
  let fare_products_data =
    load_zip_optional(archive, "fare_products.txt", fare_products.parse)
  let fare_leg_rules_data =
    load_zip_optional(archive, "fare_leg_rules.txt", fare_leg_rules.parse)
  let fare_leg_join_rules_data =
    load_zip_optional(
      archive,
      "fare_leg_join_rules.txt",
      fare_leg_join_rules.parse,
    )
  let fare_transfer_rules_data =
    load_zip_optional(
      archive,
      "fare_transfer_rules.txt",
      fare_transfer_rules.parse,
    )

  // GTFS-Flex
  let location_groups_data =
    load_zip_optional(archive, "location_groups.txt", location_groups.parse)
  let location_group_stops_data =
    load_zip_optional(
      archive,
      "location_group_stops.txt",
      location_group_stops.parse,
    )
  let locations_data = load_zip_geojson(archive, "locations.geojson")
  let booking_rules_data =
    load_zip_optional(archive, "booking_rules.txt", booking_rules.parse)

  Ok(Feed(
    agencies: agencies,
    stops: stops,
    routes: routes_data,
    trips: trips_data,
    stop_times: stop_times_data,
    calendar: calendar_data,
    calendar_dates: calendar_dates_data,
    feed_info: feed_info_data,
    levels: levels_data,
    shapes: shapes_data,
    frequencies: frequencies_data,
    transfers: transfers_data,
    pathways: pathways_data,
    fare_attributes: fare_attributes_data,
    fare_rules: fare_rules_data,
    translations: translations_data,
    attributions: attributions_data,
    areas: areas_data,
    stop_areas: stop_areas_data,
    networks: networks_data,
    route_networks: route_networks_data,
    timeframes: timeframes_data,
    fare_media: fare_media_data,
    fare_products: fare_products_data,
    fare_leg_rules: fare_leg_rules_data,
    fare_leg_join_rules: fare_leg_join_rules_data,
    fare_transfer_rules: fare_transfer_rules_data,
    location_groups: location_groups_data,
    location_group_stops: location_group_stops_data,
    locations: locations_data,
    booking_rules: booking_rules_data,
  ))
}

/// Load from archive with error collection (collects all errors instead of failing on first)
fn load_from_archive_collect_errors(
  archive: zip.ZipArchive,
) -> Result(Feed, LoadError) {
  let errors: List(LoadError) = []

  // Try loading required files, collecting errors
  let #(agencies_result, errors) =
    try_load_zip_file(archive, "agency.txt", agency.parse, errors)
  let #(stops_result, errors) =
    try_load_zip_file(archive, "stops.txt", stops.parse, errors)
  let #(routes_result, errors) =
    try_load_zip_file(archive, "routes.txt", routes.parse, errors)
  let #(trips_result, errors) =
    try_load_zip_file(archive, "trips.txt", trips.parse, errors)
  let #(stop_times_result, errors) =
    try_load_zip_file(archive, "stop_times.txt", stop_times.parse, errors)

  // If we have any errors from required files, return them
  case errors {
    [] -> {
      // All required files loaded successfully
      let assert Ok(agencies) = agencies_result
      let assert Ok(stops) = stops_result
      let assert Ok(routes_data) = routes_result
      let assert Ok(trips_data) = trips_result
      let assert Ok(stop_times_data) = stop_times_result

      // Load optional files (these don't add to errors)
      let calendar_data =
        load_zip_optional(archive, "calendar.txt", calendar.parse)
      let calendar_dates_data =
        load_zip_optional(archive, "calendar_dates.txt", calendar_dates.parse)
      let feed_info_data =
        load_zip_optional_single(archive, "feed_info.txt", feed_info.parse)
      let levels_data = load_zip_optional(archive, "levels.txt", levels.parse)
      let shapes_data = load_zip_optional(archive, "shapes.txt", shapes.parse)
      let frequencies_data =
        load_zip_optional(archive, "frequencies.txt", frequencies.parse)
      let transfers_data =
        load_zip_optional(archive, "transfers.txt", transfers.parse)
      let pathways_data =
        load_zip_optional(archive, "pathways.txt", pathways.parse)
      let fare_attributes_data =
        load_zip_optional(archive, "fare_attributes.txt", fare_attributes.parse)
      let fare_rules_data =
        load_zip_optional(archive, "fare_rules.txt", fare_rules.parse)
      let translations_data =
        load_zip_optional(archive, "translations.txt", translations.parse)
      let attributions_data =
        load_zip_optional(archive, "attributions.txt", attributions.parse)
      let areas_data = load_zip_optional(archive, "areas.txt", areas.parse)
      let stop_areas_data =
        load_zip_optional(archive, "stop_areas.txt", stop_areas.parse)
      let networks_data =
        load_zip_optional(archive, "networks.txt", networks.parse)
      let route_networks_data =
        load_zip_optional(archive, "route_networks.txt", route_networks.parse)
      let timeframes_data =
        load_zip_optional(archive, "timeframes.txt", timeframes.parse)
      let fare_media_data =
        load_zip_optional(archive, "fare_media.txt", fare_media.parse)
      let fare_products_data =
        load_zip_optional(archive, "fare_products.txt", fare_products.parse)
      let fare_leg_rules_data =
        load_zip_optional(archive, "fare_leg_rules.txt", fare_leg_rules.parse)
      let fare_leg_join_rules_data =
        load_zip_optional(
          archive,
          "fare_leg_join_rules.txt",
          fare_leg_join_rules.parse,
        )
      let fare_transfer_rules_data =
        load_zip_optional(
          archive,
          "fare_transfer_rules.txt",
          fare_transfer_rules.parse,
        )
      let location_groups_data =
        load_zip_optional(archive, "location_groups.txt", location_groups.parse)
      let location_group_stops_data =
        load_zip_optional(
          archive,
          "location_group_stops.txt",
          location_group_stops.parse,
        )
      let locations_data = load_zip_geojson(archive, "locations.geojson")
      let booking_rules_data =
        load_zip_optional(archive, "booking_rules.txt", booking_rules.parse)

      Ok(Feed(
        agencies: agencies,
        stops: stops,
        routes: routes_data,
        trips: trips_data,
        stop_times: stop_times_data,
        calendar: calendar_data,
        calendar_dates: calendar_dates_data,
        feed_info: feed_info_data,
        levels: levels_data,
        shapes: shapes_data,
        frequencies: frequencies_data,
        transfers: transfers_data,
        pathways: pathways_data,
        fare_attributes: fare_attributes_data,
        fare_rules: fare_rules_data,
        translations: translations_data,
        attributions: attributions_data,
        areas: areas_data,
        stop_areas: stop_areas_data,
        networks: networks_data,
        route_networks: route_networks_data,
        timeframes: timeframes_data,
        fare_media: fare_media_data,
        fare_products: fare_products_data,
        fare_leg_rules: fare_leg_rules_data,
        fare_leg_join_rules: fare_leg_join_rules_data,
        fare_transfer_rules: fare_transfer_rules_data,
        location_groups: location_groups_data,
        location_group_stops: location_group_stops_data,
        locations: locations_data,
        booking_rules: booking_rules_data,
      ))
    }
    _ -> Error(MultipleErrors(list.reverse(errors)))
  }
}

fn try_load_zip_file(
  archive: zip.ZipArchive,
  filename: String,
  parser: fn(String) -> Result(a, ParseError),
  errors: List(LoadError),
) -> #(Result(a, LoadError), List(LoadError)) {
  case load_zip_file(archive, filename, parser) {
    Ok(data) -> #(Ok(data), errors)
    Error(err) -> #(Error(err), [err, ..errors])
  }
}

/// Load a GTFS feed from a directory containing extracted files
pub fn load_from_directory(path: String) -> Result(Feed, LoadError) {
  load_from_directory_with_options(path, default_options())
}

/// Load a GTFS feed from a directory with options
pub fn load_from_directory_with_options(
  path: String,
  options: LoadOptions,
) -> Result(Feed, LoadError) {
  use feed <- result.try(
    profile.time_result("static.dir.load_files", fn() {
      load_from_directory_internal(path)
    }),
  )

  case options.validate {
    True -> profile.time_result("static.validate", fn() { validate_feed(feed) })
    False -> Ok(feed)
  }
}

fn load_from_directory_internal(path: String) -> Result(Feed, LoadError) {
  // Load required files
  use agencies <- result.try(load_file(path, "agency.txt", agency.parse))
  use stops <- result.try(load_file(path, "stops.txt", stops.parse))
  use routes_data <- result.try(load_file(path, "routes.txt", routes.parse))
  use trips_data <- result.try(load_file(path, "trips.txt", trips.parse))
  use stop_times_data <- result.try(load_file(
    path,
    "stop_times.txt",
    stop_times.parse,
  ))

  // Load conditionally required files
  let calendar_data = load_optional_file(path, "calendar.txt", calendar.parse)
  let calendar_dates_data =
    load_optional_file(path, "calendar_dates.txt", calendar_dates.parse)
  let feed_info_data =
    load_optional_file_single(path, "feed_info.txt", feed_info.parse)
  let levels_data = load_optional_file(path, "levels.txt", levels.parse)

  // Load optional files
  let shapes_data = load_optional_file(path, "shapes.txt", shapes.parse)
  let frequencies_data =
    load_optional_file(path, "frequencies.txt", frequencies.parse)
  let transfers_data =
    load_optional_file(path, "transfers.txt", transfers.parse)
  let pathways_data = load_optional_file(path, "pathways.txt", pathways.parse)
  let fare_attributes_data =
    load_optional_file(path, "fare_attributes.txt", fare_attributes.parse)
  let fare_rules_data =
    load_optional_file(path, "fare_rules.txt", fare_rules.parse)
  let translations_data =
    load_optional_file(path, "translations.txt", translations.parse)
  let attributions_data =
    load_optional_file(path, "attributions.txt", attributions.parse)

  // GTFS-Fares v2
  let areas_data = load_optional_file(path, "areas.txt", areas.parse)
  let stop_areas_data =
    load_optional_file(path, "stop_areas.txt", stop_areas.parse)
  let networks_data = load_optional_file(path, "networks.txt", networks.parse)
  let route_networks_data =
    load_optional_file(path, "route_networks.txt", route_networks.parse)
  let timeframes_data =
    load_optional_file(path, "timeframes.txt", timeframes.parse)
  let fare_media_data =
    load_optional_file(path, "fare_media.txt", fare_media.parse)
  let fare_products_data =
    load_optional_file(path, "fare_products.txt", fare_products.parse)
  let fare_leg_rules_data =
    load_optional_file(path, "fare_leg_rules.txt", fare_leg_rules.parse)
  let fare_leg_join_rules_data =
    load_optional_file(
      path,
      "fare_leg_join_rules.txt",
      fare_leg_join_rules.parse,
    )
  let fare_transfer_rules_data =
    load_optional_file(
      path,
      "fare_transfer_rules.txt",
      fare_transfer_rules.parse,
    )

  // GTFS-Flex
  let location_groups_data =
    load_optional_file(path, "location_groups.txt", location_groups.parse)
  let location_group_stops_data =
    load_optional_file(
      path,
      "location_group_stops.txt",
      location_group_stops.parse,
    )
  let locations_data = load_geojson_file(path, "locations.geojson")
  let booking_rules_data =
    load_optional_file(path, "booking_rules.txt", booking_rules.parse)

  Ok(Feed(
    agencies: agencies,
    stops: stops,
    routes: routes_data,
    trips: trips_data,
    stop_times: stop_times_data,
    calendar: calendar_data,
    calendar_dates: calendar_dates_data,
    feed_info: feed_info_data,
    levels: levels_data,
    shapes: shapes_data,
    frequencies: frequencies_data,
    transfers: transfers_data,
    pathways: pathways_data,
    fare_attributes: fare_attributes_data,
    fare_rules: fare_rules_data,
    translations: translations_data,
    attributions: attributions_data,
    areas: areas_data,
    stop_areas: stop_areas_data,
    networks: networks_data,
    route_networks: route_networks_data,
    timeframes: timeframes_data,
    fare_media: fare_media_data,
    fare_products: fare_products_data,
    fare_leg_rules: fare_leg_rules_data,
    fare_leg_join_rules: fare_leg_join_rules_data,
    fare_transfer_rules: fare_transfer_rules_data,
    location_groups: location_groups_data,
    location_group_stops: location_group_stops_data,
    locations: locations_data,
    booking_rules: booking_rules_data,
  ))
}

// =============================================================================
// Validation
// =============================================================================

/// Validate a feed and return it if valid, or an error with all validation issues
pub fn validate_feed(feed: Feed) -> Result(Feed, LoadError) {
  let errors =
    profile.time("static.validate.collect_errors", fn() {
      collect_validation_errors(feed)
    })

  case errors {
    [] -> Ok(feed)
    _ -> Error(ValidationErrors(errors))
  }
}

/// Collect all validation errors from a feed without failing
pub fn collect_validation_errors(feed: Feed) -> List(validation.ValidationError) {
  let errors: List(validation.ValidationError) = []

  let profiling = profile.enabled()

  let measure = fn(stage: String, thunk: fn() -> a) -> a {
    case profiling {
      True -> profile.time("static.validate." <> stage, thunk)
      False -> thunk()
    }
  }

  // Check required files presence
  let file_errors =
    measure("required_files", fn() {
      validation.validate_required_files(
        feed.agencies != [],
        feed.stops != [],
        feed.routes != [],
        feed.trips != [],
        feed.stop_times != [],
        option.is_some(feed.calendar),
        option.is_some(feed.calendar_dates),
        option.is_some(feed.locations),
      )
    })
  let errors = list.append(errors, file_errors)

  // Validate duplicates - these return tuples with (ids_set, errors)
  let #(_agency_ids, agency_errors) =
    measure("dup_agency_ids", fn() {
      validation.validate_agency_ids(feed.agencies)
    })
  let errors = list.append(errors, agency_errors)

  let #(stop_ids, stop_errors) =
    measure("dup_stop_ids", fn() { validation.validate_stop_ids(feed.stops) })
  let errors = list.append(errors, stop_errors)

  let #(route_ids, route_errors) =
    measure("dup_route_ids", fn() { validation.validate_route_ids(feed.routes) })
  let errors = list.append(errors, route_errors)

  let #(trip_ids, trip_errors) =
    measure("dup_trip_ids", fn() { validation.validate_trip_ids(feed.trips) })
  let errors = list.append(errors, trip_errors)

  // Build agency_ids and service_ids for reference checking
  let agency_ids =
    measure("build_agency_ids", fn() {
      feed.agencies
      |> list.filter_map(fn(a) { option.to_result(a.agency_id, Nil) })
      |> set.from_list()
    })

  // Get service IDs from calendar and calendar_dates
  let service_ids =
    measure("build_service_ids", fn() {
      let service_ids = case feed.calendar {
        Some(cal) -> {
          cal
          |> list.map(fn(c) { c.service_id })
          |> set.from_list()
        }
        None -> set.new()
      }
      case feed.calendar_dates {
        Some(dates) -> {
          let date_service_ids =
            dates
            |> list.map(fn(d) { d.service_id })
            |> set.from_list()
          set.union(service_ids, date_service_ids)
        }
        None -> service_ids
      }
    })

  // Validate foreign key references
  let single_agency = set.size(agency_ids) <= 1
  let route_agency_errors =
    measure("route_agency_refs", fn() {
      validation.validate_route_agency_refs(
        feed.routes,
        agency_ids,
        single_agency,
      )
    })
  let errors = list.append(errors, route_agency_errors)

  // Shape IDs if available
  let shape_ids =
    measure("build_shape_ids", fn() {
      case feed.shapes {
        Some(shapes) -> {
          shapes
          |> list.map(fn(s) { s.shape_id })
          |> set.from_list()
        }
        None -> set.new()
      }
    })

  let trip_ref_errors =
    measure("trip_refs", fn() {
      validation.validate_trip_refs(
        feed.trips,
        route_ids,
        service_ids,
        shape_ids,
      )
    })
  let errors = list.append(errors, trip_ref_errors)

  let stop_time_errors =
    measure("stop_time_refs", fn() {
      validation.validate_stop_time_refs(feed.stop_times, trip_ids, stop_ids)
    })
  let errors = list.append(errors, stop_time_errors)

  // Validate coordinates
  let coord_errors =
    measure("stop_coordinates", fn() {
      validation.validate_stop_coordinates(feed.stops)
    })
  let errors = list.append(errors, coord_errors)

  // Validate stop time sequences
  let sequence_errors =
    measure("stop_time_sequences", fn() {
      validation.validate_stop_time_sequences(feed.stop_times)
    })
  let errors = list.append(errors, sequence_errors)

  errors
}

/// Create an empty feed
pub fn empty() -> Feed {
  Feed(
    agencies: [],
    stops: [],
    routes: [],
    trips: [],
    stop_times: [],
    calendar: None,
    calendar_dates: None,
    feed_info: None,
    levels: None,
    shapes: None,
    frequencies: None,
    transfers: None,
    pathways: None,
    fare_attributes: None,
    fare_rules: None,
    translations: None,
    attributions: None,
    areas: None,
    stop_areas: None,
    networks: None,
    route_networks: None,
    timeframes: None,
    fare_media: None,
    fare_products: None,
    fare_leg_rules: None,
    fare_leg_join_rules: None,
    fare_transfer_rules: None,
    location_groups: None,
    location_group_stops: None,
    locations: None,
    booking_rules: None,
  )
}

// =============================================================================
// File Loading Helpers (Directory)
// =============================================================================

fn load_file(
  dir: String,
  filename: String,
  parser: fn(String) -> Result(a, ParseError),
) -> Result(a, LoadError) {
  let filepath = dir <> "/" <> filename

  profile.time_result("static.file." <> filename, fn() {
    case simplifile.read(filepath) {
      Ok(content) -> {
        case parser(content) {
          Ok(data) -> Ok(data)
          Error(parse_error) -> Error(CsvParseError(filename, parse_error))
        }
      }
      Error(_) -> Error(MissingRequiredFile(filename))
    }
  })
}

fn load_optional_file(
  dir: String,
  filename: String,
  parser: fn(String) -> Result(a, ParseError),
) -> Option(a) {
  let filepath = dir <> "/" <> filename

  profile.time("static.file." <> filename, fn() {
    case simplifile.read(filepath) {
      Ok(content) -> {
        case parser(content) {
          Ok(data) -> Some(data)
          Error(_) -> None
        }
      }
      Error(_) -> None
    }
  })
}

fn load_optional_file_single(
  dir: String,
  filename: String,
  parser: fn(String) -> Result(Option(a), ParseError),
) -> Option(a) {
  let filepath = dir <> "/" <> filename

  profile.time("static.file." <> filename, fn() {
    case simplifile.read(filepath) {
      Ok(content) -> {
        case parser(content) {
          Ok(data) -> data
          Error(_) -> None
        }
      }
      Error(_) -> None
    }
  })
}

fn load_geojson_file(dir: String, filename: String) -> Option(LocationsGeoJson) {
  let filepath = dir <> "/" <> filename

  profile.time("static.file." <> filename, fn() {
    case simplifile.read(filepath) {
      Ok(content) -> {
        case locations_geojson.parse(content) {
          Ok(data) -> Some(data)
          Error(_) -> None
        }
      }
      Error(_) -> None
    }
  })
}

// =============================================================================
// File Loading Helpers (ZIP)
// =============================================================================

fn load_zip_file(
  archive: zip.ZipArchive,
  filename: String,
  parser: fn(String) -> Result(a, ParseError),
) -> Result(a, LoadError) {
  profile.time_result("static.zip." <> filename, fn() {
    case zip.extract_string(archive, filename) {
      Ok(content) -> {
        case parser(content) {
          Ok(data) -> Ok(data)
          Error(parse_error) -> Error(CsvParseError(filename, parse_error))
        }
      }
      Error(_) -> Error(MissingRequiredFile(filename))
    }
  })
}

fn load_zip_optional(
  archive: zip.ZipArchive,
  filename: String,
  parser: fn(String) -> Result(a, ParseError),
) -> Option(a) {
  profile.time("static.zip." <> filename, fn() {
    case zip.extract_string(archive, filename) {
      Ok(content) -> {
        case parser(content) {
          Ok(data) -> Some(data)
          Error(_) -> None
        }
      }
      Error(_) -> None
    }
  })
}

fn load_zip_optional_single(
  archive: zip.ZipArchive,
  filename: String,
  parser: fn(String) -> Result(Option(a), ParseError),
) -> Option(a) {
  profile.time("static.zip." <> filename, fn() {
    case zip.extract_string(archive, filename) {
      Ok(content) -> {
        case parser(content) {
          Ok(data) -> data
          Error(_) -> None
        }
      }
      Error(_) -> None
    }
  })
}

fn load_zip_geojson(
  archive: zip.ZipArchive,
  filename: String,
) -> Option(LocationsGeoJson) {
  profile.time("static.zip." <> filename, fn() {
    case zip.extract_string(archive, filename) {
      Ok(content) -> {
        case locations_geojson.parse(content) {
          Ok(data) -> Some(data)
          Error(_) -> None
        }
      }
      Error(_) -> None
    }
  })
}

// =============================================================================
// Feed Queries
// =============================================================================

/// Get an agency by ID
pub fn get_agency(feed: Feed, agency_id: String) -> Option(Agency) {
  list.find(feed.agencies, fn(a) {
    case a.agency_id {
      Some(id) -> id == agency_id
      None -> False
    }
  })
  |> option.from_result
}

/// Get a stop by ID
pub fn get_stop(feed: Feed, stop_id: String) -> Option(Stop) {
  list.find(feed.stops, fn(s) { s.stop_id == stop_id })
  |> option.from_result
}

/// Get a route by ID
pub fn get_route(feed: Feed, route_id: String) -> Option(Route) {
  list.find(feed.routes, fn(r) { r.route_id == route_id })
  |> option.from_result
}

/// Get a trip by ID
pub fn get_trip(feed: Feed, trip_id: String) -> Option(Trip) {
  list.find(feed.trips, fn(t) { t.trip_id == trip_id })
  |> option.from_result
}

/// Get all stop times for a trip, sorted by stop_sequence
pub fn get_stop_times_for_trip(feed: Feed, trip_id: String) -> List(StopTime) {
  feed.stop_times
  |> list.filter(fn(st) { st.trip_id == trip_id })
  |> list.sort(fn(a, b) { int.compare(a.stop_sequence, b.stop_sequence) })
}

/// Get all trips for a route
pub fn get_trips_for_route(feed: Feed, route_id: String) -> List(Trip) {
  list.filter(feed.trips, fn(t) { t.route_id == route_id })
}

/// Get all routes for an agency
pub fn get_routes_for_agency(feed: Feed, agency_id: String) -> List(Route) {
  list.filter(feed.routes, fn(r) {
    case r.agency_id {
      Some(id) -> id == agency_id
      None -> False
    }
  })
}

/// Get all shape points for a shape, sorted by sequence
pub fn get_shape_points(feed: Feed, shape_id: String) -> List(ShapePoint) {
  case feed.shapes {
    Some(shapes_list) ->
      shapes_list
      |> list.filter(fn(s) { s.shape_id == shape_id })
      |> list.sort(fn(a, b) {
        int.compare(a.shape_pt_sequence, b.shape_pt_sequence)
      })
    None -> []
  }
}

/// Get all stop times for a stop
pub fn get_stop_times_for_stop(feed: Feed, stop_id: String) -> List(StopTime) {
  feed.stop_times
  |> list.filter(fn(st) {
    case st.stop_id {
      Some(sid) -> sid == stop_id
      None -> False
    }
  })
}

/// Get calendar entry by service_id
pub fn get_calendar(feed: Feed, service_id: String) -> Option(Calendar) {
  case feed.calendar {
    Some(cal_list) ->
      list.find(cal_list, fn(c) { c.service_id == service_id })
      |> option.from_result
    None -> None
  }
}

/// Get all calendar dates for a service_id
pub fn get_calendar_dates(feed: Feed, service_id: String) -> List(CalendarDate) {
  case feed.calendar_dates {
    Some(dates) -> list.filter(dates, fn(cd) { cd.service_id == service_id })
    None -> []
  }
}

/// Get all frequencies for a trip
pub fn get_frequencies_for_trip(feed: Feed, trip_id: String) -> List(Frequency) {
  case feed.frequencies {
    Some(freqs) -> list.filter(freqs, fn(f) { f.trip_id == trip_id })
    None -> []
  }
}

/// Get all pathways from a stop
pub fn get_pathways_from_stop(feed: Feed, stop_id: String) -> List(Pathway) {
  case feed.pathways {
    Some(paths) -> list.filter(paths, fn(p) { p.from_stop_id == stop_id })
    None -> []
  }
}

/// Get a level by ID
pub fn get_level(feed: Feed, level_id: String) -> Option(Level) {
  case feed.levels {
    Some(levels_list) ->
      list.find(levels_list, fn(l) { l.level_id == level_id })
      |> option.from_result
    None -> None
  }
}

/// Get fare attributes by ID
pub fn get_fare_attribute(feed: Feed, fare_id: String) -> Option(FareAttribute) {
  case feed.fare_attributes {
    Some(fares) ->
      list.find(fares, fn(f) { f.fare_id == fare_id })
      |> option.from_result
    None -> None
  }
}

/// Get fare rules for a fare ID
pub fn get_fare_rules(feed: Feed, fare_id: String) -> List(FareRule) {
  case feed.fare_rules {
    Some(rules) -> list.filter(rules, fn(r) { r.fare_id == fare_id })
    None -> []
  }
}
