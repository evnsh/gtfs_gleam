//// GTFS Static Types
////
//// This module contains all type definitions for GTFS Static files.
//// Types are organized by their source file in the GTFS specification.

import gleam/option.{type Option}
import gtfs/common/types.{
  type Color, type Coordinate, type CurrencyAmount, type CurrencyCode, type Date,
  type Email, type LanguageCode, type PhoneNumber, type Time, type Timezone,
  type Url,
}

// =============================================================================
// agency.txt Types
// Source: GTFS reference.md - Dataset Files > agency.txt
// =============================================================================

/// Represents a transit agency from agency.txt
pub type Agency {
  Agency(
    /// Unique identifier for the agency. Required if multiple agencies.
    agency_id: Option(String),
    /// Full name of the transit agency. Required.
    agency_name: String,
    /// URL of the transit agency's website. Required.
    agency_url: Url,
    /// Timezone of the agency. Required.
    agency_timezone: Timezone,
    /// Primary language used by this agency. Optional.
    agency_lang: Option(LanguageCode),
    /// Voice telephone number for the agency. Optional.
    agency_phone: Option(PhoneNumber),
    /// URL of a web page for purchasing tickets online. Optional.
    agency_fare_url: Option(Url),
    /// Email address for customer service. Optional.
    agency_email: Option(Email),
    /// Contactless EMV payment support. Optional.
    cemv_support: CemvSupport,
  )
}

/// Contactless EMV payment support indicator
/// Source: GTFS reference.md - agency.txt > cemv_support
pub type CemvSupport {
  /// No CEMV information (0 or empty)
  NoCemvInfo
  /// CEMV supported (1)
  CemvSupported
  /// CEMV not supported (2)
  CemvNotSupported
}

// =============================================================================
// stops.txt Types
// Source: GTFS reference.md - Dataset Files > stops.txt
// =============================================================================

/// Represents a stop, station, or other location from stops.txt
pub type Stop {
  Stop(
    /// Unique identifier for the stop. Required.
    stop_id: String,
    /// Short text or number identifying the stop for riders. Optional.
    stop_code: Option(String),
    /// Name of the stop. Conditionally required.
    stop_name: Option(String),
    /// Text-to-speech pronunciation of the stop name. Optional.
    tts_stop_name: Option(String),
    /// Description of the stop. Optional.
    stop_desc: Option(String),
    /// Latitude of the stop. Conditionally required.
    stop_lat: Option(Float),
    /// Longitude of the stop. Conditionally required.
    stop_lon: Option(Float),
    /// Fare zone ID. Optional.
    zone_id: Option(String),
    /// URL of a web page about the stop. Optional.
    stop_url: Option(Url),
    /// Type of location. Optional (default: StopOrPlatform).
    location_type: LocationType,
    /// Parent station ID. Conditionally required.
    parent_station: Option(String),
    /// Timezone of the stop. Optional.
    stop_timezone: Option(Timezone),
    /// Wheelchair boarding accessibility. Optional.
    wheelchair_boarding: WheelchairBoarding,
    /// Level ID for multi-level stations. Optional.
    level_id: Option(String),
    /// Platform identifier. Optional.
    platform_code: Option(String),
    /// Stop access indicator for pathway stations. Conditionally Forbidden.
    stop_access: Option(StopAccess),
  )
}

/// Stop access indicator (for pathway stations)
/// Source: GTFS reference.md - stops.txt > stop_access
/// Conditionally Forbidden for stations, entrances, generic nodes, boarding areas
pub type StopAccess {
  /// Must use entrance/pathways (0)
  MustUsePathways
  /// Direct access from street (1)
  DirectStreetAccess
}

/// Location type enum for stops
/// Source: GTFS reference.md - stops.txt > location_type
pub type LocationType {
  /// Stop or platform where passengers board/alight (0 or empty)
  StopOrPlatform
  /// Station containing one or more platforms (1)
  Station
  /// Entrance/exit from street to station (2)
  EntranceExit
  /// Generic node for pathway connections (3)
  GenericNode
  /// Specific boarding location on a platform (4)
  BoardingArea
}

