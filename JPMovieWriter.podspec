#
# Be sure to run `pod lib lint JPMovieWriter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JPMovieWriter'
  s.version          = '0.1.0'
  s.summary          = 'JPMovieWriter_Demo.'
  
  s.description      = <<-DESC
    基于GPUImage的GPUImageMovieWriter，添加[暂停/继续]录制的功能。
                       DESC

  s.homepage         = 'https://github.com/Rogue24/JPMovieWriter_Demo'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhoujianping' => 'zhoujianping24@hotmail.com' }
  s.source           = { :git => 'https://github.com/Rogue24/JPMovieWriter_Demo.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'

  s.source_files = 'JPMovieWriter/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JPMovieWriter' => ['JPMovieWriter/Assets/*.png']
  # }

  s.dependency 'GPUImage', '~> 0.1.7'
end
