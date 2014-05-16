#!/usr/local/bin/macruby

require 'dispatch'
job = Dispatch::Job.new { Math.sqrt(10**100) }
@result = job.value
puts "value (sync): #{@result} => 1.0e+50"

job.value {|v| puts "value (async): #{v} => 1.0e+50" } # (eventually)
job.join
puts "join done (sync)"

job.join { puts "join done (async)" }
job.add { Math.sqrt(2**64) }
job.value {|b| puts "value (async): #{b} => 4294967296.0" }
@values = job.values
puts "values: #{@values.inspect} => [1.0E50]"
job.join
puts "values: #{@values.inspect} => [1.0E50, 4294967296.0]"
job = Dispatch::Job.new {}
@hash = job.synchronize Hash.new
puts "synchronize: #{@hash.class} => Dispatch::Proxy"

puts "values: #{job.values.class} => Dispatch::Proxy"

@hash[:foo] = :bar
puts "proxy: #{@hash} => {:foo=>:bar}"
@hash.delete :foo


[64, 100].each do |n|
	job.add { @hash[n] = Math.sqrt(10**n) }
end
job.join
puts "proxy: #{@hash} => {64 => 1.0E32, 100 => 1.0E50}"

@hash.inspect { |s| puts "inspect: #{s} => {64 => 1.0E32, 100 => 1.0E50}" }
delegate = @hash.__value__
puts "\n__value__: #{delegate.class} => Hash"

n = 42
job = Dispatch::Job.new { puts "n (during): #{n} => 42" }
job.join

n = 0
job = Dispatch::Job.new { n = 21 }
job.join
puts "n (after): #{n} => 0?!?"
n = 0
job = Dispatch::Job.new { n += 84 }
job.join
puts "n (+=): #{n} => 0?!?"
5.times { |i| print "#{10**i}\t" }
puts "times"

5.p_times { |i| print "#{10**i}\t" }
puts "p_times"

5.p_times(3) { |i| print "#{10**i}\t" }
puts "p_times(3)"
DAYS=%w(Mon Tue Wed Thu Fri)
DAYS.each { |day| print "#{day}\t"}
puts "each"
DAYS.p_each { |day| print "#{day}\t"}
puts "p_each"
DAYS.p_each(3) { |day| print "#{day}\t"}
puts "p_each(3)"
DAYS.each_with_index { |day, i | print "#{i}:#{day}\t"}
puts "each_with_index"
DAYS.p_each_with_index { |day, i | print "#{i}:#{day}\t"}
puts "p_each_with_index"
DAYS.p_each_with_index(3) { |day, i | print "#{i}:#{day}\t"}
puts "p_each_with_index(3)"
print (0..4).map { |i| "#{10**i}\t" }.join
puts "map"

print (0..4).p_map { |i| "#{10**i}\t" }.join
puts "p_map"
print (0..4).p_map(3) { |i| "#{10**i}\t" }.join
puts "p_map(3)"
mr = (0..4).p_mapreduce(0) { |i| 10**i }
puts "p_mapreduce: #{mr} => 11111"
mr = (0..4).p_mapreduce([], :concat) { |i| [10**i] }
puts "p_mapreduce(:concat): #{mr} => [1, 1000, 10, 100, 10000]"

mr = (0..4).p_mapreduce([], :concat, 3) { |i| [10**i] }
puts "p_mapreduce(3): #{mr} => [1000, 10000, 1, 10, 100]"
puts "find_all | p_find_all | p_find_all(3)"
puts (0..4).find_all { |i| i.odd? }.inspect
puts (0..4).p_find_all { |i| i.odd? }.inspect
puts (0..4).p_find_all(3) { |i| i.odd? }.inspect

puts "find | p_find | p_find(3)"
puts (0..4).find { |i| i == 5 }.nil? # => nil
puts (0..4).p_find { |i| i == 5 }.nil? # => nil
puts (0..4).p_find(3) { |i| i == 5 }.nil? # => nil
puts "#{(0..4).find { |i| i.odd? }} => 1"
puts "#{(0..4).p_find { |i| i.odd? }} => 1?"
puts "#{(0..4).p_find(3) { |i| i.odd? }} => 3?"
puts
puts q = Dispatch::Queue.new("org.macruby.queue.example")
q.sync { puts "queue sync" }

q.async { puts "queue async" }

puts "queue join"
q.join
puts
puts semaphore = Dispatch::Semaphore.new(0)
q.async {
	puts "semaphore signal"
	semaphore.signal
}

puts "semaphore wait"
semaphore.wait


puts
timer = Dispatch::Source.periodic(0.4) do |src|
 	puts "Dispatch::Source.periodic: #{src.data}"
end
sleep 1 # => 1 1 ...

timer.suspend!
puts "suspend!"
sleep 1
timer.resume!
puts "resume!"
sleep 1 # => 1 2 1 ...
timer.cancel!
puts "cancel!"
puts
@sum = 0
adder = Dispatch::Source.add do |s|
 	puts "Dispatch::Source.add: #{s.data} (#{@sum += s.data})"
	semaphore.signal
