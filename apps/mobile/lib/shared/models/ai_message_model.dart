import 'package:flutter/foundation.dart';

/// Semantic classification of transit assistant response
enum AIResponseType {
  knowledge,
  liveData,
  prediction,
  recommendation,
  ticketData,
  activeJourney,
  insufficientInformation;

  static AIResponseType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'LIVE_DATA':
        return AIResponseType.liveData;
      case 'PREDICTION':
        return AIResponseType.prediction;
      case 'RECOMMENDATION':
        return AIResponseType.recommendation;
      case 'TICKET_DATA':
        return AIResponseType.ticketData;
      case 'ACTIVE_JOURNEY':
        return AIResponseType.activeJourney;
      case 'INSUFFICIENT_INFORMATION':
        return AIResponseType.insufficientInformation;
      case 'KNOWLEDGE':
      default:
        return AIResponseType.knowledge;
    }
  }

  String get label {
    switch (this) {
      case AIResponseType.liveData:
        return 'LIVE DATA';
      case AIResponseType.prediction:
        return 'PREDICTION';
      case AIResponseType.recommendation:
        return 'RECOMMENDATION';
      case AIResponseType.ticketData:
        return 'TICKET DATA';
      case AIResponseType.activeJourney:
        return 'ACTIVE JOURNEY';
      case AIResponseType.insufficientInformation:
        return 'INSUFFICIENT INFO';
      case AIResponseType.knowledge:
        return 'VERIFIED KNOWLEDGE';
    }
  }
}

/// Structured verified knowledge citation or live telemetry provider reference
@immutable
class AISourceItem {
  final String? id;
  final String title;
  final String sourceType;
  final String? snippet;
  final String? reference;

  const AISourceItem({
    this.id,
    required this.title,
    required this.sourceType,
    this.snippet,
    this.reference,
  });

  factory AISourceItem.fromJson(Map<String, dynamic> json) {
    return AISourceItem(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Verified Source',
      sourceType: json['source_type'] as String? ?? 'KNOWLEDGE',
      snippet: json['snippet'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'source_type': sourceType,
      if (snippet != null) 'snippet': snippet,
      if (reference != null) 'reference': reference,
    };
  }
}

/// Actionable deep link returned by AI assistant
@immutable
class AIActionItem {
  final String label;
  final String actionType; // VIEW_BUS, SHOW_TICKET, TRACK_HUD, EXPLORE_ROUTES, CROWD_FORECAST, ASK_QUERY
  final Map<String, dynamic>? payload;

  const AIActionItem({
    required this.label,
    required this.actionType,
    this.payload,
  });

  factory AIActionItem.fromJson(Map<String, dynamic> json) {
    return AIActionItem(
      label: json['label'] as String? ?? 'Action',
      actionType: json['action_type'] as String? ?? 'EXPLORE_ROUTES',
      payload: json['payload'] is Map<String, dynamic> ? json['payload'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'action_type': actionType,
      if (payload != null) 'payload': payload,
    };
  }
}

/// In-memory conversational chat message
@immutable
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AIResponseType responseType;
  final List<String> sources;
  final List<AISourceItem> sourceItems;
  final List<AIActionItem> actions;
  final String dataOrigin;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.responseType = AIResponseType.knowledge,
    this.sources = const [],
    this.sourceItems = const [],
    this.actions = const [],
    this.dataOrigin = 'GROUNDED RAG',
  });
}

/// Response payload from POST /api/ai/chat
@immutable
class AIQueryResponse {
  final String answer;
  final AIResponseType responseType;
  final List<String> sources;
  final List<AISourceItem> sourceItems;
  final List<AIActionItem> actions;
  final List<String> suggestedActions;
  final double? confidence;
  final String dataOrigin;

  const AIQueryResponse({
    required this.answer,
    required this.responseType,
    this.sources = const [],
    this.sourceItems = const [],
    this.actions = const [],
    this.suggestedActions = const [],
    this.confidence,
    this.dataOrigin = 'DEVELOPMENT FALLBACK',
  });

  factory AIQueryResponse.fromJson(Map<String, dynamic> json) {
    final rawType = json['response_type'] as String?;
    final rawSources = json['sources'] is List
        ? (json['sources'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final rawSourceItems = json['source_items'] is List
        ? (json['source_items'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => AISourceItem.fromJson(e))
            .toList()
        : <AISourceItem>[];
    final rawActions = json['actions'] is List
        ? (json['actions'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => AIActionItem.fromJson(e))
            .toList()
        : <AIActionItem>[];
    final rawSuggested = json['suggested_actions'] is List
        ? (json['suggested_actions'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return AIQueryResponse(
      answer: json['answer'] as String? ?? 'No response generated.',
      responseType: AIResponseType.fromString(rawType),
      sources: rawSources,
      sourceItems: rawSourceItems,
      actions: rawActions,
      suggestedActions: rawSuggested,
      confidence: (json['confidence'] as num?)?.toDouble(),
      dataOrigin: json['data_origin'] as String? ?? 'DEVELOPMENT FALLBACK',
    );
  }
}
