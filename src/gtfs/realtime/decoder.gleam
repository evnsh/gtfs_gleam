//// GTFS Realtime Decoder
////
//// Decodes GTFS Realtime Protocol Buffer messages using protobin.
//// Implements decoders for all message types defined in gtfs-realtime.proto.

import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import gtfs/realtime/types.{
  type Alert, type AlertCause, type AlertEffect, type CarriageDetails,
  type CongestionLevel, type DropOffPickupType, type EntitySelector,
  type FeedEntity, type FeedHeader, type FeedMessage, type LocalizedImage,
  type Modification, type ModifiedTripSelector, type OccupancyStatus,
  type Position, type RealtimeStop, type RealtimeWheelchairBoarding,
  type ReplacementStop, type SelectedTrips, type SeverityLevel, type Shape,
  type StopSelector, type StopTimeEvent, type StopTimeProperties,
  type StopTimeScheduleRelationship, type StopTimeUpdate, type TimeRange,
  type TranslatedImage, type TranslatedString, type Translation,
  type TripDescriptor, type TripModifications, type TripProperties,
  type TripScheduleRelationship, type TripUpdate, type VehicleDescriptor,
  type VehiclePosition, type VehicleStopStatus, type WheelchairAccessible,
}
import protobin

fn decode_single_or_list_bit_array() -> decode.Decoder(BitArray) {
  decode.one_of(decode.bit_array, or: [
    {
      use values <- decode.then(decode.list(of: decode.bit_array))
      case list.last(values) {
        Ok(value) -> decode.success(value)
        Error(Nil) -> decode.failure(<<>>, "BitArray")
      }
    },
  ])
}

fn decode_float32() -> decode.Decoder(Float) {
  use bits <- decode.then(decode_single_or_list_bit_array())

  case bits {
    <<num:float-little-size(32)>> -> decode.success(num)
    _ -> decode.failure(0.0, "Float32")
  }
}

fn decode_float64() -> decode.Decoder(Float) {
  use bits <- decode.then(decode_single_or_list_bit_array())

  case bits {
    <<num:float-little-size(64)>> -> decode.success(num)
    _ -> decode.failure(0.0, "Float64")
  }
}

// =============================================================================
// Feed Message Decoder
// =============================================================================

/// Decode a GTFS Realtime feed message from protobuf binary data
pub fn decode_feed_message(
  data: BitArray,
) -> Result(types.FeedMessage, protobin.ParseError) {
  protobin.parse(from: data, using: feed_message_decoder())
  |> result_map(fn(parsed) { parsed.value })
}

/// Alias for decode_feed_message for convenience
pub fn decode(data: BitArray) -> Result(types.FeedMessage, protobin.ParseError) {
  decode_feed_message(data)
}

fn feed_message_decoder() -> decode.Decoder(FeedMessage) {
  use header <- decode.field(
    1,
    protobin.decode_protobuf(
      using: feed_header_decoder,
      named: "header",
      default: default_feed_header(),
    ),
  )
  use entity <- decode.optional_field(2, [], decode.list(entity_decoder()))
  decode.success(types.FeedMessage(header: header, entity: entity))
}

fn default_feed_header() -> FeedHeader {
  types.FeedHeader(
    gtfs_realtime_version: "2.0",
    incrementality: types.FullDataset,
    timestamp: None,
    feed_version: None,
  )
}

fn entity_decoder() -> decode.Decoder(FeedEntity) {
  protobin.decode_protobuf(
    using: feed_entity_decoder,
    named: "entity",
    default: default_feed_entity(),
  )
}

// =============================================================================
// Feed Header Decoder
// =============================================================================

fn feed_header_decoder() -> decode.Decoder(FeedHeader) {
  use version <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use incrementality_val <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use timestamp <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use feed_version <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_string()),
  )

  let incrementality = case incrementality_val {
    Some(1) -> types.Differential
    _ -> types.FullDataset
  }

  decode.success(types.FeedHeader(
    gtfs_realtime_version: option_unwrap(version, "2.0"),
    incrementality: incrementality,
    timestamp: timestamp,
    feed_version: feed_version,
  ))
}

// =============================================================================
// Feed Entity Decoder
// =============================================================================

fn default_feed_entity() -> FeedEntity {
  types.FeedEntity(
    id: "",
    is_deleted: False,
    trip_update: None,
    vehicle: None,
    alert: None,
    shape: None,
    stop: None,
    trip_modifications: None,
  )
}

