
Pod::Spec.new do |s|
  s.name             = 'MMapKV'
  s.version          = '0.1.0'
  s.summary          = 'MMap Key-Value storage.'

  s.description      = <<-DESC
                       MMap Key-Value storage.
                       DESC

  s.homepage         = 'https://github.com/pozi119/MMapKV'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Valo Lee' => 'pozi119@163.com' }
  s.source           = { :git => 'https://github.com/pozi119/MMapKV.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.watchos.deployment_target = '3.0'

  s.source_files = 'MMapKV/Classes/**/*'
  s.dependency 'AnyCoder', '~> 0.1.3'

end
