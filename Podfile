# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'tourismtemplate' do
  project 'tourismtemplate.xcodeproj'
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'XamoomSDK', :git => 'https://github.com/xamoom/xamoom-ios-sdk.git'
  pod 'Reachability'
  pod 'ImageSlideshow', :path => './ImageSlideshow'
  pod 'ImageSlideshow/SDWebImage', :path => './ImageSlideshow'
  pod 'MBProgressHUD', '~> 1.0.0'
  pod 'GoogleAnalytics'
  pod 'Firebase'#, #'~> 5.15.0'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Mapbox-iOS-SDK', '~> 5.2.0'
  pod 'QRCodeReader.swift', '~> 8.2.0'
  pod 'RMPickerViewController', '~> 2.3.1'
end

post_install do |installer|
  installer.aggregate_targets.each do |target|
    copy_pods_resources_path = "Pods/Target Support Files/#{target.name}/#{target.name}-resources.sh"
    string_to_replace = '--compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"'
    assets_compile_with_app_icon_arguments = '--compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${BUILD_DIR}/assetcatalog_generated_info.plist"'
    text = File.read(copy_pods_resources_path)
    new_contents = text.gsub(string_to_replace, assets_compile_with_app_icon_arguments)
    File.open(copy_pods_resources_path, "w") {|file| file.puts new_contents }
  end
end
