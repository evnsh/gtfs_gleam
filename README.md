# gtfs_gleam

[![Package Version](https://img.shields.io/hexpm/v/gtfs_gleam)](https://hex.pm/packages/gtfs_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gtfs_gleam/)

A comprehensive, type-safe GTFS (General Transit Feed Specification) library for Gleam, supporting both **GTFS Static** (schedule data) and **GTFS Realtime** (live updates).

## Features

- **Complete GTFS Static support**: All 30+ file types including Fares v2 and GTFS-Flex
- **GTFS Realtime decoding**: Trip updates, vehicle positions, and alerts via Protocol Buffers
- **Type-safe**: Comprehensive Gleam types for all GTFS entities
- **Extended route types**: Support for [Google Transit Extended Route Types](https://developers.google.com/transit/gtfs/reference/extended-route-types) (100-1799)
- **ZIP support**: Load feeds directly from ZIP archives
- **Validation**: Built-in feed validation for required files, foreign keys, and semantic rules
- **Geographic utilities**: Haversine distance, polyline encoding/decoding, point-in-polygon
- **Zero runtime dependencies**: Pure Gleam with minimal Erlang FFI

## Installation

```sh
gleam add gtfs_gleam
```

## Quick Start

### Loading a GTFS Static Feed

```gleam
import gtfs/static/feed

pub fn main() {
  // Load from a directory
  let assert Ok(feed) = feed.load_from_directory("./gtfs_data")
  
  // Or load from a ZIP file
  let assert Ok(feed) = feed.load_from_zip("./gtfs.zip")
  
  // Access the data
  io.println("Routes: " <> int.to_string(list.length(feed.routes)))
  io.println("Stops: " <> int.to_string(list.length(feed.stops)))
  
  // Query the feed
  let route = feed.get_route(feed, "route_1")
  let stop = feed.get_stop(feed, "stop_100")
}
```

### Decoding GTFS Realtime

```gleam
import gtfs/realtime/feed as rt_feed

pub fn handle_realtime(data: BitArray) {
  // Decode a protobuf feed
  let assert Ok(feed) = rt_feed.decode(data)
  
  // Get all trip updates
  let trip_updates = rt_feed.get_trip_updates(feed)
  
  // Get all vehicle positions  
  let vehicles = rt_feed.get_vehicle_positions(feed)
  
  // Get all alerts
  let alerts = rt_feed.get_alerts(feed)
  
  // Query specific data
  let delay = rt_feed.get_trip_delay(feed, "trip_123")
  let vehicle = rt_feed.get_vehicle_position(feed, "vehicle_456")
  let route_alerts = rt_feed.get_alerts_for_route(feed, "route_1")
}
```

### Parsing Individual Files

```gleam
import gtfs/static/files/agency
import gtfs/static/files/routes
import gtfs/static/files/stops

pub fn parse_files() {
  // Parse agency.txt
  let assert Ok(agencies) = agency.parse("./gtfs_data/agency.txt")
  
  // Parse routes.txt
  let assert Ok(routes) = routes.parse("./gtfs_data/routes.txt")
  
  // Parse stops.txt
  let assert Ok(stops) = stops.parse("./gtfs_data/stops.txt")
}
```

### Geographic Utilities

```gleam
import gtfs/common/geo

pub fn geo_example() {
  // Calculate distance between two points (in km)
  let distance = geo.distance_km(
    40.7128, -74.0060,  // New York
    34.0522, -118.2437  // Los Angeles
  )
  
  // Decode a polyline
  let points = geo.decode_polyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@")
  
  // Check if point is in polygon
  let in_bounds = geo.point_in_polygon(lat, lon, polygon_points)
}
```

### Feed Validation

```gleam
import gtfs/static/validation as v

pub fn validate_feed(feed: Feed) {
  // Validate required files
  let context = v.ValidationContext(
    has_stops: True,
    has_locations_geojson: False,
    has_calendar: True,
    has_calendar_dates: True,
  )
  let file_errors = v.validate_required_files(context)
  
  // Validate foreign key relationships
  let route_errors = v.validate_route_refs(feed.trips, feed.routes)
  let stop_errors = v.validate_stop_refs(feed.stop_times, feed.stops)
  
  // Validate semantic rules
  let coord_errors = v.validate_stop_coordinates(feed.stops)
  let time_errors = v.validate_stop_time_sequences(feed.stop_times)
}
```

## Module Structure

### Static (Schedule Data)
- `gtfs/static/feed` - Load and query complete GTFS feeds
- `gtfs/static/types` - All GTFS Static type definitions
- `gtfs/static/validation` - Feed validation utilities
- `gtfs/static/files/*` - Individual file parsers (30+ files)

### Realtime (Live Updates)
- `gtfs/realtime/feed` - Decode and query GTFS Realtime feeds
- `gtfs/realtime/types` - All GTFS Realtime type definitions
- `gtfs/realtime/decoder` - Protocol Buffer decoder

### Common
- `gtfs/common/types` - Shared types (Date, Time, Coordinate, etc.)
- `gtfs/common/time` - Time parsing and manipulation
- `gtfs/common/geo` - Geographic utilities

## Supported GTFS Files

### Core Files
- `agency.txt` - Transit agencies
- `stops.txt` - Stop/station locations
- `routes.txt` - Transit routes (supports [extended route types](https://developers.google.com/transit/gtfs/reference/extended-route-types))
- `trips.txt` - Trips for each route
- `stop_times.txt` - Times at each stop
- `calendar.txt` - Service dates
- `calendar_dates.txt` - Service exceptions

### Optional Files
- `fare_attributes.txt` / `fare_rules.txt` - Fares v1
- `shapes.txt` - Route shapes
- `frequencies.txt` - Frequency-based service
- `transfers.txt` - Transfer rules
- `pathways.txt` - Station pathways
- `levels.txt` - Station levels
- `feed_info.txt` - Feed metadata
- `translations.txt` - Translations
- `attributions.txt` - Dataset attributions

### Fares v2 Files
- `areas.txt`, `stop_areas.txt`
- `networks.txt`, `route_networks.txt`
- `timeframes.txt`
- `fare_media.txt`, `fare_products.txt`
- `fare_leg_rules.txt`, `fare_transfer_rules.txt`

### GTFS-Flex Files
- `location_groups.txt`, `location_group_stops.txt`
- `booking_rules.txt`
- `locations.geojson`

## GTFS Realtime Support

Full support for decoding GTFS Realtime Protocol Buffer feeds:

- **Feed Message** - Header and entity list
- **Trip Updates** - Arrival/departure predictions, delays
- **Vehicle Positions** - Real-time vehicle locations
- **Alerts** - Service alerts and notifications
- **Trip Modifications** - Detours and trip changes (experimental)
- **Shapes** - Real-time shape updates (experimental)

## Development

```sh
gleam build   # Build the project
gleam test    # Run the tests
gleam docs build  # Generate documentation
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## References

- [GTFS Static Reference](https://gtfs.org/schedule/reference/)
- [GTFS Realtime Reference](https://gtfs.org/realtime/reference/)
- [GTFS Best Practices](https://gtfs.org/schedule/best-practices/)