fn feed_entity_decoder() -> decode.Decoder(FeedEntity) {
  use id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use is_deleted <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_bool()),
  )
  use trip_update <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_protobuf(
      using: trip_update_decoder,
      named: "trip_update",
      default: default_trip_update(),
    )),
  )
  use vehicle <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_protobuf(
      using: vehicle_position_decoder,
      named: "vehicle",
      default: default_vehicle_position(),
    )),
  )
  use alert <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_protobuf(
      using: alert_decoder,
      named: "alert",
      default: default_alert(),
    )),
  )
  use shape <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_protobuf(
      using: shape_decoder,
      named: "shape",
      default: default_shape(),
    )),
  )
  use stop <- decode.optional_field(
    7,
    None,
    decode.optional(protobin.decode_protobuf(
      using: realtime_stop_decoder,
      named: "stop",
      default: default_realtime_stop(),
    )),
  )
  use trip_modifications <- decode.optional_field(
    8,
    None,
    decode.optional(protobin.decode_protobuf(
      using: trip_modifications_decoder,
      named: "trip_modifications",
      default: default_trip_modifications(),
    )),
  )

  decode.success(types.FeedEntity(
    id: option_unwrap(id, ""),
    is_deleted: option_unwrap(is_deleted, False),
    trip_update: trip_update,
    vehicle: vehicle,
    alert: alert,
    shape: shape,
    stop: stop,
    trip_modifications: trip_modifications,
  ))
}

// =============================================================================
// Trip Update Decoder
// =============================================================================

fn default_trip_update() -> TripUpdate {
  types.TripUpdate(
    trip: default_trip_descriptor(),
    vehicle: None,
    stop_time_update: [],
    timestamp: None,
    delay: None,
    trip_properties: None,
  )
}

fn trip_update_decoder() -> decode.Decoder(TripUpdate) {
  use trip <- decode.field(
    1,
    protobin.decode_protobuf(
      using: trip_descriptor_decoder,
      named: "trip",
      default: default_trip_descriptor(),
    ),
  )
  use vehicle <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_protobuf(
      using: vehicle_descriptor_decoder,
      named: "vehicle",
      default: default_vehicle_descriptor(),
    )),
  )
  use stop_time_update <- decode.optional_field(
    2,
    [],
    decode.list(stop_time_update_item_decoder()),
  )
  use timestamp <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use delay <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use trip_properties <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_protobuf(
      using: trip_properties_decoder,
      named: "trip_properties",
      default: default_trip_properties(),
    )),
  )

  decode.success(types.TripUpdate(
    trip: trip,
    vehicle: vehicle,
    stop_time_update: stop_time_update,
    timestamp: timestamp,
    delay: delay,
    trip_properties: trip_properties,
  ))
}

fn stop_time_update_item_decoder() -> decode.Decoder(StopTimeUpdate) {
  protobin.decode_protobuf(
    using: stop_time_update_decoder,
    named: "stop_time_update",
    default: default_stop_time_update(),
  )
}

fn default_stop_time_update() -> StopTimeUpdate {
  types.StopTimeUpdate(
    stop_sequence: None,
    stop_id: None,
    arrival: None,
    departure: None,
    departure_occupancy_status: None,
    schedule_relationship: types.StopScheduled,
    stop_time_properties: None,
  )
}

fn stop_time_update_decoder() -> decode.Decoder(StopTimeUpdate) {
  use stop_sequence <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use stop_id <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_string()),
  )
  use arrival <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_protobuf(
      using: stop_time_event_decoder,
      named: "arrival",
      default: default_stop_time_event(),
    )),
  )
  use departure <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_protobuf(
      using: stop_time_event_decoder,
      named: "departure",
      default: default_stop_time_event(),
    )),
  )
  use departure_occupancy_val <- decode.optional_field(
    7,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use schedule_rel_val <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use stop_time_properties <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_protobuf(
      using: stop_time_properties_decoder,
      named: "stop_time_properties",
      default: default_stop_time_properties(),
    )),
  )

  decode.success(types.StopTimeUpdate(
    stop_sequence: stop_sequence,
    stop_id: stop_id,
    arrival: arrival,
    departure: departure,
    departure_occupancy_status: option_map(
      departure_occupancy_val,
      decode_occupancy_status,
    ),
    schedule_relationship: decode_stop_schedule_relationship(option_unwrap(
      schedule_rel_val,
      0,
    )),
    stop_time_properties: stop_time_properties,
  ))
}

