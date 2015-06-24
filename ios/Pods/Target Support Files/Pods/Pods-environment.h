
// To check if a library is compiled with CocoaPods you
// can use the `COCOAPODS` macro definition which is
// defined in the xcconfigs so it is available in
// headers also when they are imported in the client
// project.


// Fabric
#define COCOAPODS_POD_AVAILABLE_Fabric
#define COCOAPODS_VERSION_MAJOR_Fabric 1
#define COCOAPODS_VERSION_MINOR_Fabric 2
#define COCOAPODS_VERSION_PATCH_Fabric 3

// Fabric/Core
#define COCOAPODS_POD_AVAILABLE_Fabric_Core
#define COCOAPODS_VERSION_MAJOR_Fabric_Core 1
#define COCOAPODS_VERSION_MINOR_Fabric_Core 2
#define COCOAPODS_VERSION_PATCH_Fabric_Core 3

// Fabric/Crashlytics
#define COCOAPODS_POD_AVAILABLE_Fabric_Crashlytics
#define COCOAPODS_VERSION_MAJOR_Fabric_Crashlytics 1
#define COCOAPODS_VERSION_MINOR_Fabric_Crashlytics 2
#define COCOAPODS_VERSION_PATCH_Fabric_Crashlytics 3

// Mixpanel/AppExtension
#define COCOAPODS_POD_AVAILABLE_Mixpanel_AppExtension
#define COCOAPODS_VERSION_MAJOR_Mixpanel_AppExtension 2
#define COCOAPODS_VERSION_MINOR_Mixpanel_AppExtension 8
#define COCOAPODS_VERSION_PATCH_Mixpanel_AppExtension 0

// PMEDatePicker
#define COCOAPODS_POD_AVAILABLE_PMEDatePicker
#define COCOAPODS_VERSION_MAJOR_PMEDatePicker 0
#define COCOAPODS_VERSION_MINOR_PMEDatePicker 0
#define COCOAPODS_VERSION_PATCH_PMEDatePicker 1

// TTTAttributedLabel
#define COCOAPODS_POD_AVAILABLE_TTTAttributedLabel
#define COCOAPODS_VERSION_MAJOR_TTTAttributedLabel 1
#define COCOAPODS_VERSION_MINOR_TTTAttributedLabel 10
#define COCOAPODS_VERSION_PATCH_TTTAttributedLabel 1

// Debug build configuration
#ifdef DEBUG

  // Reveal-iOS-SDK
  #define COCOAPODS_POD_AVAILABLE_Reveal_iOS_SDK
  #define COCOAPODS_VERSION_MAJOR_Reveal_iOS_SDK 1
  #define COCOAPODS_VERSION_MINOR_Reveal_iOS_SDK 5
  #define COCOAPODS_VERSION_PATCH_Reveal_iOS_SDK 1

  // SimulatorStatusMagic
  #define COCOAPODS_POD_AVAILABLE_SimulatorStatusMagic
  #define COCOAPODS_VERSION_MAJOR_SimulatorStatusMagic 1
  #define COCOAPODS_VERSION_MINOR_SimulatorStatusMagic 5
  #define COCOAPODS_VERSION_PATCH_SimulatorStatusMagic 0

#endif
