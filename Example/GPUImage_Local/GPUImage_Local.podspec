#
# Be sure to run `pod lib lint QWLottie.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GPUImage_Local'
  s.version          = '0.1.0'
  s.summary          = 'GPUImage in local.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  GPUImage in local.
                       DESC

  s.homepage         = 'https://github.com/zhoujianping/GPUImage_Local'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhoujianping' => 'zhoujianping24@hotmail.com' }
  s.source           = { :git => 'https://github.com/zhoujianping/GPUImage_Local.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
  s.platform   = :ios, "10.0"
  s.frameworks = 'UIKit'
  s.static_framework = true
  
  s.subspec 'Source' do |so|
    so.source_files = "GPUImage/Source/**/*.{h,m}"
  end
  
  s.subspec 'Resources' do |re|
    re.source_files = "GPUImage/Resources/**/*.png"
  end #QWOCTools
end
