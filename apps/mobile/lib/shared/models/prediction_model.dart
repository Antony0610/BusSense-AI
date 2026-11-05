import 'bus_model.dart';

/// Single Horizon Prediction Point
class PredictionPoint {
  final String timeOffset;
  final int minutesFromNow;
  final double predictedOccupancyPct;
  final CrowdLevel crowdLevel;
  final double confidence;
  final String dataOrigin;

  const PredictionPoint({
    required this.timeOffset,
    required this.minutesFromNow,
    required this.predictedOccupancyPct,
    required this.crowdLevel,
    required this.confidence,
    this.dataOrigin = 'PREDICTION',
  });

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      timeOffset: json['time_offset'] as String? ?? 'NOW',
      minutesFromNow: json['minutes_from_now'] as int? ?? 0,
      predictedOccupancyPct: (json['predicted_occupancy_pct'] as num?)?.toDouble() ?? 40.0,
      crowdLevel: CrowdLevel.fromString(json['crowd_level'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      dataOrigin: json['data_origin'] as String? ?? 'PREDICTION',
    );
  }
}

/// 4-Horizon Demand Prediction Model
class PredictionModel {
  final String busNumber;
  final String routeNumber;
  final String corridorName;
  final double nowOccupancyPct;
  final double plus15mOccupancyPct;
  final double plus30mOccupancyPct;
  final double plus60mOccupancyPct;
  final CrowdLevel nowCrowdLevel;
  final CrowdLevel plus15mCrowdLevel;
  final CrowdLevel plus30mCrowdLevel;
  final CrowdLevel plus60mCrowdLevel;
  final double confidenceScore;
  final String modelVersion;
  final List<PredictionPoint> points;
  final String dataOrigin;

  const PredictionModel({
    required this.busNumber,
    required this.routeNumber,
    required this.corridorName,
    required this.nowOccupancyPct,
    required this.plus15mOccupancyPct,
    required this.plus30mOccupancyPct,
    required this.plus60mOccupancyPct,
    this.nowCrowdLevel = CrowdLevel.low,
    this.plus15mCrowdLevel = CrowdLevel.low,
    this.plus30mCrowdLevel = CrowdLevel.moderate,
    this.plus60mCrowdLevel = CrowdLevel.moderate,
    this.confidenceScore = 0.88,
    this.modelVersion = 'xgboost-demand-v1',
    this.points = const [],
    this.dataOrigin = 'PREDICTION',
  });

  int get predictedOccupancy => nowOccupancyPct.round();

  factory PredictionModel.fromForecastList(String busNumber, List<dynamic> rawPoints) {
    final parsed = rawPoints
        .map((p) => PredictionPoint.fromJson(p as Map<String, dynamic>))
        .toList();

    PredictionPoint? pNow;
    PredictionPoint? p15;
    PredictionPoint? p30;
    PredictionPoint? p60;

    for (final pt in parsed) {
      if (pt.timeOffset == 'NOW') pNow = pt;
      if (pt.timeOffset == '+15 MIN') p15 = pt;
      if (pt.timeOffset == '+30 MIN') p30 = pt;
      if (pt.timeOffset == '+60 MIN') p60 = pt;
    }

    final nowPt = pNow ?? (parsed.isNotEmpty ? parsed[0] : const PredictionPoint(timeOffset: 'NOW', minutesFromNow: 0, predictedOccupancyPct: 40.0, crowdLevel: CrowdLevel.low, confidence: 0.88));
    final pt15 = p15 ?? (parsed.length > 1 ? parsed[1] : nowPt);
    final pt30 = p30 ?? (parsed.length > 2 ? parsed[2] : pt15);
    final pt60 = p60 ?? (parsed.length > 3 ? parsed[3] : pt30);

    return PredictionModel(
      busNumber: busNumber,
      routeNumber: 'Route $busNumber',
      corridorName: 'Kochi Transit Corridor',
      nowOccupancyPct: nowPt.predictedOccupancyPct,
      plus15mOccupancyPct: pt15.predictedOccupancyPct,
      plus30mOccupancyPct: pt30.predictedOccupancyPct,
      plus60mOccupancyPct: pt60.predictedOccupancyPct,
      nowCrowdLevel: nowPt.crowdLevel,
      plus15mCrowdLevel: pt15.crowdLevel,
      plus30mCrowdLevel: pt30.crowdLevel,
      plus60mCrowdLevel: pt60.crowdLevel,
      confidenceScore: nowPt.confidence,
      modelVersion: 'xgboost-demand-v1',
      points: parsed,
      dataOrigin: 'PREDICTION',
    );
  }

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    final horizon = json['horizon'] as Map<String, dynamic>? ?? {};
    final nowMap = horizon['now'] as Map<String, dynamic>? ?? {};
    final p15Map = horizon['plus_15m'] as Map<String, dynamic>? ?? {};
    final p30Map = horizon['plus_30m'] as Map<String, dynamic>? ?? {};
    final p60Map = horizon['plus_60m'] as Map<String, dynamic>? ?? {};