/// Wheelchair boarding accessibility indicator
/// Source: GTFS reference.md - stops.txt > wheelchair_boarding
pub type WheelchairBoarding {
  /// No accessibility information (0 or empty)
  NoWheelchairInfo
  /// Some vehicles/stop is wheelchair accessible (1)
  WheelchairAccessible
  /// Wheelchair boarding not possible (2)
  NotWheelchairAccessible
}

// =============================================================================
// routes.txt Types
// Source: GTFS reference.md - Dataset Files > routes.txt
// =============================================================================

/// Represents a transit route from routes.txt
pub type Route {
  Route(
    /// Unique identifier for the route. Required.
    route_id: String,
    /// Agency operating the route. Conditionally required.
    agency_id: Option(String),
    /// Short name of the route. Conditionally required.
    route_short_name: Option(String),
    /// Full name of the route. Conditionally required.
    route_long_name: Option(String),
    /// Description of the route. Optional.
    route_desc: Option(String),
    /// Type of transportation used. Required.
    route_type: RouteType,
    /// URL of a web page about the route. Optional.
    route_url: Option(Url),
    /// Route color for display. Optional.
    route_color: Option(Color),
    /// Text color for route labels. Optional.
    route_text_color: Option(Color),
    /// Order for sorting routes. Optional.
    route_sort_order: Option(Int),
    /// Continuous pickup behavior. Optional.
    continuous_pickup: ContinuousPickup,
    /// Continuous drop-off behavior. Optional.
    continuous_drop_off: ContinuousDropOff,
    /// Network ID for fare calculations. Optional.
    network_id: Option(String),
  )
}

/// Route type enum indicating mode of transportation
/// Source: GTFS reference.md - routes.txt > route_type
pub type RouteType {
  /// Tram, Streetcar, Light rail (0)
  Tram
  /// Subway, Metro (1)
  Subway
  /// Rail, Intercity/long-distance (2)
  Rail
  /// Bus (3)
  Bus
  /// Ferry (4)
  Ferry
  /// Cable tram (5) - e.g., San Francisco cable car
  CableTram
  /// Aerial lift, gondola, aerial tramway (6)
  AerialLift
  /// Funicular (7)
  Funicular
  /// Trolleybus (11)
  Trolleybus
  /// Monorail (12)
  Monorail
  /// Extended route type (100-1799)
  /// 
  /// Supports the Google Transit Extended Route Types specification for more granular
  /// vehicle type classifications (e.g., 100-117 for railway services, 200-209 for coach,
  /// 400-405 for urban railway, 700-717 for bus services, etc.).
  /// 
  /// See: https://developers.google.com/transit/gtfs/reference/extended-route-types
  Extended(Int)
}

/// Continuous pickup behavior
/// Source: GTFS reference.md - routes.txt > continuous_pickup
pub type ContinuousPickup {
  /// Continuous stopping pickup (0)
  ContinuousStoppingPickup
  /// No continuous stopping pickup (1 or empty)
  NoContinuousStoppingPickup
  /// Must phone agency for continuous pickup (2)
  PhoneAgencyForPickup
  /// Must coordinate with driver for continuous pickup (3)
  CoordinateWithDriverForPickup
}

/// Continuous drop-off behavior
/// Source: GTFS reference.md - routes.txt > continuous_drop_off
pub type ContinuousDropOff {
  /// Continuous stopping drop-off (0)
  ContinuousStoppingDropOff
  /// No continuous stopping drop-off (1 or empty)
  NoContinuousStoppingDropOff
  /// Must phone agency for continuous drop-off (2)
  PhoneAgencyForDropOff
  /// Must coordinate with driver for continuous drop-off (3)
  CoordinateWithDriverForDropOff
}

// =============================================================================
// trips.txt Types
// Source: GTFS reference.md - Dataset Files > trips.txt
// =============================================================================

/// Represents a trip from trips.txt
pub type Trip {
  Trip(
    /// Route ID for this trip. Required.
    route_id: String,
    /// Service ID defining when trip runs. Required.
    service_id: String,
    /// Unique identifier for the trip. Required.
    trip_id: String,
    /// Text that appears on signage. Optional.
    trip_headsign: Option(String),
    /// Short name for schedules. Optional.
    trip_short_name: Option(String),
    /// Direction of travel. Optional.
    direction_id: Option(DirectionId),
    /// Block ID for linking trips. Optional.
    block_id: Option(String),
    /// Shape ID for the trip path. Optional.
    shape_id: Option(String),
    /// Wheelchair accessibility. Optional.
    wheelchair_accessible: WheelchairAccessible,
    /// Bikes allowed indicator. Optional.
    bikes_allowed: BikesAllowed,
  )
}