fn default_stop_time_event() -> StopTimeEvent {
  types.StopTimeEvent(
    delay: None,
    time: None,
    uncertainty: None,
    scheduled_time: None,
  )
}

fn stop_time_event_decoder() -> decode.Decoder(StopTimeEvent) {
  use delay <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use time <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use uncertainty <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use scheduled_time <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )

  decode.success(types.StopTimeEvent(
    delay: delay,
    time: time,
    uncertainty: uncertainty,
    scheduled_time: scheduled_time,
  ))
}

fn default_stop_time_properties() -> StopTimeProperties {
  types.StopTimeProperties(
    assigned_stop_id: None,
    stop_headsign: None,
    pickup_type: None,
    drop_off_type: None,
  )
}

fn stop_time_properties_decoder() -> decode.Decoder(StopTimeProperties) {
  use assigned_stop_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use stop_headsign <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use pickup_type_val <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use drop_off_type_val <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )

  decode.success(types.StopTimeProperties(
    assigned_stop_id: assigned_stop_id,
    stop_headsign: stop_headsign,
    pickup_type: option_map(pickup_type_val, decode_drop_off_pickup_type),
    drop_off_type: option_map(drop_off_type_val, decode_drop_off_pickup_type),
  ))
}

fn default_trip_properties() -> TripProperties {
  types.TripProperties(
    trip_id: None,
    start_date: None,
    start_time: None,
    shape_id: None,
    trip_headsign: None,
    trip_short_name: None,
  )
}

fn trip_properties_decoder() -> decode.Decoder(TripProperties) {
  use trip_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use start_date <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use start_time <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_string()),
  )
  use shape_id <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_string()),
  )
  use trip_headsign <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_string()),
  )
  use trip_short_name <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_string()),
  )

  decode.success(types.TripProperties(
    trip_id: trip_id,
    start_date: start_date,
    start_time: start_time,
    shape_id: shape_id,
    trip_headsign: trip_headsign,
    trip_short_name: trip_short_name,
  ))
}

// =============================================================================
// Vehicle Position Decoder
// =============================================================================

fn default_vehicle_position() -> VehiclePosition {
  types.VehiclePosition(
    trip: None,
    vehicle: None,
    position: None,
    current_stop_sequence: None,
    stop_id: None,
    current_status: types.InTransitTo,
    timestamp: None,
    congestion_level: types.UnknownCongestionLevel,
    occupancy_status: None,
    occupancy_percentage: None,
    multi_carriage_details: [],
  )
}

fn vehicle_position_decoder() -> decode.Decoder(VehiclePosition) {
  use trip <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_protobuf(
      using: trip_descriptor_decoder,
      named: "trip",
      default: default_trip_descriptor(),
    )),
  )
  use vehicle <- decode.optional_field(
    8,
    None,
    decode.optional(protobin.decode_protobuf(
      using: vehicle_descriptor_decoder,
      named: "vehicle",
      default: default_vehicle_descriptor(),
    )),
  )
  use position <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_protobuf(
      using: position_decoder,
      named: "position",
      default: default_position(),
    )),
  )
  use current_stop_sequence <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use stop_id <- decode.optional_field(
    7,
    None,
    decode.optional(protobin.decode_string()),
  )
  use current_status_val <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use timestamp <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use congestion_level_val <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use occupancy_status_val <- decode.optional_field(
    9,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use occupancy_percentage <- decode.optional_field(
    10,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use multi_carriage_details <- decode.optional_field(
    11,
    [],
    decode.list(carriage_details_item_decoder()),
  )

  decode.success(types.VehiclePosition(
    trip: trip,
    vehicle: vehicle,
    position: position,
    current_stop_sequence: current_stop_sequence,
    stop_id: stop_id,
    current_status: decode_vehicle_stop_status(option_unwrap(
      current_status_val,
      2,
    )),
    timestamp: timestamp,
    congestion_level: decode_congestion_level(option_unwrap(
      congestion_level_val,
      0,
    )),
    occupancy_status: option_map(occupancy_status_val, decode_occupancy_status),
    occupancy_percentage: occupancy_percentage,
    multi_carriage_details: multi_carriage_details,
  ))
}

fn default_position() -> Position {
  types.Position(
    latitude: 0.0,
    longitude: 0.0,
    bearing: None,
    odometer: None,
    speed: None,
  )
}

fn position_decoder() -> decode.Decoder(Position) {
  use latitude <- decode.optional_field(
    1,
    None,
    decode.optional(decode_float32()),
  )
  use longitude <- decode.optional_field(
    2,
    None,
    decode.optional(decode_float32()),
  )
  use bearing <- decode.optional_field(
    3,
    None,
    decode.optional(decode_float32()),
  )
  use odometer <- decode.optional_field(
    4,
    None,
    decode.optional(decode_float64()),
  )
  use speed <- decode.optional_field(5, None, decode.optional(decode_float32()))

  decode.success(types.Position(
    latitude: option_unwrap(latitude, 0.0),
    longitude: option_unwrap(longitude, 0.0),
    bearing: bearing,
    odometer: odometer,
    speed: speed,
  ))
}

fn carriage_details_item_decoder() -> decode.Decoder(CarriageDetails) {
  protobin.decode_protobuf(
    using: carriage_details_decoder,
    named: "carriage_details",
    default: default_carriage_details(),
  )
}

fn default_carriage_details() -> CarriageDetails {
  types.CarriageDetails(
    id: None,
    label: None,
    occupancy_status: types.NoDataAvailable,
    occupancy_percentage: -1,
    carriage_sequence: None,
  )
}

fn carriage_details_decoder() -> decode.Decoder(CarriageDetails) {
  use id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use label <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use occupancy_status_val <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use occupancy_percentage <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use carriage_sequence <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_uint()),
  )

  decode.success(types.CarriageDetails(
    id: id,
    label: label,
    occupancy_status: decode_occupancy_status(option_unwrap(
      occupancy_status_val,
      7,
    )),
    occupancy_percentage: option_unwrap(occupancy_percentage, -1),
    carriage_sequence: carriage_sequence,
  ))
}

