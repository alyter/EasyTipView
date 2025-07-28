platform :ios, '15.0'
use_frameworks!

target 'PolyPal' do
  # Your local, prebuilt Zoho frameworks
  pod 'ZCCoreFramework', :path => 'local-pods/ZCCoreFramework'
  pod 'ZCUIFramework',    :path => 'local-pods/ZCUIFramework'
  pod 'ZohoPortalAuth',   :path => 'local-pods/ZohoPortalAuth'
  pod 'GLTFSceneKitTemp', :path => 'local-pods/GLTFSceneKit' 

  # ALL dependencies required by ZCUIFramework (from otool analysis)
  pod 'CropViewController'
  pod 'EasyTipView'
  #pod 'GLTFSceneKit'
  pod 'PhoneNumberKit'
  pod 'PromisesObjC'       # FBLPromises
  pod 'PromisesSwift'      # Promises
  pod 'ReachabilitySwift'  # Reachability (different name)
  pod 'SQLite.swift'       # SQLite (different name)
  pod 'SwiftSoup'
  pod 'Zip', '~> 2.1'
  pod 'ZIPFoundation', '~> 0.9'
  # Note: ZMLKit and SQLiteWrapper may be internal Zoho dependencies

  target 'PolyPalTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    # Disable the privacy manifest generation
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_PRIVACY_MANIFEST'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      
      # Set Swift 5 mode for dependencies with concurrency issues
      if ['SwiftSoup', 'PhoneNumberKit', 'SQLite.swift', 'ReachabilitySwift'].include?(target.name)
        config.build_settings['SWIFT_VERSION'] = '5.0'
      end
      
      # Add proper runpath search paths for framework linking
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= []
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '@executable_path/Frameworks'
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '@loader_path/Frameworks'
    end
  end
  
  # # Create symbolic link for GLTFSceneKitTemp (ZCUIFramework expects this exact name)
  # gltf_original = "#{installer.sandbox.root}/GLTFSceneKit/GLTFSceneKit.framework"
  # gltf_temp_dir = "#{installer.sandbox.root}/GLTFSceneKitTemp"
  # gltf_temp_framework = "#{gltf_temp_dir}/GLTFSceneKitTemp.framework"
  
  # if File.exist?(gltf_original)
  #   puts "🔧 Creating GLTFSceneKitTemp framework link for ZCUIFramework..."
    
  #   # Remove existing if present
  #   FileUtils.rm_rf(gltf_temp_dir) if File.exist?(gltf_temp_dir)
    
  #   # Create the directory structure
  #   FileUtils.mkdir_p(gltf_temp_dir)
    
  #   # Create symbolic link with correct path structure
  #   FileUtils.ln_sf("../GLTFSceneKit/GLTFSceneKit.framework", gltf_temp_framework)
    
  #   puts "✅ GLTFSceneKitTemp.framework created at: #{gltf_temp_framework}"
  # else
  #   puts "❌ GLTFSceneKit.framework not found at: #{gltf_original}"
  # end
  
  # Add framework name mappings for dependencies with different names
  puts "🔧 Setting up framework name mappings..."
  
  # Map ReachabilitySwift -> Reachability
  reachability_original = "#{installer.sandbox.root}/ReachabilitySwift/Reachability.framework"
  reachability_link = "#{installer.sandbox.root}/Reachability"
  
  if File.exist?(reachability_original) && !File.exist?(reachability_link)
    FileUtils.mkdir_p(reachability_link)
    FileUtils.ln_sf("../ReachabilitySwift/Reachability.framework", "#{reachability_link}/Reachability.framework")
    puts "✅ Reachability framework mapping created"
  end
  
  # Map SQLite.swift -> SQLite
  sqlite_original = "#{installer.sandbox.root}/SQLite.swift/SQLite.framework"
  sqlite_link = "#{installer.sandbox.root}/SQLite"
  
  if File.exist?(sqlite_original) && !File.exist?(sqlite_link)
    FileUtils.mkdir_p(sqlite_link)
    FileUtils.ln_sf("../SQLite.swift/SQLite.framework", "#{sqlite_link}/SQLite.framework")
    puts "✅ SQLite framework mapping created"
  end
end
