

abstract class BaseApiService{
  Future<dynamic> getGetResponse(String url, String token);
  Future<dynamic> getPostApiResponse(String url, Map<String, String> data, String? token);
  Future<dynamic> getPostApiResponseWithoutParam(String url);
  // Future<dynamic> getPostApiResponseRaw(String url, dynamic data);
  Future<dynamic> getPostApiResponseRaw(String url, dynamic data, String? token);

  Future<dynamic> putApiResponseRaw(String url, dynamic data, String token);


}