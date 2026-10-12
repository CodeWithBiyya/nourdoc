

class Constants{
  // static Map< int, ShopOrder>  cartitemModel  = new  Map< int, ShopOrder> () ;
static String Stripe_Id = '';
   // for delivery options
   static const int SHOP_OWNED_DELIVERY = 1;
   static const int UBER_EATS_DELIVERY = 2;
   static const int DOOR_DASH_DELIVERY =3;


   static int SHOP_ID =  21;

   // For pre order dtatus
/*   API control/public/api/shops/10
   param name: order_accepting_status
   here are conditions for this*/
// 	0 = pre order
//  1 = open
//  2 = finished trading
//  3 = closed today

static const int PRE_ORDER = 0;
   static const int SHOP_OPEN = 1;
   static const int FINISH_TRADING = 2;
   static const int CLOSED_TODAY = 3;


   static String itemUnavailabilityStatus = "1";
   static int selectedTabForDeliveryType = 0;

   // static   ShopDetailsModel? shopDetailsModel =null ;
}