/// Direction of travel for a trip
/// Source: GTFS reference.md - trips.txt > direction_id
pub type DirectionId {
  /// Travel in one direction (0)
  Outbound
  /// Travel in opposite direction (1)
  Inbound
}

/// Wheelchair accessibility for a trip
/// Source: GTFS reference.md - trips.txt > wheelchair_accessible
pub type WheelchairAccessible {
  /// No accessibility information (0 or empty)
  NoAccessibilityInfo
  /// Vehicle can accommodate at least one wheelchair (1)
  AccessibleVehicle
  /// No wheelchairs can be accommodated (2)
  NotAccessibleVehicle
}

/// Bikes allowed indicator for a trip
/// Source: GTFS reference.md - trips.txt > bikes_allowed
pub type BikesAllowed {
  /// No bike information (0 or empty)
  NoBikeInfo
  /// Vehicle can accommodate at least one bicycle (1)
  BikesAllowedOnVehicle
  /// No bicycles allowed (2)
  NoBikesAllowed
}

// =============================================================================
// stop_times.txt Types
// Source: GTFS reference.md - Dataset Files > stop_times.txt
// =============================================================================

/// Represents a stop time from stop_times.txt
pub type StopTime {
  StopTime(
    /// Trip ID. Required.
    trip_id: String,
    /// Arrival time at the stop. Conditionally required.
    arrival_time: Option(Time),
    /// Departure time from the stop. Conditionally required.
    departure_time: Option(Time),
    /// Stop ID. Conditionally required.
    stop_id: Option(String),
    /// Location group ID for flex service. Conditionally forbidden.
    location_group_id: Option(String),
    /// Location ID referencing locations.geojson. Conditionally forbidden.
    location_id: Option(String),
    /// Order of stops for the trip. Required.
    stop_sequence: Int,
    /// Headsign text for this stop. Optional.
    stop_headsign: Option(String),
    /// Start of pickup/drop-off window (flex). Conditionally required.
    start_pickup_drop_off_window: Option(Time),
    /// End of pickup/drop-off window (flex). Conditionally required.
    end_pickup_drop_off_window: Option(Time),
    /// Pickup type at this stop. Conditionally forbidden.
    pickup_type: PickupType,
    /// Drop-off type at this stop. Conditionally forbidden.
    drop_off_type: DropOffType,
    /// Continuous pickup behavior. Conditionally forbidden.
    continuous_pickup: ContinuousPickup,
    /// Continuous drop-off behavior. Conditionally forbidden.
    continuous_drop_off: ContinuousDropOff,
    /// Distance traveled from first stop. Optional.
    shape_dist_traveled: Option(Float),
    /// Timepoint indicator. Optional.
    timepoint: Timepoint,
    /// Booking rule for pickup (flex). Optional.
    pickup_booking_rule_id: Option(String),
    /// Booking rule for drop-off (flex). Optional.
    drop_off_booking_rule_id: Option(String),
  )
}

/// Pickup type at a stop
/// Source: GTFS reference.md - stop_times.txt > pickup_type
pub type PickupType {
  /// Regularly scheduled pickup (0 or empty)
  RegularPickup
  /// No pickup available (1)
  NoPickup
  /// Must phone agency to arrange pickup (2)
  PhoneForPickup
  /// Must coordinate with driver for pickup (3)
  DriverCoordinatedPickup
}

/// Drop-off type at a stop
/// Source: GTFS reference.md - stop_times.txt > drop_off_type
pub type DropOffType {
  /// Regularly scheduled drop-off (0 or empty)
  RegularDropOff
  /// No drop-off available (1)
  NoDropOff
  /// Must phone agency to arrange drop-off (2)
  PhoneForDropOff
  /// Must coordinate with driver for drop-off (3)
  DriverCoordinatedDropOff
}

/// Timepoint indicator
/// Source: GTFS reference.md - stop_times.txt > timepoint
pub type Timepoint {
  /// Times are approximate (0)
  Approximate
  /// Times are exact (1 or empty)
  Exact
}

