#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint file_selector_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'file_selector_ios'
  s.version          = '0.0.1'
  s.summary          = 'iOS implementation of file_selector.'
  s.description      = <<-DESC
Displays the native iOS document picker.
                       DESC
  s.homepage         = 'https://github.com/flutter/packages/tree/main/packages/file_selector'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Flutter Dev Team' => 'flutter-dev@googlegroups.com' }
  s.source           = { :http => 'https://github.com/flutter/packages/tree/main/packages/file_selector/file_selector_ios' }
  s.source_files = 'Classes/**/*.{h,m}'
  s.module_map = 'Classes/FileSelectorPlugin.modulemap'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  s.resource_bundles = {'file_selector_ios_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
