#
# Be sure to run `pod lib lint Skynet.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Skynet'
  s.version          = '0.1.0'
  s.summary          = 'Skynet SDK for iOS and macOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Use Sia Skynet in your iOS or macOS projects (Decentralized database)
                       DESC

  s.homepage         = 'https://github.com/ppamorim/skynet-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Pedro Paulo de Amorim' => 'pp.amorim@hotmail.com' }
  s.source           = { :git => 'https://github.com/ppamorim/skynet-swift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.source_files = 'Sources/**/*.swift', 'Sources/**/Blake2b/*.{h,m,c}'
  s.swift_versions = ['5.2']
  s.ios.deployment_target = '12.1'
  s.osx.deployment_target = '10.14'
  
  # s.resource_bundles = {
  #   'Skynet' => ['Skynet/Assets/*.png']
  # }

  # s.public_header_files = 'Sources/**/*.h'
  s.dependency 'CryptoSwift', '~> 1.4.0'
  s.dependency 'ed25519swift', '~> 1.2.5'
end
