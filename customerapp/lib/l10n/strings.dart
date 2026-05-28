import '../app_settings.dart';

// ignore_for_file: non_constant_identifier_names
class S {
  static bool get _en => AppSettings.instance.isEnglish;

  // ── Navigation ───────────────────────────────────────────────────
  static String get home         => _en ? 'Home'        : 'หน้าหลัก';
  static String get orders       => _en ? 'Orders'      : 'ออเดอร์';
  static String get profile      => _en ? 'Profile'     : 'โปรไฟล์';

  // ── Common ───────────────────────────────────────────────────────
  static String get cancel       => _en ? 'Cancel'      : 'ยกเลิก';
  static String get confirm      => _en ? 'Confirm'     : 'ยืนยัน';
  static String get save         => _en ? 'Save'        : 'บันทึก';
  static String get ok           => _en ? 'OK'          : 'ตกลง';
  static String get back         => _en ? 'Back'        : 'ย้อนกลับ';
  static String get no           => _en ? 'No'          : 'ไม่';
  static String get yes          => _en ? 'Yes'         : 'ใช่';
  static String get free         => _en ? 'Free'        : 'ฟรี';
  static String get closed       => _en ? 'Closed'      : 'ปิดอยู่';
  static String get stores       => _en ? 'stores'      : 'ร้าน';

  // ── Home ─────────────────────────────────────────────────────────
  static String get allCategories     => _en ? 'All Categories'             : 'หมวดหมู่ทั้งหมด';
  static String get seeAll            => _en ? 'See All'                    : 'ดูทั้งหมด';
  static String get openRestaurants   => _en ? 'Open Restaurants'           : 'ร้านอาหารที่เปิด';
  static String get searchHint        => _en ? 'Search dishes, restaurants' : 'ค้นหาอาหาร ร้านอาหาร';
  static String get scanTitle         => _en ? 'Scan to Find'               : 'สแกนหาร้าน';
  static String get scanSubtitle      => _en ? 'Photo food, AI finds store' : 'ถ่ายรูปอาหาร AI หาร้านให้';
  static String get randomTitle       => _en ? 'Random Menu AI'             : 'สุ่มเมนู AI';
  static String get randomSubtitle    => _en ? "Can't decide? AI helps"     : 'ไม่รู้จะกินอะไร? AI ช่วย';
  static String get noRestaurant      => _en ? 'No restaurants found'       : 'ไม่พบร้านอาหาร';

  static String greeting(String name, int hour) {
    final g = hour < 12
        ? (_en ? 'Good Morning' : 'สวัสดีตอนเช้า')
        : hour < 17
            ? (_en ? 'Good Afternoon' : 'สวัสดีตอนบ่าย')
            : (_en ? 'Good Evening' : 'สวัสดีตอนเย็น');
    return 'Hey $name, $g!';
  }

  // ── Drawer ───────────────────────────────────────────────────────
  static String get drawerOrders      => _en ? 'My Orders'               : 'ออเดอร์ของฉัน';
  static String get drawerFav         => _en ? 'Favourite Stores'        : 'ร้านโปรด';
  static String get drawerAddress     => _en ? 'Delivery Addresses'      : 'ที่อยู่จัดส่ง';
  static String get drawerScan        => _en ? 'Scan Food AI'            : 'Scan Food AI';
  static String get drawerScanMatch   => _en ? 'Scan to Find Store'      : 'สแกนหาร้าน';
  static String get drawerRandom      => _en ? 'Random Menu AI'          : 'สุ่มเมนู AI';
  static String get drawerSupport     => _en ? 'Support'                 : 'ติดต่อฝ่ายสนับสนุน';
  static String get logout            => _en ? 'Log Out'                 : 'ออกจากระบบ';

  // ── Profile ──────────────────────────────────────────────────────
  static String get personalInfo      => _en ? 'Personal Info'           : 'ข้อมูลส่วนตัว';
  static String get addresses         => _en ? 'Addresses'               : 'ที่อยู่';
  static String get cart              => _en ? 'Cart'                    : 'ตะกร้า';
  static String get favourite         => _en ? 'Favourite'               : 'ร้านโปรด';
  static String get notifications     => _en ? 'Notifications'           : 'การแจ้งเตือน';
  static String get wallet            => _en ? 'Wallet'                  : 'กระเป๋าเงิน';
  static String get paymentMethod     => _en ? 'Payment Method'          : 'วิธีชำระเงิน';
  static String get contactAdmin      => _en ? 'Contact Support'         : 'ติดต่อฝ่ายสนับสนุน';
  static String get faqs              => _en ? 'FAQs'                    : 'คำถามที่พบบ่อย';
  static String get myReviews         => _en ? 'My Reviews'              : 'รีวิวของฉัน';
  static String get settings          => _en ? 'Settings'                : 'การตั้งค่า';
  static String get logoutQ           => _en ? 'Log out?'                : 'ออกจากระบบ?';
  static String get logoutMsg         => _en ? 'Are you sure you want to log out?' : 'คุณต้องการออกจากระบบใช่ไหม?';
  static String get appVersion        => _en ? 'Food Delivery v1.0.0'    : 'Food Delivery v1.0.0';

