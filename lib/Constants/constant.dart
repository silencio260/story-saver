class AppConstants {
  // static String WHATSAPP_PATH = "/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses";
  static List<String> WHATSAPP_PATH_LIST = [
  "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
  "/storage/emulated/0/Pictures/Saved Statuses/"
  ];

  static String WHATSAPP_PATH =
      "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses";

  static String TEST_STORYSAVER_PATH =
      "/storage/emulated/0/Pictures/Story Saver/";


  static String DEVELOPER_SPECIAL_SAVED_STORY_PATH =
      "Story Saver";

  static String USER_SAVED_STORY_PATH =
      "Saved Statuses";
  
  static String SAVED_STORY_PATH =  (const String.fromEnvironment("founders_version ") == "true") ? DEVELOPER_SPECIAL_SAVED_STORY_PATH :
  USER_SAVED_STORY_PATH;
  // static String DEVELOPER_SPECIAL_SAVED_STORY_PATH =
  //     "/storage/emulated/0/Pictures/Story Saver/";
  //
  // static String SAVED_STORY_PATH =
  //     "/storage/emulated/0/Pictures/Saved Statuses/";
}