// =============================================================================
// Alert Decoder
// =============================================================================

fn default_alert() -> Alert {
  types.Alert(
    active_period: [],
    informed_entity: [],
    cause: types.UnknownCause,
    effect: types.UnknownEffect,
    url: None,
    header_text: None,
    description_text: None,
    tts_header_text: None,
    tts_description_text: None,
    severity_level: types.UnknownSeverity,
    image: None,
    image_alternative_text: None,
    cause_detail: None,
    effect_detail: None,
  )
}

fn alert_decoder() -> decode.Decoder(Alert) {
  use active_period <- decode.optional_field(
    1,
    [],
    decode.list(time_range_item_decoder()),
  )
  use informed_entity <- decode.optional_field(
    5,
    [],
    decode.list(entity_selector_item_decoder()),
  )
  use cause_val <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use effect_val <- decode.optional_field(
    7,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use url <- decode.optional_field(
    8,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "url",
      default: default_translated_string(),
    )),
  )
  use header_text <- decode.optional_field(
    10,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "header_text",
      default: default_translated_string(),
    )),
  )
  use description_text <- decode.optional_field(
    11,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "description_text",
      default: default_translated_string(),
    )),
  )
  use tts_header_text <- decode.optional_field(
    12,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "tts_header_text",
      default: default_translated_string(),
    )),
  )
  use tts_description_text <- decode.optional_field(
    13,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "tts_description_text",
      default: default_translated_string(),
    )),
  )
  use severity_level_val <- decode.optional_field(
    14,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use image <- decode.optional_field(
    15,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_image_decoder,
      named: "image",
      default: default_translated_image(),
    )),
  )
  use image_alternative_text <- decode.optional_field(
    16,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "image_alternative_text",
      default: default_translated_string(),
    )),
  )
  use cause_detail <- decode.optional_field(
    17,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "cause_detail",
      default: default_translated_string(),
    )),
  )
  use effect_detail <- decode.optional_field(
    18,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "effect_detail",
      default: default_translated_string(),
    )),
  )

  decode.success(types.Alert(
    active_period: active_period,
    informed_entity: informed_entity,
    cause: decode_alert_cause(option_unwrap(cause_val, 1)),
    effect: decode_alert_effect(option_unwrap(effect_val, 8)),
    url: url,
    header_text: header_text,
    description_text: description_text,
    tts_header_text: tts_header_text,
    tts_description_text: tts_description_text,
    severity_level: decode_severity_level(option_unwrap(severity_level_val, 1)),
    image: image,
    image_alternative_text: image_alternative_text,
    cause_detail: cause_detail,
    effect_detail: effect_detail,
  ))
}

fn time_range_item_decoder() -> decode.Decoder(TimeRange) {
  protobin.decode_protobuf(
    using: time_range_decoder,
    named: "time_range",
    default: default_time_range(),
  )
}

