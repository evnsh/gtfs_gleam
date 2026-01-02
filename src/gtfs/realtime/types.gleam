//// GTFS Realtime Types
////
//// Type definitions for GTFS Realtime Protocol Buffer messages.
//// Based on gtfs-realtime.proto specification.
//// Source: https://github.com/google/transit/blob/master/gtfs-realtime/proto/gtfs-realtime.proto

import gleam/option.{type Option}

// =============================================================================
// Feed Message - Top Level
// =============================================================================

/// The contents of a feed message.
/// A feed is a continuous stream of feed messages.
pub type FeedMessage {
  FeedMessage(
    /// Metadata about this feed and feed message
    header: FeedHeader,
    /// Contents of the feed - list of entities
    entity: List(FeedEntity),
  )
}

/// Metadata about a feed, included in feed messages.
pub type FeedHeader {
  FeedHeader(
    /// Version of the feed specification ("2.0" or "1.0")
    gtfs_realtime_version: String,
    /// Whether the current fetch is incremental
    incrementality: Incrementality,
    /// Timestamp when the content was created (POSIX time)
    timestamp: Option(Int),
    /// String that matches feed_info.feed_version from GTFS feed
    feed_version: Option(String),
  )
}

/// Determines whether the current fetch is incremental
pub type Incrementality {
  FullDataset
  Differential
}

/// A definition (or update) of an entity in the transit feed.
pub type FeedEntity {
  FeedEntity(
    /// Unique identifier for this entity within the feed
    id: String,
    /// Whether this entity is to be deleted (for incremental fetches)
    is_deleted: Bool,
    /// Trip update data (optional)
    trip_update: Option(TripUpdate),
    /// Vehicle position data (optional)
    vehicle: Option(VehiclePosition),
    /// Alert data (optional)
    alert: Option(Alert),
    /// Shape data (experimental)
    shape: Option(Shape),
    /// Stop data (experimental)
    stop: Option(RealtimeStop),
    /// Trip modifications (experimental)
    trip_modifications: Option(TripModifications),
  )
}

// =============================================================================
// Trip Update
// =============================================================================

/// Realtime update of the progress of a vehicle along a trip.
pub type TripUpdate {
  TripUpdate(
    /// The trip that this message applies to
    trip: TripDescriptor,
    /// Additional information on the vehicle serving this trip
    vehicle: Option(VehicleDescriptor),
    /// Updates to StopTimes for the trip
    stop_time_update: List(StopTimeUpdate),
    /// Timestamp of the most recent real-time progress measurement
    timestamp: Option(Int),
    /// Current schedule deviation for the trip (seconds, positive = late)
    delay: Option(Int),
    /// Updated properties of the trip (experimental)
    trip_properties: Option(TripProperties),
  )
}

/// Timing information for a single predicted event (arrival or departure)
pub type StopTimeEvent {
  StopTimeEvent(
    /// Delay in seconds (positive = late, negative = early)
    delay: Option(Int),
    /// Event as absolute time (Unix timestamp)
    time: Option(Int),
    /// Uncertainty of the prediction
    uncertainty: Option(Int),
    /// Scheduled time for NEW/REPLACEMENT/DUPLICATED trips (experimental)
    scheduled_time: Option(Int),
  )
}

/// Realtime update for arrival/departure events for a given stop
pub type StopTimeUpdate {
  StopTimeUpdate(
    /// Stop sequence (must match stop_times.txt)
    stop_sequence: Option(Int),
    /// Stop ID (must match stops.txt)
    stop_id: Option(String),
    /// Arrival time update
    arrival: Option(StopTimeEvent),
    /// Departure time update
    departure: Option(StopTimeEvent),
    /// Expected occupancy after departure (experimental)
    departure_occupancy_status: Option(OccupancyStatus),
    /// Relationship between this update and the static schedule
    schedule_relationship: StopTimeScheduleRelationship,
    /// Updated stop time properties (experimental)
    stop_time_properties: Option(StopTimeProperties),
  )
}

