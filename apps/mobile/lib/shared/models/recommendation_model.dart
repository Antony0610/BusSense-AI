import 'bus_model.dart';

/// Single Bus Option from Recommendation Engine
class BusRecommendationItem {
  final String busNumber;
  final String routeNumber;
  final String routeName;
  final String operatorType;
  final int etaMins;
  final double occupancyPct;
  final CrowdLevel crowdLevel;
  final bool isRecommended;
  final double journeyScore;
  final String whyRecommended;
  final double? crowdSavingVsAlternativePct;
  final int? timeSavingMins;
  final double fareInr;
  final String dataOrigin;

  const BusRecommendationItem({
    required this.busNumber,
    required this.routeNumber,
    required this.routeName,
    required this.operatorType,
    required this.etaMins,
    required this.occupancyPct,
    required this.crowdLevel,
    required this.isRecommended,
    required this.journeyScore,
    required this.whyRecommended,
    this.crowdSavingVsAlternativePct,
    this.timeSavingMins,
    required this.fareInr,
    this.dataOrigin = 'RECOMMENDATION',
  });

  factory BusRecommendationItem.fromJson(Map<String, dynamic> json) {
    return BusRecommendationItem(
      busNumber: json['bus_number'] as String? ?? '',
      routeNumber: json['route_number'] as String? ?? '',
      routeName: json['route_name'] as String? ?? '',
      operatorType: json['operator_type'] as String? ?? 'KSRTC',
      etaMins: json['eta_mins'] as int? ?? 5,
      occupancyPct: (json['occupancy_pct'] as num?)?.toDouble() ?? 40.0,
      crowdLevel: CrowdLevel.fromString(json['crowd_level'] as String?),
      isRecommended: json['is_recommended'] as bool? ?? false,
      journeyScore: (json['journey_score'] as num?)?.toDouble() ?? 50.0,
      whyRecommended: json['why_recommended'] as String? ?? '',
      crowdSavingVsAlternativePct: (json['crowd_saving_vs_alternative_pct'] as num?)?.toDouble(),
      timeSavingMins: json['time_saving_mins'] as int?,
      fareInr: (json['fare_inr'] as num?)?.toDouble() ?? 20.0,
      dataOrigin: json['data_origin'] as String? ?? 'RECOMMENDATION',
    );
  }

  Map<String, dynamic> toJson() => {
        'bus_number': busNumber,
        'route_number': routeNumber,
        'route_name': routeName,
        'operator_type': operatorType,
        'eta_mins': etaMins,
        'occupancy_pct': occupancyPct,
        'crowd_level': crowdLevel.value,
        'is_recommended': isRecommended,
        'journey_score': journeyScore,
        'why_recommended': whyRecommended,
        'crowd_saving_vs_alternative_pct': crowdSavingVsAlternativePct,
        'time_saving_mins': timeSavingMins,
        'fare_inr': fareInr,
        'data_origin': dataOrigin,
      };
}

/// Explainable Journey Plan Recommendation
class JourneyPlanModel {
  final String originStop;
  final String destinationStop;
  final BusRecommendationItem recommendedBus;
  final List<BusRecommendationItem> alternativeBuses;
  final double routeDistanceKm;
  final int estimatedTravelTimeMins;
  final String explanation;
  final String dataOrigin;

  const JourneyPlanModel({
    required this.originStop,
    required this.destinationStop,
    required this.recommendedBus,
    required this.alternativeBuses,
    required this.routeDistanceKm,
    required this.estimatedTravelTimeMins,
    required this.explanation,
    this.dataOrigin = 'RECOMMENDATION',
  });

  factory JourneyPlanModel.fromJson(Map<String, dynamic> json) {
    final recJson = json['recommended_bus'] as Map<String, dynamic>? ?? {};
    final altList = json['alternative_buses'] as List<dynamic>? ?? [];

    return JourneyPlanModel(
      originStop: json['origin_stop'] as String? ?? '',
      destinationStop: json['destination_stop'] as String? ?? '',
      recommendedBus: BusRecommendationItem.fromJson(recJson),
      alternativeBuses: altList.map((e) => BusRecommendationItem.fromJson(e as Map<String, dynamic>)).toList(),
      routeDistanceKm: (json['route_distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedTravelTimeMins: json['estimated_travel_time_mins'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
      dataOrigin: json['data_origin'] as String? ?? 'RECOMMENDATION',
    );
  }

  Map<String, dynamic> toJson() => {
        'origin_stop': originStop,
        'destination_stop': destinationStop,
        'recommended_bus': recommendedBus.toJson(),
        'alternative_buses': alternativeBuses.map((b) => b.toJson()).toList(),
        'route_distance_km': routeDistanceKm,
        'estimated_travel_time_mins': estimatedTravelTimeMins,
        'explanation': explanation,
        'data_origin': dataOrigin,
      };
}