fn default_time_range() -> TimeRange {
  types.TimeRange(start: None, end: None)
}

fn time_range_decoder() -> decode.Decoder(TimeRange) {
  use start <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use end <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_uint()),
  )
  decode.success(types.TimeRange(start: start, end: end))
}

fn entity_selector_item_decoder() -> decode.Decoder(EntitySelector) {
  protobin.decode_protobuf(
    using: entity_selector_decoder,
    named: "entity_selector",
    default: default_entity_selector(),
  )
}

fn default_entity_selector() -> EntitySelector {
  types.EntitySelector(
    agency_id: None,
    route_id: None,
    route_type: None,
    trip: None,
    stop_id: None,
    direction_id: None,
  )
}

fn entity_selector_decoder() -> decode.Decoder(EntitySelector) {
  use agency_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use route_id <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use route_type <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use trip <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_protobuf(
      using: trip_descriptor_decoder,
      named: "trip",
      default: default_trip_descriptor(),
    )),
  )
  use stop_id <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_string()),
  )
  use direction_id <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_uint()),
  )

  decode.success(types.EntitySelector(
    agency_id: agency_id,
    route_id: route_id,
    route_type: route_type,
    trip: trip,
    stop_id: stop_id,
    direction_id: direction_id,
  ))
}

fn default_translated_string() -> TranslatedString {
  types.TranslatedString(translation: [])
}

fn translated_string_decoder() -> decode.Decoder(TranslatedString) {
  use translation <- decode.optional_field(
    1,
    [],
    decode.list(translation_item_decoder()),
  )
  decode.success(types.TranslatedString(translation: translation))
}

fn translation_item_decoder() -> decode.Decoder(Translation) {
  protobin.decode_protobuf(
    using: translation_decoder,
    named: "translation",
    default: default_translation(),
  )
}

fn default_translation() -> Translation {
  types.Translation(text: "", language: None)
}

fn translation_decoder() -> decode.Decoder(Translation) {
  use text <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use language <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  decode.success(types.Translation(
    text: option_unwrap(text, ""),
    language: language,
  ))
}

fn default_translated_image() -> TranslatedImage {
  types.TranslatedImage(localized_image: [])
}

fn translated_image_decoder() -> decode.Decoder(TranslatedImage) {
  use localized_image <- decode.optional_field(
    1,
    [],
    decode.list(localized_image_item_decoder()),
  )
  decode.success(types.TranslatedImage(localized_image: localized_image))
}

fn localized_image_item_decoder() -> decode.Decoder(LocalizedImage) {
  protobin.decode_protobuf(
    using: localized_image_decoder,
    named: "localized_image",
    default: default_localized_image(),
  )
}

fn default_localized_image() -> LocalizedImage {
  types.LocalizedImage(url: "", media_type: "", language: None)
}

fn localized_image_decoder() -> decode.Decoder(LocalizedImage) {
  use url <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use media_type <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use language <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_string()),
  )
  decode.success(types.LocalizedImage(
    url: option_unwrap(url, ""),
    media_type: option_unwrap(media_type, ""),
    language: language,
  ))
}

// =============================================================================
// Common Decoders
// =============================================================================

fn default_trip_descriptor() -> TripDescriptor {
  types.TripDescriptor(
    trip_id: None,
    route_id: None,
    direction_id: None,
    start_time: None,
    start_date: None,
    schedule_relationship: types.TripScheduled,
    modified_trip: None,
  )
}

fn trip_descriptor_decoder() -> decode.Decoder(TripDescriptor) {
  use trip_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use route_id <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_string()),
  )
  use direction_id <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use start_time <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use start_date <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_string()),
  )
  use schedule_rel_val <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use modified_trip <- decode.optional_field(
    7,
    None,
    decode.optional(protobin.decode_protobuf(
      using: modified_trip_selector_decoder,
      named: "modified_trip",
      default: default_modified_trip_selector(),
    )),
  )

  decode.success(types.TripDescriptor(
    trip_id: trip_id,
    route_id: route_id,
    direction_id: direction_id,
    start_time: start_time,
    start_date: start_date,
    schedule_relationship: decode_trip_schedule_relationship(option_unwrap(
      schedule_rel_val,
      0,
    )),
    modified_trip: modified_trip,
  ))
}

fn default_modified_trip_selector() -> ModifiedTripSelector {
  types.ModifiedTripSelector(
    modifications_id: None,
    affected_trip_id: None,
    start_time: None,
    start_date: None,
  )
}