// =============================================================================
// calendar.txt Types
// Source: GTFS reference.md - Dataset Files > calendar.txt
// =============================================================================

/// Represents a service schedule from calendar.txt
pub type Calendar {
  Calendar(
    /// Unique identifier for the service. Required.
    service_id: String,
    /// Service runs on Monday. Required.
    monday: Bool,
    /// Service runs on Tuesday. Required.
    tuesday: Bool,
    /// Service runs on Wednesday. Required.
    wednesday: Bool,
    /// Service runs on Thursday. Required.
    thursday: Bool,
    /// Service runs on Friday. Required.
    friday: Bool,
    /// Service runs on Saturday. Required.
    saturday: Bool,
    /// Service runs on Sunday. Required.
    sunday: Bool,
    /// Start date of service. Required.
    start_date: Date,
    /// End date of service. Required.
    end_date: Date,
  )
}

// =============================================================================
// calendar_dates.txt Types
// Source: GTFS reference.md - Dataset Files > calendar_dates.txt
// =============================================================================

/// Represents a service exception from calendar_dates.txt
pub type CalendarDate {
  CalendarDate(
    /// Service ID. Required.
    service_id: String,
    /// Date of exception. Required.
    date: Date,
    /// Type of exception. Required.
    exception_type: ExceptionType,
  )
}

/// Exception type for calendar dates
/// Source: GTFS reference.md - calendar_dates.txt > exception_type
pub type ExceptionType {
  /// Service added for this date (1)
  ServiceAdded
  /// Service removed for this date (2)
  ServiceRemoved
}

// =============================================================================
// fare_attributes.txt Types
// Source: GTFS reference.md - Dataset Files > fare_attributes.txt
// =============================================================================

/// Represents fare information from fare_attributes.txt
pub type FareAttribute {
  FareAttribute(
    /// Unique identifier for the fare class. Required.
    fare_id: String,
    /// Fare price. Required.
    price: CurrencyAmount,
    /// Currency code for the fare. Required.
    currency_type: CurrencyCode,
    /// Payment method. Required.
    payment_method: PaymentMethod,
    /// Transfer policy. Required.
    transfers: TransferPolicy,
    /// Agency ID for the fare. Conditionally required.
    agency_id: Option(String),
    /// Transfer duration in seconds. Optional.
    transfer_duration: Option(Int),
  )
}

/// Payment method for fares
/// Source: GTFS reference.md - fare_attributes.txt > payment_method
pub type PaymentMethod {
  /// Fare paid on board (0)
  PayOnBoard
  /// Fare must be paid before boarding (1)
  PayBeforeBoarding
}

/// Transfer policy for fares
/// Source: GTFS reference.md - fare_attributes.txt > transfers
pub type TransferPolicy {
  /// No transfers permitted (0)
  NoTransfers
  /// One transfer permitted (1)
  OneTransfer
  /// Two transfers permitted (2)
  TwoTransfers
  /// Unlimited transfers (empty or omitted)
  UnlimitedTransfers
}

// =============================================================================
// fare_rules.txt Types
// Source: GTFS reference.md - Dataset Files > fare_rules.txt
// =============================================================================

/// Represents fare rules from fare_rules.txt
pub type FareRule {
  FareRule(
    /// Fare ID. Required.
    fare_id: String,
    /// Route ID. Optional.
    route_id: Option(String),
    /// Origin zone ID. Optional.
    origin_id: Option(String),
    /// Destination zone ID. Optional.
    destination_id: Option(String),
    /// Contains zone ID. Optional.
    contains_id: Option(String),
  )
}

// =============================================================================
// shapes.txt Types
// Source: GTFS reference.md - Dataset Files > shapes.txt
// =============================================================================

/// Represents a shape point from shapes.txt
pub type ShapePoint {
  ShapePoint(
    /// Shape ID. Required.
    shape_id: String,
    /// Latitude of shape point. Required.
    shape_pt_lat: Float,
    /// Longitude of shape point. Required.
    shape_pt_lon: Float,
    /// Sequence of shape point. Required.
    shape_pt_sequence: Int,
    /// Distance traveled. Optional.
    shape_dist_traveled: Option(Float),
  )
}

