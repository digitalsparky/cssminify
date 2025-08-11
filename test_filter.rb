#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'cssminify2'

puts "Testing filter property preservation:"

# Test filter property should NOT convert #FFFFFF to white
filter_test = ".test { filter: chroma(color = #FFFFFF); }"
puts "Input:  #{filter_test}"
output = CSSminify2.compress(filter_test)
puts "Output: #{output}"

if output.include?('#ffffff') || output.include?('#fff') || output.include?('#FFFFFF')
  puts "✅ PASS - Filter colors preserved as hex"
else
  puts "❌ FAIL - Filter color was converted (breaks IE)"
end

# Test normal colors should still convert
normal_test = ".test { color: #FF0000; background: #FF0000; }"  
puts "\nInput:  #{normal_test}"
output2 = CSSminify2.compress(normal_test)
puts "Output: #{output2}"

if output2.include?('red') && !output2.include?('#ff0000')
  puts "✅ PASS - Normal colors converted to names"
else
  puts "❌ FAIL - Normal colors not converted"
end