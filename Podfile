project 'TranscribeTool/TranscribeTool.xcodeproj/'

platform :macos, '10.13'

target 'TranscribeTool' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!


  pod 'SAMKeychain'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '10.13'
    end
  end
end