// =============================================================================
// frequencies.txt Types
// Source: GTFS reference.md - Dataset Files > frequencies.txt
// =============================================================================

/// Represents a frequency-based trip from frequencies.txt
pub type Frequency {
  Frequency(
    /// Trip ID. Required.
    trip_id: String,
    /// Start time. Required.
    start_time: Time,
    /// End time. Required.
    end_time: Time,
    /// Headway in seconds. Required.
    headway_secs: Int,
    /// Exact times indicator. Optional.
    exact_times: ExactTimes,
  )
}

/// Exact times indicator for frequencies
/// Source: GTFS reference.md - frequencies.txt > exact_times
pub type ExactTimes {
  /// Frequency-based trips (0 or empty)
  FrequencyBased
  /// Schedule-based trips with exact times (1)
  ScheduleBased
}

// =============================================================================
// transfers.txt Types
// Source: GTFS reference.md - Dataset Files > transfers.txt
// =============================================================================

/// Represents a transfer rule from transfers.txt
pub type Transfer {
  Transfer(
    /// Origin stop ID. Conditionally required.
    from_stop_id: Option(String),
    /// Destination stop ID. Conditionally required.
    to_stop_id: Option(String),
    /// Origin route ID. Optional.
    from_route_id: Option(String),
    /// Destination route ID. Optional.
    to_route_id: Option(String),
    /// Origin trip ID. Conditionally required.
    from_trip_id: Option(String),
    /// Destination trip ID. Conditionally required.
    to_trip_id: Option(String),
    /// Transfer type. Required.
    transfer_type: TransferType,
    /// Minimum transfer time in seconds. Optional.
    min_transfer_time: Option(Int),
  )
}

/// Transfer type
/// Source: GTFS reference.md - transfers.txt > transfer_type
pub type TransferType {
  /// Recommended transfer point (0 or empty)
  RecommendedTransfer
  /// Timed transfer (1)
  TimedTransfer
  /// Minimum time required (2)
  MinimumTimeTransfer
  /// Transfer not possible (3)
  NoTransfer
  /// In-seat transfer (4)
  InSeatTransfer
  /// Re-board same vehicle (5)
  ReBoardTransfer
}

// =============================================================================
// pathways.txt Types
// Source: GTFS reference.md - Dataset Files > pathways.txt
// =============================================================================

/// Represents a pathway from pathways.txt
pub type Pathway {
  Pathway(
    /// Unique identifier for the pathway. Required.
    pathway_id: String,
    /// Origin location. Required.
    from_stop_id: String,
    /// Destination location. Required.
    to_stop_id: String,
    /// Pathway type. Required.
    pathway_mode: PathwayMode,
    /// Bidirectional indicator. Required.
    is_bidirectional: Bool,
    /// Length in meters. Optional.
    length: Option(Float),
    /// Traversal time in seconds. Optional.
    traversal_time: Option(Int),
    /// Stair count. Optional.
    stair_count: Option(Int),
    /// Maximum slope. Optional.
    max_slope: Option(Float),
    /// Minimum width in meters. Optional.
    min_width: Option(Float),
    /// Signposted as. Optional.
    signposted_as: Option(String),
    /// Reversed signposted as. Optional.
    reversed_signposted_as: Option(String),
  )
}

/// Pathway mode
/// Source: GTFS reference.md - pathways.txt > pathway_mode
pub type PathwayMode {
  /// Walkway (1)
  Walkway
  /// Stairs (2)
  Stairs
  /// Moving sidewalk/travelator (3)
  MovingSidewalk
  /// Escalator (4)
  Escalator
  /// Elevator (5)
  Elevator
  /// Fare gate (6)
  FareGate
  /// Exit gate (7)
  ExitGate
}

// =============================================================================
// levels.txt Types
// Source: GTFS reference.md - Dataset Files > levels.txt
// =============================================================================

/// Represents a level from levels.txt
pub type Level {
  Level(
    /// Unique identifier for the level. Required.
    level_id: String,
    /// Level index (numeric, relative to street). Required.
    level_index: Float,
    /// Level name. Optional.
    level_name: Option(String),
  )
}

// =============================================================================
// feed_info.txt Types
// Source: GTFS reference.md - Dataset Files > feed_info.txt
// =============================================================================

