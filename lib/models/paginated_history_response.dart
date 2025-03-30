import 'historical_record.dart';

class PaginatedHistoryResponse {
  final List<HistoricalRecord> results;
  final String? nextPageUrl;
  final int totalCount;
  final int currentPage;

  PaginatedHistoryResponse({
    required this.results,
    this.nextPageUrl,
    required this.totalCount,
    required this.currentPage,
  });

  factory PaginatedHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedHistoryResponse(
      results:
          (json['results'] as List<dynamic>?)
              ?.map((item) => HistoricalRecord.fromJson(item))
              .toList() ??
          [],
      nextPageUrl: json['next'] as String?,
      totalCount: json['count'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
    );
  }

  bool get hasNextPage => nextPageUrl != null;
}