  // ── Settings ─────────────────────────────────────────────────────
  static String get appearance        => _en ? 'Appearance'              : 'ธีมและภาษา';
  static String get darkMode          => _en ? 'Dark Mode'               : 'โหมดมืด';
  static String get darkModeDesc      => _en ? 'Switch to dark theme'    : 'เปลี่ยนเป็นธีมมืด';
  static String get language          => _en ? 'Language'                : 'ภาษา';
  static String get languageDesc      => _en ? 'Thai / English'          : 'ไทย / English';
  static String get notifSection      => _en ? 'Notifications'           : 'การแจ้งเตือน';
  static String get pushNotif         => _en ? 'Push Notifications'      : 'Push Notifications';
  static String get pushNotifDesc     => _en ? 'Receive all notifications': 'รับการแจ้งเตือนทั้งหมด';
  static String get orderUpdates      => _en ? 'Order Updates'           : 'อัพเดทออเดอร์';
  static String get orderUpdatesDesc  => _en ? 'Order status notifications': 'แจ้งเตือนสถานะออเดอร์';
  static String get promotions        => _en ? 'Promotions'              : 'โปรโมชั่น';
  static String get promotionsDesc    => _en ? 'Receive news & promotions': 'รับข่าวสารและโปรโมชั่น';
  static String get about             => _en ? 'About'                   : 'เกี่ยวกับ';
  static String get version           => _en ? 'Version'                 : 'เวอร์ชัน';
  static String get privacyPolicy     => _en ? 'Privacy Policy'          : 'นโยบายความเป็นส่วนตัว';
  static String get terms             => _en ? 'Terms of Service'        : 'เงื่อนไขการใช้งาน';

  // ── Orders ───────────────────────────────────────────────────────
  static String get myOrders          => _en ? 'My Orders'               : 'ออเดอร์ของฉัน';
  static String get ongoing           => _en ? 'Ongoing'                 : 'กำลังดำเนินการ';
  static String get history           => _en ? 'History'                 : 'ประวัติ';
  static String get track             => _en ? 'Track'                   : 'ติดตาม';
  static String get rate              => _en ? 'Rate'                    : 'รีวิว';
  static String get rated             => _en ? 'Rated'                   : 'รีวิวแล้ว';
  static String get reorder           => _en ? 'Re-Order'                : 'สั่งอีกครั้ง';
  static String get noOngoing         => _en ? 'No ongoing orders'       : 'ไม่มีออเดอร์ที่กำลังดำเนินการ';
  static String get noHistory         => _en ? 'No order history yet'    : 'ยังไม่มีประวัติการสั่ง';
  static String get orderFood         => _en ? 'Order delicious food!'   : 'สั่งอาหารอร่อยๆ กันเถอะ!';
  static String get cancelOrder       => _en ? 'Cancel'                  : 'ยกเลิก';
  static String get cancelQ           => _en ? 'Cancel order?'           : 'ยกเลิกออเดอร์?';
  static String get cancelMsg         => _en ? 'Order not yet confirmed by store.\nCancel it?' : 'ออเดอร์ยังไม่ได้รับการยืนยันจากร้าน\nต้องการยกเลิกใช่ไหม?';
  static String get cancelFailed      => _en ? 'Cancellation failed. Try again.' : 'ยกเลิกไม่สำเร็จ กรุณาลองใหม่';
  static String get reportOrder       => _en ? 'Report this order'       : 'แจ้งปัญหาออเดอร์นี้';