fn modified_trip_selector_decoder() -> decode.Decoder(ModifiedTripSelector) {
  use modifications_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use affected_trip_id <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use start_time <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_string()),
  )
  use start_date <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_string()),
  )

  decode.success(types.ModifiedTripSelector(
    modifications_id: modifications_id,
    affected_trip_id: affected_trip_id,
    start_time: start_time,
    start_date: start_date,
  ))
}

fn default_vehicle_descriptor() -> VehicleDescriptor {
  types.VehicleDescriptor(
    id: None,
    label: None,
    license_plate: None,
    wheelchair_accessible: types.WheelchairNoValue,
  )
}

fn vehicle_descriptor_decoder() -> decode.Decoder(VehicleDescriptor) {
  use id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use label <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  use license_plate <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_string()),
  )
  use wheelchair_val <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_uint()),
  )

  decode.success(types.VehicleDescriptor(
    id: id,
    label: label,
    license_plate: license_plate,
    wheelchair_accessible: decode_wheelchair_accessible(option_unwrap(
      wheelchair_val,
      0,
    )),
  ))
}

// =============================================================================
// Shape Decoder
// =============================================================================

fn default_shape() -> Shape {
  types.Shape(shape_id: None, encoded_polyline: None)
}

fn shape_decoder() -> decode.Decoder(Shape) {
  use shape_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use encoded_polyline <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  decode.success(types.Shape(
    shape_id: shape_id,
    encoded_polyline: encoded_polyline,
  ))
}

// =============================================================================
// Realtime Stop Decoder
// =============================================================================

fn default_realtime_stop() -> RealtimeStop {
  types.RealtimeStop(
    stop_id: None,
    stop_code: None,
    stop_name: None,
    tts_stop_name: None,
    stop_desc: None,
    stop_lat: None,
    stop_lon: None,
    zone_id: None,
    stop_url: None,
    parent_station: None,
    stop_timezone: None,
    wheelchair_boarding: types.RealtimeWheelchairUnknown,
    level_id: None,
    platform_code: None,
  )
}

fn realtime_stop_decoder() -> decode.Decoder(RealtimeStop) {
  use stop_id <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_string()),
  )
  use stop_code <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "stop_code",
      default: default_translated_string(),
    )),
  )
  use stop_name <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "stop_name",
      default: default_translated_string(),
    )),
  )
  use tts_stop_name <- decode.optional_field(
    4,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "tts_stop_name",
      default: default_translated_string(),
    )),
  )
  use stop_desc <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "stop_desc",
      default: default_translated_string(),
    )),
  )
  use stop_lat <- decode.optional_field(
    6,
    None,
    decode.optional(decode_float32()),
  )
  use stop_lon <- decode.optional_field(
    7,
    None,
    decode.optional(decode_float32()),
  )
  use zone_id <- decode.optional_field(
    8,
    None,
    decode.optional(protobin.decode_string()),
  )
  use stop_url <- decode.optional_field(
    9,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "stop_url",
      default: default_translated_string(),
    )),
  )
  use parent_station <- decode.optional_field(
    11,
    None,
    decode.optional(protobin.decode_string()),
  )
  use stop_timezone <- decode.optional_field(
    12,
    None,
    decode.optional(protobin.decode_string()),
  )
  use wheelchair_val <- decode.optional_field(
    13,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use level_id <- decode.optional_field(
    14,
    None,
    decode.optional(protobin.decode_string()),
  )
  use platform_code <- decode.optional_field(
    15,
    None,
    decode.optional(protobin.decode_protobuf(
      using: translated_string_decoder,
      named: "platform_code",
      default: default_translated_string(),
    )),
  )

  decode.success(types.RealtimeStop(
    stop_id: stop_id,
    stop_code: stop_code,
    stop_name: stop_name,
    tts_stop_name: tts_stop_name,
    stop_desc: stop_desc,
    stop_lat: stop_lat,
    stop_lon: stop_lon,
    zone_id: zone_id,
    stop_url: stop_url,
    parent_station: parent_station,
    stop_timezone: stop_timezone,
    wheelchair_boarding: decode_realtime_wheelchair_boarding(option_unwrap(
      wheelchair_val,
      0,
    )),
    level_id: level_id,
    platform_code: platform_code,
  ))
}

// =============================================================================
// Trip Modifications Decoder
// =============================================================================

