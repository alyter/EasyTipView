#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'PolyPal.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the PolyPal target
target = project.targets.find { |t| t.name == 'PolyPal' }

if target
  # Disable sandboxing for all configurations
  target.build_configurations.each do |config|
    config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    puts "Disabled sandboxing for #{config.name} configuration"
  end
  
  # Save the project
  project.save
  puts "Project saved successfully"
else
  puts "Could not find PolyPal target"
end
