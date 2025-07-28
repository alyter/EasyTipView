Pod::Spec.new do |s|
  s.name         = 'ZCUIFramework'
  s.version      = '3.0-beta16.0'
  s.summary      = 'ZCUIFramework that provides UI Interfaces of Zoho Creator'
  s.homepage     = 'https://creator.zoho.com/'
  s.authors      = { 'Zoho' => 'support@zoho.com' }
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.platform     = :ios, '12.0'
  s.source       = { :path => '.' }  # ✅ Required even for local
  s.vendored_frameworks = 'ZCUIFramework.framework'
  s.swift_versions = ['4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '5.10']
end