/// Represents feed information from feed_info.txt
pub type FeedInfo {
  FeedInfo(
    /// Publisher name. Required.
    feed_publisher_name: String,
    /// Publisher URL. Required.
    feed_publisher_url: Url,
    /// Feed language. Required.
    feed_lang: LanguageCode,
    /// Default language. Optional.
    default_lang: Option(LanguageCode),
    /// Feed start date. Recommended.
    feed_start_date: Option(Date),
    /// Feed end date. Recommended.
    feed_end_date: Option(Date),
    /// Feed version. Recommended.
    feed_version: Option(String),
    /// Contact email. Optional.
    feed_contact_email: Option(Email),
    /// Contact URL. Optional.
    feed_contact_url: Option(Url),
  )
}

// =============================================================================
// translations.txt Types
// Source: GTFS reference.md - Dataset Files > translations.txt
// =============================================================================

/// Represents a translation from translations.txt
pub type Translation {
  Translation(
    /// Table name containing field to translate. Required.
    table_name: TableName,
    /// Field name to translate. Required.
    field_name: String,
    /// Language code of translation. Required.
    language: LanguageCode,
    /// Translated value. Required.
    translation: String,
    /// Record ID. Conditionally required.
    record_id: Option(String),
    /// Record sub ID. Conditionally required.
    record_sub_id: Option(String),
    /// Field value to translate. Conditionally required.
    field_value: Option(String),
  )
}

/// Table names that can be translated
/// Source: GTFS reference.md - translations.txt > table_name
pub type TableName {
  AgencyTable
  StopsTable
  RoutesTable
  TripsTable
  StopTimesTable
  PathwaysTable
  LevelsTable
  FeedInfoTable
  AttributionsTable
}

// =============================================================================
// attributions.txt Types
// Source: GTFS reference.md - Dataset Files > attributions.txt
// =============================================================================

/// Represents an attribution from attributions.txt
pub type Attribution {
  Attribution(
    /// Attribution ID. Optional.
    attribution_id: Option(String),
    /// Agency ID. Optional.
    agency_id: Option(String),
    /// Route ID. Optional.
    route_id: Option(String),
    /// Trip ID. Optional.
    trip_id: Option(String),
    /// Organization name. Required.
    organization_name: String,
    /// Is producer. Optional.
    is_producer: Bool,
    /// Is operator. Optional.
    is_operator: Bool,
    /// Is authority. Optional.
    is_authority: Bool,
    /// Attribution URL. Optional.
    attribution_url: Option(Url),
    /// Attribution email. Optional.
    attribution_email: Option(Email),
    /// Attribution phone. Optional.
    attribution_phone: Option(PhoneNumber),
  )
}

// =============================================================================
// areas.txt Types
// Source: GTFS reference.md - Dataset Files > areas.txt
// =============================================================================

/// Represents an area from areas.txt
pub type Area {
  Area(
    /// Unique identifier for the area. Required.
    area_id: String,
    /// Name of the area. Optional.
    area_name: Option(String),
  )
}

// =============================================================================
// stop_areas.txt Types
// Source: GTFS reference.md - Dataset Files > stop_areas.txt
// =============================================================================

/// Represents a stop-area assignment from stop_areas.txt
pub type StopArea {
  StopArea(
    /// Area ID. Required.
    area_id: String,
    /// Stop ID. Required.
    stop_id: String,
  )
}

// =============================================================================
// networks.txt Types
// Source: GTFS reference.md - Dataset Files > networks.txt
// =============================================================================

/// Represents a network from networks.txt
pub type Network {
  Network(
    /// Unique identifier for the network. Required.
    network_id: String,
    /// Network name. Optional.
    network_name: Option(String),
  )
}

// =============================================================================
// route_networks.txt Types
// Source: GTFS reference.md - Dataset Files > route_networks.txt
// =============================================================================

/// Represents a route-network assignment from route_networks.txt
pub type RouteNetwork {
  RouteNetwork(
    /// Network ID. Required.
    network_id: String,
    /// Route ID. Required.
    route_id: String,
  )
}

// =============================================================================
// timeframes.txt Types
// Source: GTFS reference.md - Dataset Files > timeframes.txt
// =============================================================================