/// The relation between StopTimeEvents and the static schedule
pub type StopTimeScheduleRelationship {
  /// Vehicle proceeding according to schedule
  StopScheduled
  /// Stop is skipped
  StopSkipped
  /// No data for this stop
  StopNoData
  /// For frequency-based trips with exact_times=0
  StopUnscheduled
}

/// Updated values for stop time (experimental)
pub type StopTimeProperties {
  StopTimeProperties(
    /// Real-time stop assignment
    assigned_stop_id: Option(String),
    /// Updated headsign at the stop
    stop_headsign: Option(String),
    /// Updated pickup type
    pickup_type: Option(DropOffPickupType),
    /// Updated drop off type
    drop_off_type: Option(DropOffPickupType),
  )
}

/// Drop off/pickup types for real-time updates
pub type DropOffPickupType {
  /// Regularly scheduled
  Regular
  /// Not available
  NoPickupDropOff
  /// Must phone agency
  PhoneAgency
  /// Must coordinate with driver
  CoordinateWithDriver
}

/// Updated properties of a trip (experimental)
pub type TripProperties {
  TripProperties(
    /// New trip_id for duplicated trips
    trip_id: Option(String),
    /// Service date for duplicated trips (YYYYMMDD)
    start_date: Option(String),
    /// Start time for duplicated trips
    start_time: Option(String),
    /// Shape ID when different from GTFS
    shape_id: Option(String),
    /// Updated headsign
    trip_headsign: Option(String),
    /// Updated short name
    trip_short_name: Option(String),
  )
}

// =============================================================================
// Vehicle Position
// =============================================================================

/// Realtime positioning information for a given vehicle.
pub type VehiclePosition {
  VehiclePosition(
    /// The trip that this vehicle is serving
    trip: Option(TripDescriptor),
    /// Additional information on the vehicle
    vehicle: Option(VehicleDescriptor),
    /// Current position of this vehicle
    position: Option(Position),
    /// Stop sequence index of the current stop
    current_stop_sequence: Option(Int),
    /// Current stop ID
    stop_id: Option(String),
    /// Status with respect to the current stop
    current_status: VehicleStopStatus,
    /// Timestamp of the position measurement
    timestamp: Option(Int),
    /// Congestion level affecting this vehicle
    congestion_level: CongestionLevel,
    /// Occupancy status of the vehicle
    occupancy_status: Option(OccupancyStatus),
    /// Occupancy percentage (0-100+)
    occupancy_percentage: Option(Int),
    /// Details of multiple carriages (experimental)
    multi_carriage_details: List(CarriageDetails),
  )
}

/// A position (latitude, longitude, bearing, etc.)
pub type Position {
  Position(
    /// Degrees North, WGS-84
    latitude: Float,
    /// Degrees East, WGS-84
    longitude: Float,
    /// Bearing in degrees, clockwise from North
    bearing: Option(Float),
    /// Odometer value in meters
    odometer: Option(Float),
    /// Speed in meters per second
    speed: Option(Float),
  )
}

/// Vehicle stop status
pub type VehicleStopStatus {
  /// Vehicle just about to arrive at the stop
  IncomingAt
  /// Vehicle standing at the stop
  StoppedAt
  /// Vehicle in transit to the next stop
  InTransitTo
}

/// Congestion level
pub type CongestionLevel {
  UnknownCongestionLevel
  RunningSmoothly
  StopAndGo
  Congestion
  SevereCongestion
}

/// Occupancy status of the vehicle or carriage
pub type OccupancyStatus {
  Empty
  ManySeatsAvailable
  FewSeatsAvailable
  StandingRoomOnly
  CrushedStandingRoomOnly
  Full
  NotAcceptingPassengers
  NoDataAvailable
  NotBoardable
}

/// Carriage-specific details for multi-carriage vehicles (experimental)
pub type CarriageDetails {
  CarriageDetails(
    /// Carriage identifier
    id: Option(String),
    /// User-visible label
    label: Option(String),
    /// Occupancy status for this carriage
    occupancy_status: OccupancyStatus,
    /// Occupancy percentage (-1 if not available)
    occupancy_percentage: Int,
    /// Order of this carriage (1 = first in direction of travel)
    carriage_sequence: Option(Int),
  )
}

