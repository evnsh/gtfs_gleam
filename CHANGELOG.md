# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-02

### Added

- **GTFS Static Support**
  - Complete parsing for all 30 GTFS static file types
  - Core files: agency.txt, stops.txt, routes.txt, trips.txt, stop_times.txt
  - Calendar files: calendar.txt, calendar_dates.txt
  - Optional files: shapes.txt, frequencies.txt, transfers.txt, pathways.txt, levels.txt
  - Feed information: feed_info.txt, attributions.txt, translations.txt
  - GTFS-Fares v1: fare_attributes.txt, fare_rules.txt
  - GTFS-Fares v2: fare_media.txt, fare_products.txt, fare_leg_rules.txt, fare_transfer_rules.txt, areas.txt, stop_areas.txt, networks.txt, route_networks.txt, timeframes.txt
  - GTFS-Flex: location_groups.txt, location_group_stops.txt, booking_rules.txt, locations.geojson
  - Feed loading from ZIP files

- **GTFS Realtime Support**
  - Protocol Buffer decoding for GTFS-RT v2.0
  - Trip updates with stop time updates and delays
  - Vehicle positions with location and status
  - Service alerts with multi-language support
  - Experimental features: shapes, stops, trip modifications

- **Common Utilities**
  - Time parsing including overnight times (> 24:00:00)
  - Date parsing (YYYYMMDD format)
  - Geographic distance calculations (Haversine, Vincenty)
  - Polyline encoding and decoding
  - GeoJSON parsing for flex zones

- **Type Safety**
  - Comprehensive type definitions for all GTFS entities
  - Strongly-typed enumerations for route types, location types, etc.
  - Support for [Extended Route Types](https://developers.google.com/transit/gtfs/reference/extended-route-types) (100-1799)
  - Option types for nullable fields
  - Clear separation between static and realtime types

- **Developer Experience**
  - Comprehensive test suite
  - Example code for static and realtime feeds
  - CI/CD with GitHub Actions
  - Documentation

### Dependencies

- gleam_stdlib >= 0.44.0
- simplifile >= 2.0.0
- filepath >= 1.0.0
- protobin >= 2.0.0
- gleeunit (dev)