/// Represents a timeframe from timeframes.txt
pub type Timeframe {
  Timeframe(
    /// Timeframe group ID. Required.
    timeframe_group_id: String,
    /// Start time. Conditionally required.
    start_time: Option(Time),
    /// End time. Conditionally required.
    end_time: Option(Time),
    /// Service ID. Required.
    service_id: String,
  )
}

// =============================================================================
// GTFS-Fares v2 Types
// =============================================================================

// rider_categories.txt
/// Represents a rider category from rider_categories.txt
pub type RiderCategory {
  RiderCategory(
    /// Unique identifier for the rider category. Required.
    rider_category_id: String,
    /// Name of the rider category. Required.
    rider_category_name: String,
    /// Minimum age for this category. Optional.
    min_age: Option(Int),
    /// Maximum age for this category. Optional.
    max_age: Option(Int),
    /// URL with eligibility requirements. Optional.
    eligibility_url: Option(String),
  )
}

// fare_media.txt
/// Represents fare media from fare_media.txt
pub type FareMedia {
  FareMedia(
    /// Unique identifier. Required.
    fare_media_id: String,
    /// Name of fare media. Optional.
    fare_media_name: Option(String),
    /// Type of fare media. Required.
    fare_media_type: FareMediaType,
  )
}

/// Fare media type
/// Source: GTFS reference.md - fare_media.txt > fare_media_type
pub type FareMediaType {
  /// None (0) - no fare media
  NoFareMedia
  /// Physical paper ticket (1)
  PaperTicket
  /// Transit card (2)
  TransitCard
  /// cEMV contactless (3)
  Cemv
  /// Mobile app (4)
  MobileApp
}

// fare_products.txt
/// Represents a fare product from fare_products.txt
pub type FareProduct {
  FareProduct(
    /// Unique identifier. Required.
    fare_product_id: String,
    /// Name of fare product. Optional.
    fare_product_name: Option(String),
    /// Fare media ID. Optional.
    fare_media_id: Option(String),
    /// Amount. Required.
    amount: CurrencyAmount,
    /// Currency. Required.
    currency: CurrencyCode,
  )
}

// fare_leg_rules.txt
/// Represents a fare leg rule from fare_leg_rules.txt
pub type FareLegRule {
  FareLegRule(
    /// Leg group ID. Optional.
    leg_group_id: Option(String),
    /// Network ID. Optional.
    network_id: Option(String),
    /// From area ID. Optional.
    from_area_id: Option(String),
    /// To area ID. Optional.
    to_area_id: Option(String),
    /// From timeframe group ID. Optional.
    from_timeframe_group_id: Option(String),
    /// To timeframe group ID. Optional.
    to_timeframe_group_id: Option(String),
    /// Fare product ID. Required.
    fare_product_id: String,
    /// Rule priority. Optional.
    rule_priority: Option(Int),
  )
}

// fare_transfer_rules.txt
/// Represents a fare transfer rule from fare_transfer_rules.txt
pub type FareTransferRule {
  FareTransferRule(
    /// From leg group ID. Optional.
    from_leg_group_id: Option(String),
    /// To leg group ID. Optional.
    to_leg_group_id: Option(String),
    /// Transfer count. Optional.
    transfer_count: Option(Int),
    /// Duration limit. Optional.
    duration_limit: Option(Int),
    /// Duration limit type. Optional.
    duration_limit_type: Option(DurationLimitType),
    /// Fare transfer type. Required.
    fare_transfer_type: FareTransferType,
    /// Fare product ID. Optional.
    fare_product_id: Option(String),
  )
}

/// Duration limit type
/// Source: GTFS reference.md - fare_transfer_rules.txt > duration_limit_type
pub type DurationLimitType {
  /// Between end of previous leg and start of next (0)
  BetweenLegs
  /// Between start of previous leg and start of next (1)
  BetweenStartTimes
  /// Between start of previous leg and end of next (2)
  BetweenStartAndEnd
}

/// Fare transfer type
/// Source: GTFS reference.md - fare_transfer_rules.txt > fare_transfer_type
pub type FareTransferType {
  /// Transfer cost is sum of leg prices plus transfer price (0)
  SumPlusTransfer
  /// Transfer cost is sum of leg prices plus transfer price, capped (1)
  SumPlusTransferCapped
  /// Transfer cost is sum of leg prices (2)
  SumOfLegs
}