  // ── Store ────────────────────────────────────────────────────────
  static String get freeDelivery      => _en ? 'Free'                    : 'ส่งฟรี';
  static String get min30             => _en ? '30 min'                  : '30 นาที';
  static String get allMenu           => _en ? 'All Menu'                : 'เมนูทั้งหมด';
  static String get viewCart          => _en ? 'View Cart'               : 'ดูตะกร้า';
  static String get addFav            => _en ? 'Add to Favourites'       : 'เพิ่มเป็นร้านโปรด';
  static String get removeFav         => _en ? 'Remove from Favourites'  : 'ลบออกจากร้านโปรด';
  static String get addedFav          => _en ? 'Added to favourites'     : 'เพิ่มร้านโปรดแล้ว';
  static String get removedFav        => _en ? 'Removed from favourites' : 'ลบออกจากร้านโปรดแล้ว';
  static String get shareStore        => _en ? 'Share Store'             : 'แชร์ร้านนี้';
  static String get storeCopied       => _en ? 'Store info copied'       : 'คัดลอกข้อมูลร้านแล้ว';
  static String get reportIssue       => _en ? 'Report Issue'            : 'รายงานปัญหา';
  static String get reportThanks      => _en ? 'Thank you!\nOur team will review shortly.' : 'ขอบคุณที่แจ้งปัญหา\nทีมงานจะตรวจสอบและดำเนินการโดยเร็ว';
  static String get changeStore       => _en ? 'Change Store'            : 'เปลี่ยนร้าน';
  static String get changeStoreQ      => _en ? 'Change restaurant?'      : 'เปลี่ยนร้านอาหาร?';
  static String changeStoreMsg(String n) => _en
      ? 'Items from "$n" are in your cart.\nClear and order from here?'
      : 'มีสินค้าจากร้าน "$n" อยู่ในตะกร้า\nต้องการล้างตะกร้าเพื่อสั่งจากร้านนี้แทนไหม?';

  // ── Cart ─────────────────────────────────────────────────────────
  static String get myCart            => _en ? 'My Cart'                 : 'ตะกร้าสินค้า';
  static String get emptyCart         => _en ? 'Your cart is empty'      : 'ตะกร้าว่างเปล่า';
  static String get emptyCartSub      => _en ? 'Add items from a restaurant first' : 'เพิ่มสินค้าจากร้านที่ต้องการก่อนนะ';
  static String get deliveryAddress   => _en ? 'Delivery Address'        : 'ที่อยู่จัดส่ง';
  static String get tapToSetAddress   => _en ? 'Tap to set delivery address' : 'แตะเพื่อปักหมุดที่อยู่จัดส่ง';
  static String get addressRequired   => _en ? 'Please select a delivery address' : 'กรุณาเลือกที่อยู่จัดส่ง';
  static String get change            => _en ? 'Change'                  : 'เปลี่ยน';
  static String get noteLabel         => _en ? 'Note (optional)'         : 'หมายเหตุ (ถ้ามี)';
  static String get noteHint          => _en ? 'e.g. No spicy, extra sauce...' : 'เช่น ไม่เผ็ด, เอาซอสเพิ่ม...';
  static String get foodCost          => _en ? 'Food'                    : 'ค่าอาหาร';
  static String get deliveryFee       => _en ? 'Delivery'                : 'ค่าจัดส่ง';
  static String get totalLabel        => _en ? 'Total'                   : 'รวมทั้งหมด';
  static String get discountLabel     => _en ? 'Discount'                : 'ส่วนลด';
  static String get splitBill         => _en ? 'Split with Friends'      : 'หารกับเพื่อน';
  static String get peopleCount       => _en ? 'People'                  : 'จำนวนคน';
  static String get perPerson         => _en ? 'Per person'              : 'ตกคนละ';
  static String selectPaymentBtn(String amt) => _en ? 'Select Payment ฿$amt' : 'เลือกการชำระเงิน ฿$amt';
  static String proceedBtn(String amt)       => _en ? 'Proceed  ฿$amt'       : 'ดำเนินการต่อ ฿$amt';
  static String get checkoutTitle     => _en ? 'Checkout'               : 'ยืนยันรายการ';
  static String get basket            => _en ? 'Cart'                    : 'ตะกร้าสินค้า';

  // ── Favourites ───────────────────────────────────────────────────
  static String get favourites        => _en ? 'Favourites'              : 'ร้านโปรด';
  static String get noFavourites      => _en ? 'No favourites yet'       : 'ยังไม่มีร้านโปรด';
  static String get noFavSub          => _en ? 'Tap the heart icon on store cards to add' : 'กดไอคอนหัวใจบนการ์ดร้านเพื่อเพิ่ม';

  // ── Reviews ──────────────────────────────────────────────────────
  static String get reviewsTitle      => _en ? 'My Reviews'              : 'รีวิวของฉัน';
  static String get noReviews         => _en ? 'No reviews yet'          : 'ยังไม่มีรีวิว';
  static String get noReviewsSub      => _en ? 'Reviews appear here after ordering' : 'รีวิวของคุณจะแสดงที่นี่หลังสั่งอาหาร';
  static String get storeLabel        => _en ? 'Restaurant'              : 'ร้านอาหาร';
  static String get riderLabel        => _en ? 'Rider'                   : 'คนส่ง';
}
