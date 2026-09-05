Pod::Spec.new do |s|
  s.name             = 'dartnative_share'
  s.version          = '1.0.0'
  s.summary          = 'Native share sheet plugin for DartNative (UIActivityViewController).'
  s.description      = <<-DESC
    Share plugin for DartNative.
    Wraps UIActivityViewController for text sharing with zero Flutter
    platform channels — pure FFI @_cdecl bridge.
  DESC
  s.homepage         = 'https://github.com/DartNative/dartnative_share'
  s.license          = { :type => 'BSD-3-Clause' }
  s.author           = { 'DartNative' => 'hello@dartnative.com' }
  s.platform         = :ios, '13.0'

  s.source           = { :path => '.' }

  s.source_files     = 'Classes/**/*.swift'
  s.frameworks       = 'UIKit', 'Foundation'

  s.swift_version    = '5.9'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }
end
