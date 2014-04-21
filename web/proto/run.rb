puts "spawning:"
spawn('/bin/bash', "./slow_script.sh", :out => "slow.log")
puts "sleeping"
sleep(15)
puts "reading"
File.open("slow.log") { |f| puts f.read }
puts "done"
