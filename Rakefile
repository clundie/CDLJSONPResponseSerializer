namespace :test do
  desc "Run the CDLJSONPResponseSerializer Tests for iOS"
  task :ios do
    $ios_success = system("xctool -workspace CDLJSONPResponseSerializer.xcworkspace -scheme 'iOS Tests' -sdk iphonesimulator7.0 -configuration Release test -test-sdk iphonesimulator -freshInstall")
  end

  desc "Run the CDLJSONPResponseSerializer Tests for Mac OS X"
  task :osx do
    $osx_success = system("xctool -workspace CDLJSONPResponseSerializer.xcworkspace -scheme 'OS X Tests' -sdk macosx10.9 -configuration Release test -test-sdk macosx")
  end
end

desc "Run the CDLJSONPResponseSerializer Tests for iOS & Mac OS X"
task :test => ['test:ios', 'test:osx'] do
  puts "\033[0;31m! iOS unit tests failed" unless $ios_success
  puts "\033[0;31m! OS X unit tests failed" unless $osx_success
  if $ios_success && $osx_success
    puts "\033[0;32m** All tests executed successfully"
  else
    exit(-1)
  end
end

task :default => 'test'