    final nowPct = (json['predicted_occupancy'] as num?)?.toDouble() ??
        (nowMap['occupancy_pct'] as num?)?.toDouble() ??
        41.8;
    final p15Pct = (p15Map['occupancy_pct'] as num?)?.toDouble() ?? 45.2;
    final p30Pct = (p30Map['occupancy_pct'] as num?)?.toDouble() ?? 52.0;
    final p60Pct = (p60Map['occupancy_pct'] as num?)?.toDouble() ?? 64.5;

    final nowCrowd = CrowdLevel.fromString((json['predicted_crowd_level'] as String?) ?? (nowMap['crowd_level'] as String?));
    final p15Crowd = CrowdLevel.fromString(p15Map['crowd_level'] as String?);
    final p30Crowd = CrowdLevel.fromString(p30Map['crowd_level'] as String?);
    final p60Crowd = CrowdLevel.fromString(p60Map['crowd_level'] as String?);

    return PredictionModel(
      busNumber: json['bus_number'] as String? ?? '205',
      routeNumber: json['route_number'] as String? ?? '12',
      corridorName: json['corridor_name'] as String? ?? 'Aluva - Vyttila Hub',
      nowOccupancyPct: nowPct,
      plus15mOccupancyPct: p15Pct,
      plus30mOccupancyPct: p30Pct,
      plus60mOccupancyPct: p60Pct,
      nowCrowdLevel: nowCrowd,
      plus15mCrowdLevel: p15Crowd,
      plus30mCrowdLevel: p30Crowd,
      plus60mCrowdLevel: p60Crowd,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.88,
      modelVersion: json['model_version'] as String? ?? 'xgboost-demand-v1',
      points: [
        PredictionPoint(timeOffset: 'NOW', minutesFromNow: 0, predictedOccupancyPct: nowPct, crowdLevel: nowCrowd, confidence: (json['confidence_score'] as num?)?.toDouble() ?? 0.88),
        PredictionPoint(timeOffset: '+15 MIN', minutesFromNow: 15, predictedOccupancyPct: p15Pct, crowdLevel: p15Crowd, confidence: 0.88),
        PredictionPoint(timeOffset: '+30 MIN', minutesFromNow: 30, predictedOccupancyPct: p30Pct, crowdLevel: p30Crowd, confidence: 0.88),
        PredictionPoint(timeOffset: '+60 MIN', minutesFromNow: 60, predictedOccupancyPct: p60Pct, crowdLevel: p60Crowd, confidence: 0.81),
      ],
      dataOrigin: json['data_origin'] as String? ?? 'PREDICTION',
    );
  }

  Map<String, dynamic> toJson() => {
        'bus_number': busNumber,
        'route_number': routeNumber,
        'corridor_name': corridorName,
        'predicted_occupancy': nowOccupancyPct.round(),
        'confidence_score': confidenceScore,
        'model_version': modelVersion,
        'horizon': {
          'now': {'occupancy_pct': nowOccupancyPct, 'crowd_level': nowCrowdLevel.value},
          'plus_15m': {'occupancy_pct': plus15mOccupancyPct, 'crowd_level': plus15mCrowdLevel.value},
          'plus_30m': {'occupancy_pct': plus30mOccupancyPct, 'crowd_level': plus30mCrowdLevel.value},
          'plus_60m': {'occupancy_pct': plus60mOccupancyPct, 'crowd_level': plus60mCrowdLevel.value},
        },
        'data_origin': dataOrigin,
      };
}
