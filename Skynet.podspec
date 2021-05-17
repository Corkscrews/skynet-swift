#
# Be sure to run `pod lib lint Skynet.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Skynet'
  s.version          = '0.1.4'
  s.summary          = 'Skynet SDK for iOS and macOS'

  s.description      = <<-DESC
  Use Sia Skynet in your iOS or macOS projects (Decentralized database)
                       DESC

  s.homepage         = 'https://github.com/ppamorim/skynet-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Pedro Paulo de Amorim' => 'pp.amorim@hotmail.com' }
  s.source           = { :git => 'https://github.com/ppamorim/skynet-swift.git', :tag => s.version.to_s }

  s.source_files =
    'Sources/**/*.swift',
    'Sources/Blake2b/*.{h,m,c}',
    'Sources/Blake2b/**/*.{h,m,c}'

  s.swift_versions = ['5.2']
  s.ios.deployment_target = '12.1'
  s.osx.deployment_target = '10.12'
  
  s.dependency 'CryptoSwift', '~> 1.4.0'
  s.dependency 'ed25519swift', '~> 1.2.8'
  s.dependency 'TweetNacl'

end
