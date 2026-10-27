Pod::Spec.new do |s|
  s.name             = 'samvaad_widget'
  s.version          = '0.1.0'
  s.summary          = 'Samvaad chat for Flutter apps (iOS binding).'
  s.description      = <<-DESC
Flutter plugin binding over the Samvaad iOS SDK.
                       DESC
  s.homepage         = 'https://github.com/sachdesk/samvaad-flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = 'Sachdesk'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Samvaad', '~> 0.1.0'
  s.platform         = :ios, '15.0'
  s.swift_version    = '5.9'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
