Pod::Spec.new do |s|
  s.name             = 'duo_kit'
  s.version          = '0.1.2'
  s.summary          = 'iPhone Duo and foldable layouts for Flutter.'
  s.description      = <<-DESC
Publishes what iPhone Duo reports natively, such as the vertical bar, the hinge
and the reserved regions of the window, to Flutter for duo_kit.
                       DESC
  s.homepage         = 'https://github.com/leancodepl/duo_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LeanCode' => 'https://leancode.co' }
  s.source           = { :path => '.' }
  s.source_files     = 'duo_kit/Sources/duo_kit/**/*'
  s.dependency 'Flutter'
  # Flutter's minimum, so that apps without iPhone Duo keep theirs.
  s.platform         = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
end