end
adder << 1
semaphore.wait
puts "sum: #{@sum} => 1"
adder.suspend!
adder << 3
adder << 5
puts "sum: #{@sum} => 1"
adder.resume!
semaphore.wait
puts "sum: #{@sum} => 9"
adder.cancel!
@mask = 0
masker = Dispatch::Source.or do |s|
	@mask |= s.data
	puts "Dispatch::Source.or: #{s.data.to_s(2)} (#{@mask.to_s(2)})"
	semaphore.signal
end
masker << 0b0001
semaphore.wait
puts "mask: #{@mask.to_s(2)} => 1"
masker.suspend!
masker << 0b0011
masker << 0b1010
puts "mask: #{@mask.to_s(2)} => 1"
masker.resume!
semaphore.wait
puts "mask: #{@mask.to_s(2)} => 1011"
masker.cancel!
puts

@event = 0
mask = Dispatch::Source::PROC_EXIT | Dispatch::Source::PROC_SIGNAL
proc_src = Dispatch::Source.process($$, mask) do |s|
	@event |= s.data
	puts "Dispatch::Source.process: #{s.data.to_s(2)} (#{@event.to_s(2)})"
	semaphore.signal
end


semaphore2 = Dispatch::Semaphore.new(0)
@events = []
mask2 = [:exit, :fork, :exec, :signal]
proc_src2 = Dispatch::Source.process($$, mask2) do |s|
	these = Dispatch::Source.data2events(s.data)
	@events += these
	puts "Dispatch::Source.process: #{these} (#{@events})"
	semaphore2.signal
end
sig_usr1 = Signal.list["USR1"]
Signal.trap(sig_usr1, "IGNORE")
Process.kill(sig_usr1, $$)
Signal.trap(sig_usr1, "DEFAULT")
semaphore.wait
result = @event & mask
print "@event: #{result.to_s(2)} =>"
puts  " #{Dispatch::Source::PROC_SIGNAL.to_s(2)} (Dispatch::Source::PROC_SIGNAL)"
proc_src.cancel!
semaphore2.wait
puts "@events: #{(result2 = @events & mask2)} => [:signal]"
proc_src2.cancel!
puts "event2num: #{Dispatch::Source.event2num(result2[0]).to_s(2)} => #{result.to_s(2)}"
puts "data2events: #{Dispatch::Source.data2events(result)} => #{result2}"
@signals = 0
sig_usr2 = Signal.list["USR2"]
signal = Dispatch::Source.signal(sig_usr2) do |s|
	puts "Dispatch::Source.signal: #{s.data} (#{@signals += s.data})"
	semaphore.signal
end
puts "signals: #{@signals} => 0"
signal.suspend!
Signal.trap(sig_usr2, "IGNORE")
3.times { Process.kill(sig_usr2, $$) }
Signal.trap(sig_usr2, "DEFAULT")
signal.resume!
semaphore.wait
puts "signals: #{@signals} => 3"
signal.cancel!
puts
@fevent = 0
@msg = "#{$$}-#{Time.now.to_s.gsub(' ','_')}"
puts "msg: #{@msg}"
filename = "/tmp/dispatch-#{@msg}"
puts "filename: #{filename}"
file = File.open(filename, "w")
fmask = Dispatch::Source::VNODE_DELETE | Dispatch::Source::VNODE_WRITE
file_src = Dispatch::Source.file(file.fileno, fmask, q) do |s|
	@fevent |= s.data
	puts "Dispatch::Source.file: #{s.data.to_s(2)} (#{@fevent.to_s(2)})"
	semaphore.signal
end
file.print @msg
file.flush
file.close
semaphore.wait(0.1)
print "fevent: #{(@fevent & fmask).to_s(2)} =>"
puts " #{Dispatch::Source::VNODE_WRITE.to_s(2)} (Dispatch::Source::VNODE_WRITE)"
File.delete(filename)
semaphore.wait(0.1)
print "fevent: #{@fevent.to_s(2)} => #{fmask.to_s(2)}"
puts " (Dispatch::Source::VNODE_DELETE | Dispatch::Source::VNODE_WRITE)"
file_src.cancel!
q.join

@fevent2 = []
file = File.open(filename, "w")
fmask2 = %w(delete write)
file_src2 = Dispatch::Source.file(file, fmask2) do |s|
	@fevent2 += Dispatch::Source.data2events(s.data)
	puts "Dispatch::Source.file: #{Dispatch::Source.data2events(s.data)} (#{@fevent2})"
	semaphore2.signal
end
file.print @msg
file.flush
semaphore2.wait(0.1)
puts "fevent2: #{@fevent2} => [:write]"
file_src2.cancel!

file = File.open(filename, "r")
@input = ""
reader = Dispatch::Source.read(file) do |s|
	@input << file.read(s.data)
	puts "Dispatch::Source.read: #{s.data}: #{@input}"
end
while (@input.size < @msg.size) do; end
puts "input: #{@input} => #{@msg}" # => e.g., 74323-2010-07-07_15:23:10_-0700
reader.cancel!
file = File.open(filename, "w")
@next_char = 0
writer = Dispatch::Source.write(file) do |s|
	if @next_char < @msg.size then
		char = @msg[@next_char]
		file.write(char)
		@next_char += 1
		puts "Dispatch::Source.write: #{char}|#{@msg[@next_char..-1]}"
	end
end
while (@next_char < @msg.size) do; end
puts "output: #{File.read(filename)} => #{@msg}" # e.g., 74323-2010-07-07_15:23:10_-0700
File.delete(filename)

