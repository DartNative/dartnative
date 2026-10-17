# The auto-scroll driver as a pod, for the apps built with CocoaPods (the
# DartNative app's Podfile names it; setup.sh adds it to the React Native
# app's). The Swift app compiles the source directly (native/ios/project.yml).
Pod::Spec.new do |s|
  s.name = 'BenchAutoScroll'
  s.version = '1.0.0'
  s.summary = 'Flings the list from inside the app, for the scrolling benchmark.'
  s.description = 'Flings the list from inside the app, for the scrolling benchmark. Idle unless the app is launched with BENCH_AUTOSCROLL.'
  s.homepage = 'https://github.com/DartNative/dartnative/tree/main/benchmarks/scrollable'
  s.license = { :type => 'DartNative Framework License', :text => 'See the LICENSE file at the root of the repository.' }
  s.author = 'DartNative Team'
  s.source = { :path => '.' }
  s.platform = :ios, '15.0'
  s.source_files = 'BenchAutoScroll.m'
  s.frameworks = 'UIKit'
  # Linked into the app's own binary, as the Swift app compiles the source
  # into its own: a framework of its own would add a library for the
  # system to load and check at every launch, which the other apps do not
  # carry.
  s.static_framework = true
end
