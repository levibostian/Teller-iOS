#
# Be sure to run `pod lib lint Teller.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Teller'
  s.version          = '0.5.0'
  s.summary          = "iOS library that manages your app's cached data with ease."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The data used in your mobile app: user profiles, a collection of photos, list of friends, etc. all have state. Your data is in 1 of many different states:

* Being fetched for the first time (if it comes from an async network call)
* The data is empty
* Data exists in the device's storage (cached).
* During the empty and data states, your app could also be fetching fresh data to replace the cached data on the device that is out of date.

Determining what state your data is in and managing it can be a big pain. That is where Teller comes in. All you need to do is tell Teller how to save your data, query your data, and how to fetch fresh data (probably with a network API call) and Teller facilities everything else for you. Teller will query your cached data, parse it to determine the state of it, fetch fresh data if the cached data is too old, and deliver the state of the data to listeners so you can update the UI to your users.
                       DESC

  s.homepage         = 'https://github.com/levibostian/Teller-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Levi Bostian' => 'levi.bostian@gmail.com' }
  s.source           = { :git => 'https://github.com/levibostian/Teller-iOS.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/levibostian'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source_files = 'Teller/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Teller' => ['Teller/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'  
  s.dependency 'RxSwift', '~> 5.0'
end
