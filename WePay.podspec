Pod::Spec.new do |s|
  s.name              = "WePay"
  s.version           = "5.0.1"
  s.summary           = "WePay binary for both simulator and iOS devices"
  s.description       = "A library that helps WePay partners develop their own iOS apps aimed at merchants and/or consumers for collection of payments via various payment methods"
  s.homepage          = "http://github.com/wepay/wepay-ios"
  s.documentation_url = 'http://wepay.github.io/wepay-ios/'
  s.license           = { :type => 'MIT', :file => 'LICENSE' }
  s.source            = { :http => "https://github.com/wepay/wepay-ios/releases/download/v#{s.version}/wepay-ios-#{s.version}.zip" }
  s.authors           = { 'Chaitanya Bagaria' => 'mobile@wepay.com' }
  
  s.ios.deployment_target = '7.0'
  s.ios.requires_arc = true  

  s.ios.preserve_paths   = '**'
  s.public_header_files = 'WePay.framework/**/*.h'
  s.vendored_frameworks  = 'WePay.framework', 'TrustDefenderMobile.framework'


  s.ios.frameworks = 'AudioToolbox', 'AVFoundation', 'CoreBluetooth', 'CoreTelephony', 'MediaPlayer', 'SystemConfiguration'
  s.ios.libraries  = 'stdc++.6.0.9'
end