fn default_trip_modifications() -> TripModifications {
  types.TripModifications(
    selected_trips: [],
    start_times: [],
    service_dates: [],
    modifications: [],
  )
}

fn trip_modifications_decoder() -> decode.Decoder(TripModifications) {
  use selected_trips <- decode.optional_field(
    1,
    [],
    decode.list(selected_trips_item_decoder()),
  )
  use start_times <- decode.optional_field(
    2,
    [],
    decode.list(protobin.decode_string()),
  )
  use service_dates <- decode.optional_field(
    3,
    [],
    decode.list(protobin.decode_string()),
  )
  use modifications <- decode.optional_field(
    4,
    [],
    decode.list(modification_item_decoder()),
  )

  decode.success(types.TripModifications(
    selected_trips: selected_trips,
    start_times: start_times,
    service_dates: service_dates,
    modifications: modifications,
  ))
}

fn selected_trips_item_decoder() -> decode.Decoder(SelectedTrips) {
  protobin.decode_protobuf(
    using: selected_trips_decoder,
    named: "selected_trips",
    default: default_selected_trips(),
  )
}

fn default_selected_trips() -> SelectedTrips {
  types.SelectedTrips(trip_ids: [], shape_id: None)
}

fn selected_trips_decoder() -> decode.Decoder(SelectedTrips) {
  use trip_ids <- decode.optional_field(
    1,
    [],
    decode.list(protobin.decode_string()),
  )
  use shape_id <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  decode.success(types.SelectedTrips(trip_ids: trip_ids, shape_id: shape_id))
}

fn modification_item_decoder() -> decode.Decoder(Modification) {
  protobin.decode_protobuf(
    using: modification_decoder,
    named: "modification",
    default: default_modification(),
  )
}

fn default_modification() -> Modification {
  types.Modification(
    start_stop_selector: None,
    end_stop_selector: None,
    propagated_modification_delay: 0,
    replacement_stops: [],
    service_alert_id: None,
    last_modified_time: None,
  )
}

fn modification_decoder() -> decode.Decoder(Modification) {
  use start_stop_selector <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_protobuf(
      using: stop_selector_decoder,
      named: "start_stop_selector",
      default: default_stop_selector(),
    )),
  )
  use end_stop_selector <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_protobuf(
      using: stop_selector_decoder,
      named: "end_stop_selector",
      default: default_stop_selector(),
    )),
  )
  use propagated_delay <- decode.optional_field(
    3,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use replacement_stops <- decode.optional_field(
    4,
    [],
    decode.list(replacement_stop_item_decoder()),
  )
  use service_alert_id <- decode.optional_field(
    5,
    None,
    decode.optional(protobin.decode_string()),
  )
  use last_modified_time <- decode.optional_field(
    6,
    None,
    decode.optional(protobin.decode_uint()),
  )

  decode.success(types.Modification(
    start_stop_selector: start_stop_selector,
    end_stop_selector: end_stop_selector,
    propagated_modification_delay: option_unwrap(propagated_delay, 0),
    replacement_stops: replacement_stops,
    service_alert_id: service_alert_id,
    last_modified_time: last_modified_time,
  ))
}

fn default_stop_selector() -> StopSelector {
  types.StopSelector(stop_sequence: None, stop_id: None)
}

fn stop_selector_decoder() -> decode.Decoder(StopSelector) {
  use stop_sequence <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use stop_id <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  decode.success(types.StopSelector(
    stop_sequence: stop_sequence,
    stop_id: stop_id,
  ))
}

fn replacement_stop_item_decoder() -> decode.Decoder(ReplacementStop) {
  protobin.decode_protobuf(
    using: replacement_stop_decoder,
    named: "replacement_stop",
    default: default_replacement_stop(),
  )
}

fn default_replacement_stop() -> ReplacementStop {
  types.ReplacementStop(travel_time_to_stop: None, stop_id: None)
}

fn replacement_stop_decoder() -> decode.Decoder(ReplacementStop) {
  use travel_time_to_stop <- decode.optional_field(
    1,
    None,
    decode.optional(protobin.decode_uint()),
  )
  use stop_id <- decode.optional_field(
    2,
    None,
    decode.optional(protobin.decode_string()),
  )
  decode.success(types.ReplacementStop(
    travel_time_to_stop: travel_time_to_stop,
    stop_id: stop_id,
  ))
}

// =============================================================================
// Enum Decoders
// =============================================================================

