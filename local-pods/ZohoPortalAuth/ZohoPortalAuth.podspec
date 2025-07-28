Pod::Spec.new do |s|
  s.name         = 'ZohoPortalAuth'
  s.version      = '1.0.4'
  s.summary      = 'Zoho Client Portal Apps user login OAuth framework'
  s.homepage     = 'https://www.zoho.com/accounts/help/'
  s.authors      = { 'ZOHO' => 'support@zoho.com' }
  s.license      = { :type => 'MIT' }

  s.platform     = :ios, '15.0'
  s.swift_versions = ['4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '5.10']

  s.source = { :path => '.' }  # ✅ Required even for local

  s.vendored_frameworks = 'ZohoPortalAuthKit.framework'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }

  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
end
