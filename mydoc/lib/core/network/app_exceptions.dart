class AppExceptions implements Exception {
  final _message;
  final _prefix;

  AppExceptions(this._message, this._prefix);

  String toString() {
    final text = _message?.toString().trim() ?? '';
    if (text.isEmpty) return _prefix.toString();
    return text;
  }
}

class FetchDataException extends AppExceptions {

  FetchDataException([String? message])
      : super(message, "Error during communication with server");

}

class BadRequestException extends AppExceptions {

  BadRequestException([String? message])
      : super(message, "Invalid Request");

}
class UnauthorisedException extends AppExceptions {
  UnauthorisedException([String? message])
      : super(message, "Unauthorised Request: ");
}

// 🚩 YE BHI ADD KAR LEIN (Optional but good)
class InvalidInputException extends AppExceptions {
  InvalidInputException([String? message])
      : super(message, "Invalid Input: ");
}
