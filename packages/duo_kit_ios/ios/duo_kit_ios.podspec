Pod::Spec.new do |s|
  s.name             = 'duo_kit_ios'
  s.version          = '0.1.0'
  s.summary          = 'The iOS side of duo_kit.'
  s.description      = <<-DESC
Publishes what iPhone Duo reports natively, such as the vertical bar, the hinge
and the reserved regions of the window, to Flutter for duo_kit.
                       DESC
  s.homepage         = 'https://github.com/leancodepl/duo_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LeanCode' => 'https://leancode.co' }
  s.source           = { :path => '.' }
  s.source_files     = 'duo_kit_ios/Sources/duo_kit_ios/**/*'
  s.dependency 'Flutter'
  # Xcode 27 rejects lower deployment targets.
  s.platform         = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