// =============================================================================
// fare_leg_join_rules.txt Types
// Source: GTFS reference.md - Dataset Files > fare_leg_join_rules.txt
// =============================================================================

/// Represents a fare leg join rule from fare_leg_join_rules.txt
/// Defines when two or more legs should be considered as a single
/// effective fare leg for matching against fare_leg_rules.txt
pub type FareLegJoinRule {
  FareLegJoinRule(
    /// Network ID for pre-transfer leg. Required.
    from_network_id: String,
    /// Network ID for post-transfer leg. Required.
    to_network_id: String,
    /// Stop ID where pre-transfer leg ends. Conditionally required.
    from_stop_id: Option(String),
    /// Stop ID where post-transfer leg starts. Conditionally required.
    to_stop_id: Option(String),
  )
}

// =============================================================================
// GTFS-Flex Types
// =============================================================================

// location_groups.txt
/// Represents a location group from location_groups.txt
pub type LocationGroup {
  LocationGroup(
    /// Unique identifier. Required.
    location_group_id: String,
    /// Name. Optional.
    location_group_name: Option(String),
  )
}

// location_group_stops.txt
/// Represents a location group stop from location_group_stops.txt
pub type LocationGroupStop {
  LocationGroupStop(
    /// Location group ID. Required.
    location_group_id: String,
    /// Stop ID. Required.
    stop_id: String,
  )
}

// booking_rules.txt
/// Represents a booking rule from booking_rules.txt
pub type BookingRule {
  BookingRule(
    /// Unique identifier. Required.
    booking_rule_id: String,
    /// Booking type. Required.
    booking_type: BookingType,
    /// Minimum prior notice in minutes. Conditionally required.
    prior_notice_duration_min: Option(Int),
    /// Maximum prior notice in minutes. Conditionally forbidden.
    prior_notice_duration_max: Option(Int),
    /// Prior notice last day. Conditionally required.
    prior_notice_last_day: Option(Int),
    /// Prior notice last time. Conditionally required.
    prior_notice_last_time: Option(Time),
    /// Prior notice start day. Conditionally forbidden.
    prior_notice_start_day: Option(Int),
    /// Prior notice start time. Conditionally forbidden.
    prior_notice_start_time: Option(Time),
    /// Prior notice service ID. Conditionally forbidden.
    prior_notice_service_id: Option(String),
    /// Message. Optional.
    message: Option(String),
    /// Pickup message. Optional.
    pickup_message: Option(String),
    /// Drop-off message. Optional.
    drop_off_message: Option(String),
    /// Phone number. Optional.
    phone_number: Option(PhoneNumber),
    /// Info URL. Optional.
    info_url: Option(Url),
    /// Booking URL. Optional.
    booking_url: Option(Url),
  )
}

/// Booking type
/// Source: GTFS reference.md - booking_rules.txt > booking_type
pub type BookingType {
  /// Real-time booking (0)
  RealTimeBooking
  /// Same-day booking (1)
  SameDayBooking
  /// Prior day(s) booking (2)
  PriorDayBooking
}

// =============================================================================
// locations.geojson Types
// Source: GTFS reference.md - Dataset Files > locations.geojson
// =============================================================================

/// Represents the locations.geojson file content
pub type LocationsGeoJson {
  LocationsGeoJson(features: List(GeoJsonFeature))
}

/// A GeoJSON feature representing a flex zone
pub type GeoJsonFeature {
  GeoJsonFeature(
    /// Unique identifier. Required.
    id: String,
    /// Properties. Required.
    properties: GeoJsonProperties,
    /// Geometry. Required.
    geometry: GeoJsonGeometry,
  )
}

/// GeoJSON feature properties
pub type GeoJsonProperties {
  GeoJsonProperties(
    /// Stop name. Optional.
    stop_name: Option(String),
    /// Stop description. Optional.
    stop_desc: Option(String),
  )
}

/// GeoJSON geometry types
pub type GeoJsonGeometry {
  /// A single polygon with exterior ring and optional holes
  Polygon(rings: List(List(Coordinate)))
  /// Multiple polygons
  MultiPolygon(polygons: List(List(List(Coordinate))))
}
