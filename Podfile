# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'PolyPal' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Zoho Creator iOS SDK Dependencies
  pod 'ZohoPortalAuth'
  pod 'ZCUIFramework'

  target 'PolyPalTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Fix for framework embedding issues in Xcode 16
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['SKIP_INSTALL'] = 'YES'
      
      # Disable bitcode for all pods (not needed for iOS 15+)
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Fix sandbox issues with CropViewController
      if target.name == 'CropViewController'
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
  
  # Disable sandboxing for the main project's embed frameworks script
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      if target.name == 'Pods-PolyPal'
        target.build_phases.each do |build_phase|
          if build_phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
            if build_phase.name&.include?('Embed Pods Frameworks')
              build_phase.shell_script = build_phase.shell_script.gsub('rsync --delete', 'rsync --delete --no-perms --no-owner --no-group')
            end
          end
        end
      end
    end
  end
end
