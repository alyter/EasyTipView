Pod::Spec.new do |s|
  s.name         = 'ZCCoreFramework'
  s.version      = '3.0-beta16.0'
  s.summary      = 'ZCCoreFramework that interacts with Zoho Creator Rest API'
  s.homepage     = 'https://creator.zoho.com/'
  s.authors      = { 'ZOHO' => 'support@zoho.com' }
  s.license      = {
    :type => 'MIT',
    :text => <<-LICENSE
MIT License

Copyright (c) 2023 Zoho Creator

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE
      LICENSE
  }
  s.platform     = :ios, '15.0'
  s.source       = { :path => '.' }  # ✅ Required even for local

  s.vendored_frameworks = 'ZCCoreFramework.framework'
  s.dependencies = {
    'PromisesSwift'     => '2.4.0',
    'PhoneNumberKit'    => '3.7.10',
    'SwiftSoup'         => '1.7.4',
    'ReachabilitySwift' => '5.2.4',
    'ZMLKit'            => '3.0-beta16.0',
    'SQLite.swift'      => '0.15.3',
    'SQLite.Wrapper'    => '3.0-beta16.0'
  }
  s.swift_versions = ['4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '5.10']
end
