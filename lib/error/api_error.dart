class ApiError {
  final int status;
  final String? message;
  final String? code;
  final Map<String, List<String>>? errors;

  ApiError({
    required this.status,
    this.message,
    this.code,
    this.errors,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      status: json['status'],
      message: json['message'],
      code: json['code'],
      errors: json['errors'] != null
          ? Map<String, List<String>>.from(
        json['errors'].map(
              (k, v) => MapEntry(k, List<String>.from(v)),
        ),
      )
          : null,
    );
  }
}