fn decode_stop_schedule_relationship(val: Int) -> StopTimeScheduleRelationship {
  case val {
    0 -> types.StopScheduled
    1 -> types.StopSkipped
    2 -> types.StopNoData
    3 -> types.StopUnscheduled
    _ -> types.StopScheduled
  }
}

fn decode_trip_schedule_relationship(val: Int) -> TripScheduleRelationship {
  case val {
    0 -> types.TripScheduled
    1 -> types.TripAdded
    2 -> types.TripUnscheduled
    3 -> types.TripCanceled
    5 -> types.TripReplacement
    6 -> types.TripDuplicated
    7 -> types.TripDeleted
    8 -> types.TripNew
    _ -> types.TripScheduled
  }
}

fn decode_vehicle_stop_status(val: Int) -> VehicleStopStatus {
  case val {
    0 -> types.IncomingAt
    1 -> types.StoppedAt
    2 -> types.InTransitTo
    _ -> types.InTransitTo
  }
}

fn decode_congestion_level(val: Int) -> CongestionLevel {
  case val {
    0 -> types.UnknownCongestionLevel
    1 -> types.RunningSmoothly
    2 -> types.StopAndGo
    3 -> types.Congestion
    4 -> types.SevereCongestion
    _ -> types.UnknownCongestionLevel
  }
}

fn decode_occupancy_status(val: Int) -> OccupancyStatus {
  case val {
    0 -> types.Empty
    1 -> types.ManySeatsAvailable
    2 -> types.FewSeatsAvailable
    3 -> types.StandingRoomOnly
    4 -> types.CrushedStandingRoomOnly
    5 -> types.Full
    6 -> types.NotAcceptingPassengers
    7 -> types.NoDataAvailable
    8 -> types.NotBoardable
    _ -> types.NoDataAvailable
  }
}

fn decode_alert_cause(val: Int) -> AlertCause {
  case val {
    1 -> types.UnknownCause
    2 -> types.OtherCause
    3 -> types.TechnicalProblem
    4 -> types.Strike
    5 -> types.Demonstration
    6 -> types.Accident
    7 -> types.Holiday
    8 -> types.Weather
    9 -> types.Maintenance
    10 -> types.Construction
    11 -> types.PoliceActivity
    12 -> types.MedicalEmergency
    _ -> types.UnknownCause
  }
}

fn decode_alert_effect(val: Int) -> AlertEffect {
  case val {
    1 -> types.NoService
    2 -> types.ReducedService
    3 -> types.SignificantDelays
    4 -> types.Detour
    5 -> types.AdditionalService
    6 -> types.ModifiedService
    7 -> types.OtherEffect
    8 -> types.UnknownEffect
    9 -> types.StopMoved
    10 -> types.NoEffect
    11 -> types.AccessibilityIssue
    _ -> types.UnknownEffect
  }
}

fn decode_severity_level(val: Int) -> SeverityLevel {
  case val {
    1 -> types.UnknownSeverity
    2 -> types.Info
    3 -> types.Warning
    4 -> types.Severe
    _ -> types.UnknownSeverity
  }
}

fn decode_drop_off_pickup_type(val: Int) -> DropOffPickupType {
  case val {
    0 -> types.Regular
    1 -> types.NoPickupDropOff
    2 -> types.PhoneAgency
    3 -> types.CoordinateWithDriver
    _ -> types.Regular
  }
}

fn decode_wheelchair_accessible(val: Int) -> WheelchairAccessible {
  case val {
    0 -> types.WheelchairNoValue
    1 -> types.WheelchairUnknown
    2 -> types.WheelchairAccessibleVehicle
    3 -> types.WheelchairInaccessible
    _ -> types.WheelchairNoValue
  }
}

fn decode_realtime_wheelchair_boarding(val: Int) -> RealtimeWheelchairBoarding {
  case val {
    0 -> types.RealtimeWheelchairUnknown
    1 -> types.RealtimeWheelchairAvailable
    2 -> types.RealtimeWheelchairNotAvailable
    _ -> types.RealtimeWheelchairUnknown
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

fn option_unwrap(opt: Option(a), default: a) -> a {
  case opt {
    Some(val) -> val
    None -> default
  }
}

fn option_map(opt: Option(a), f: fn(a) -> b) -> Option(b) {
  case opt {
    Some(val) -> Some(f(val))
    None -> None
  }
}

fn result_map(result: Result(a, e), f: fn(a) -> b) -> Result(b, e) {
  case result {
    Ok(val) -> Ok(f(val))
    Error(e) -> Error(e)
  }
}
