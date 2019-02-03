require 'trent'

ci = Trent.new(:color => :light_blue, :local => true)

ci.sh("xcodebuild test -workspace Example/Teller.xcworkspace -scheme Teller-Example -destination 'platform=iOS Simulator,OS=12.1,name=iPhone XR' test")