// =============================================================================
// Alert
// =============================================================================

/// An alert indicating some sort of incident in the public transit network.
pub type Alert {
  Alert(
    /// Time periods when the alert should be shown
    active_period: List(TimeRange),
    /// Entities affected by this alert
    informed_entity: List(EntitySelector),
    /// Cause of this alert
    cause: AlertCause,
    /// Effect of this alert
    effect: AlertEffect,
    /// URL with additional information
    url: Option(TranslatedString),
    /// Alert header (short summary)
    header_text: Option(TranslatedString),
    /// Full description
    description_text: Option(TranslatedString),
    /// Text-to-speech version of header
    tts_header_text: Option(TranslatedString),
    /// Text-to-speech version of description
    tts_description_text: Option(TranslatedString),
    /// Severity level
    severity_level: SeverityLevel,
    /// Image to display (experimental)
    image: Option(TranslatedImage),
    /// Alt text for image (experimental)
    image_alternative_text: Option(TranslatedString),
    /// Detailed cause description (experimental)
    cause_detail: Option(TranslatedString),
    /// Detailed effect description (experimental)
    effect_detail: Option(TranslatedString),
  )
}

/// Cause of an alert
pub type AlertCause {
  UnknownCause
  OtherCause
  TechnicalProblem
  Strike
  Demonstration
  Accident
  Holiday
  Weather
  Maintenance
  Construction
  PoliceActivity
  MedicalEmergency
}

/// Effect of an alert
pub type AlertEffect {
  NoService
  ReducedService
  SignificantDelays
  Detour
  AdditionalService
  ModifiedService
  OtherEffect
  UnknownEffect
  StopMoved
  NoEffect
  AccessibilityIssue
}

/// Severity level of an alert
pub type SeverityLevel {
  UnknownSeverity
  Info
  Warning
  Severe
}

/// A time range (start and/or end time)
pub type TimeRange {
  TimeRange(
    /// Start time (POSIX time), or minus infinity if missing
    start: Option(Int),
    /// End time (POSIX time), or plus infinity if missing
    end: Option(Int),
  )
}

/// Selector for entities in a GTFS feed
pub type EntitySelector {
  EntitySelector(
    agency_id: Option(String),
    route_id: Option(String),
    route_type: Option(Int),
    trip: Option(TripDescriptor),
    stop_id: Option(String),
    direction_id: Option(Int),
  )
}

/// Internationalized text with translations
pub type TranslatedString {
  TranslatedString(translation: List(Translation))
}

/// A single translation
pub type Translation {
  Translation(
    /// The translated text (UTF-8)
    text: String,
    /// BCP-47 language code (optional)
    language: Option(String),
  )
}

/// Internationalized image (experimental)
pub type TranslatedImage {
  TranslatedImage(localized_image: List(LocalizedImage))
}

/// A localized image
pub type LocalizedImage {
  LocalizedImage(
    /// URL linking to the image
    url: String,
    /// IANA media type (e.g., "image/png")
    media_type: String,
    /// BCP-47 language code (optional)
    language: Option(String),
  )
}

// =============================================================================
// Common Types
// =============================================================================

/// A descriptor that identifies an instance of a GTFS trip
pub type TripDescriptor {
  TripDescriptor(
    /// Trip ID from the GTFS feed
    trip_id: Option(String),
    /// Route ID from the GTFS feed
    route_id: Option(String),
    /// Direction ID (0 or 1)
    direction_id: Option(Int),
    /// Start time for frequency-based trips (HH:MM:SS)
    start_time: Option(String),
    /// Start date (YYYYMMDD)
    start_date: Option(String),
    /// Relationship to the static schedule
    schedule_relationship: TripScheduleRelationship,
    /// Linkage to modifications (experimental)
    modified_trip: Option(ModifiedTripSelector),
  )
}

/// Trip schedule relationship
pub type TripScheduleRelationship {
  TripScheduled
  TripAdded
  TripUnscheduled
  TripCanceled
  TripReplacement
  TripDuplicated
  TripDeleted
  TripNew
}

