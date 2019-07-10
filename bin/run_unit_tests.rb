require 'trent'

ci = Trent.new(:color => :light_blue, :local => true)

workspace = "Example/Teller.xcworkspace"
scheme = "Teller-Example"
iphoneSimulator = "iphonesimulator"

testsSuccessIndicatorString = "0 failed, 0 errored"

ci.sh("xcodebuild -quiet -workspace #{workspace} -scheme #{scheme} -sdk #{iphoneSimulator} build-for-testing")

# For some reason, when running xctool on Travis, even when all tests pass, it says that something failed. So, manually check. 
result = ci.sh("xctool -workspace #{workspace} -scheme #{scheme} -sdk #{iphoneSimulator} run-tests", :fail_non_success => false)
if !result[:output].include? testsSuccessIndicatorString 
  puts "Tests failed"
  exit 1
else 
  exit 0
end 