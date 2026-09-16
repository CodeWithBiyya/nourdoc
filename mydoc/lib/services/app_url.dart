class AppUrls {
  //  static var baseUrl = 'http://182.180.59.232:8501/';   //server
  // static var baseUrl = 'http://192.168.1.3:8000/';    //local
  //static var baseUrl = 'https://ronald-contest-lie-necessity.trycloudflare.com/';   //public
  // static var baseUrl = 'https://vq7tqcjfce.execute-api.us-east-1.amazonaws.com/'; //AWS
  // static var awsBaseUrl = 'https://wd2rsrq9n6.execute-api.us-east-1.amazonaws.com/'; // for now aws .. bcz kuch api mai yeh use ho rha hai
  // static var baseUrl = "https://4ugllkifsb.execute-api.us-east-1.amazonaws.com/"; // producation url
    static var baseUrl = "https://8wfvyjajy1.execute-api.us-east-1.amazonaws.com/";  //dev

// jb bhi aws pr change krna hai to upload_Service mai bhi change krna hai or clicnical finding screeen wala urlbhi change ho ga


  static var health = '${baseUrl}health';
  // static var login = '${baseUrl}login'; // aws

  static var login = '${baseUrl}auth/login';  //prod
  static var register_user = '${baseUrl}auth/register';  // prod
  static var interference = '${baseUrl}inference';
  static var EncounterList = '${baseUrl}consultation/list/100';
  static var consultationsBase = '${baseUrl}consultations/';
  //static var consultationsEndpoint = '${awsBaseUrl}v2/consultations/'; //aws get consultation list
  // static var encounterDetailsApi = '${awsBaseUrl}v2/consultation/'; //aws get consultation info
  static var consultationsEndpoint = '${baseUrl}consultation/list/'; //production consultation list
  static var encounterDetailsApi = '${baseUrl}consultation/'; //producation get consultation info
  static var session_info = '${baseUrl}consultation/';
  // static var register_user = '${baseUrl}register';   //aws
  static var session_edit = '${baseUrl}consultation/edit/';
  // static var get_doctor_profile = '${baseUrl}doctor';
  // static var get_doctor_profile = '${awsBaseUrl}v2/doctor/';
  // static var get_doctor_profile = '${baseUrl}v2/doctor/';        //aws
  static var get_doctor_profile = '${baseUrl}doctor/';  //prod
  static var update_doctor_profile = '${baseUrl}doctor/';
  //  static var postBooking = '${awsBaseUrl}v2/book'; // aws
  static var postBooking = '${baseUrl}booking'; // prod

  // static var getBookedList = '${awsBaseUrl}v2/bookings/'; //aws
  static var getBookedList = '${baseUrl}booking/list/'; //prod
  static var feedback = '${baseUrl}feedback';
  static var riskEvaluation = "https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com/evaluation";

  //pricing
  static var pricingBaseUrl = "https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com/";

  static var pricingPlans = "${pricingBaseUrl}pricing/plans";
  static var activateTrial = "${pricingBaseUrl}entitlements/activate-trial";
  static var entitlementStatus = "${pricingBaseUrl}entitlements/status";
  static var initiateConsultation = "${pricingBaseUrl}consultations/initiate";
  static var startConsultation = "${pricingBaseUrl}consultations/"; // {job_id}/start
  static var planRequests = "${pricingBaseUrl}plan-requests";
  static String deleteBooking = "${baseUrl}booking";
}


  