/// Modified trip selector (experimental)
pub type ModifiedTripSelector {
  ModifiedTripSelector(
    /// ID of the FeedEntity with TripModifications
    modifications_id: Option(String),
    /// Trip ID being modified
    affected_trip_id: Option(String),
    /// Start time (for frequency-based trips)
    start_time: Option(String),
    /// Start date (YYYYMMDD)
    start_date: Option(String),
  )
}

/// Identification information for a vehicle
pub type VehicleDescriptor {
  VehicleDescriptor(
    /// Internal system ID of the vehicle
    id: Option(String),
    /// User-visible label
    label: Option(String),
    /// License plate
    license_plate: Option(String),
    /// Wheelchair accessibility
    wheelchair_accessible: WheelchairAccessible,
  )
}

/// Wheelchair accessibility for a vehicle
pub type WheelchairAccessible {
  /// No information (default, doesn't override GTFS)
  WheelchairNoValue
  /// Unknown accessibility (overrides GTFS)
  WheelchairUnknown
  /// Vehicle is wheelchair accessible
  WheelchairAccessibleVehicle
  /// Vehicle is not wheelchair accessible
  WheelchairInaccessible
}

// =============================================================================
// Shape (Experimental)
// =============================================================================

/// A shape that describes the vehicle's travel path (experimental)
pub type Shape {
  Shape(
    /// Shape ID (different from GTFS shapes)
    shape_id: Option(String),
    /// Encoded polyline representation
    encoded_polyline: Option(String),
  )
}

// =============================================================================
// Realtime Stop (Experimental)
// =============================================================================

/// A stop served by trips (experimental)
pub type RealtimeStop {
  RealtimeStop(
    stop_id: Option(String),
    stop_code: Option(TranslatedString),
    stop_name: Option(TranslatedString),
    tts_stop_name: Option(TranslatedString),
    stop_desc: Option(TranslatedString),
    stop_lat: Option(Float),
    stop_lon: Option(Float),
    zone_id: Option(String),
    stop_url: Option(TranslatedString),
    parent_station: Option(String),
    stop_timezone: Option(String),
    wheelchair_boarding: RealtimeWheelchairBoarding,
    level_id: Option(String),
    platform_code: Option(TranslatedString),
  )
}

/// Wheelchair boarding for realtime stops
pub type RealtimeWheelchairBoarding {
  RealtimeWheelchairUnknown
  RealtimeWheelchairAvailable
  RealtimeWheelchairNotAvailable
}

// =============================================================================
// Trip Modifications (Experimental)
// =============================================================================

/// Trip modifications for detours, etc. (experimental)
pub type TripModifications {
  TripModifications(
    /// List of selected trips affected
    selected_trips: List(SelectedTrips),
    /// Start times for frequency-based trips
    start_times: List(String),
    /// Service dates (YYYYMMDD)
    service_dates: List(String),
    /// List of modifications
    modifications: List(Modification),
  )
}

/// Selected trips for modifications
pub type SelectedTrips {
  SelectedTrips(
    /// List of trip IDs affected
    trip_ids: List(String),
    /// New shape ID for modified trips
    shape_id: Option(String),
  )
}

/// A modification to a trip
pub type Modification {
  Modification(
    /// Start stop selector
    start_stop_selector: Option(StopSelector),
    /// End stop selector
    end_stop_selector: Option(StopSelector),
    /// Delay to add to following times
    propagated_modification_delay: Int,
    /// Replacement stops
    replacement_stops: List(ReplacementStop),
    /// ID of alert describing this modification
    service_alert_id: Option(String),
    /// Last modification timestamp
    last_modified_time: Option(Int),
  )
}

/// Stop selector for modifications
pub type StopSelector {
  StopSelector(
    /// Stop sequence
    stop_sequence: Option(Int),
    /// Stop ID
    stop_id: Option(String),
  )
}

/// Replacement stop for modifications
pub type ReplacementStop {
  ReplacementStop(
    /// Travel time to this stop from reference (seconds)
    travel_time_to_stop: Option(Int),
    /// Replacement stop ID
    stop_id: Option(String),
  )
}
