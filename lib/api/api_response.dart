class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? rawData;
  final dynamic errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.rawData,
    this.errors,
  });

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? rawData,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      rawData: rawData,
    );
  }

  factory ApiResponse.error({
    String? message,
    int? statusCode,
    dynamic errors,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }
}