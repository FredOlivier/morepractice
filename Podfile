# Podfile

# Specify the minimum iOS deployment target for your app.
# Start with a reasonable modern version like 14.0 or 13.0.
# If 'pod install' fails due to GoogleWebRTC requiring a higher version,
# adjust this upwards accordingly. Avoid unnecessarily high versions like 17.0
# unless you specifically intend to only support the latest OS.
platform :ios, '14.0' # <-- EXAMPLE: Start here, adjust if needed

# Enable this if you are using Swift and want pods integrated as dynamic frameworks
# (Most modern Swift projects use this).
use_frameworks!

#target 'Morepractice' do
  # Pods for your main application target 'Morepractice'

  # Add the WebRTC pod


  # --- Add ALL other pods your main app target needs here ---
  # Example: Firebase pods (you likely have these already)
  # pod 'FirebaseCore'
  # pod 'FirebaseAuth'
  # pod 'FirebaseFirestore'
  # pod 'Socket.IO-Client-Swift' # If you installed Socket.IO via CocoaPods
  # ... etc.

  # --- DO NOT add 'use_frameworks!' again inside the target block ---

  # Pods only needed for unit tests go in the Tests target
  target 'MorepracticeTests' do
    inherit! :search_paths # Inherits pods from the parent 'Morepractice' target
    # Add pods specific to unit testing below, if any
    # Example: pod 'Quick', pod 'Nimble'
  end

  # Pods only needed for UI tests go in the UITests target
  target 'MorepracticeUITests' do
    inherit! :search_paths # Inherits pods from the parent 'Morepractice' target
    # Add pods specific to UI testing below, if any
  end

 # End of 'Morepractice' target block

# --- Post Install Hooks (Optional but common) ---
# Example: Disabling warnings for specific pods
# post_install do |installer|
#   installer.pods_project.targets.each do |target|
#     target.build_configurations.each do |config|
#       # Example: config.build_settings['GCC_WARN_UNUSED_VARIABLE'] = 'NO'
#       # Example: config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0' # Can also set here
#     end
#   end
# end