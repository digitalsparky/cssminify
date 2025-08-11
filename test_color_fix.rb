#!/usr/bin/env ruby
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'cssminify2'

puts "Testing color name optimization fix:"

# Test the exact failing case
input = ".c1{color:#FF0000}.c2{color:#000080}.c3{color:#808080}.c4{color:#808000}.c5{color:#800080}.c6{color:#C0C0C0}.c7{color:#008080}.c8{color:#FFA500}.c9{color:#800000}"
expected = ".c1{color:red}.c2{color:navy}.c3{color:gray}.c4{color:olive}.c5{color:purple}.c6{color:silver}.c7{color:teal}.c8{color:orange}.c9{color:maroon}"

puts "Input:    #{input}"
output = CSSminify2.compress(input)
puts "Output:   #{output}"
puts "Expected: #{expected}"
puts "Match:    #{output == expected ? '✅ YES' : '❌ NO'}"

if output != expected
  puts "\nDifferences:"
  # Check each color individually
  colors_to_test = [
    ['#FF0000', 'red'],
    ['#000080', 'navy'], 
    ['#808080', 'gray'],
    ['#808000', 'olive'],
    ['#800080', 'purple'],
    ['#C0C0C0', 'silver'],
    ['#008080', 'teal'],
    ['#FFA500', 'orange'],
    ['#800000', 'maroon']
  ]
  
  colors_to_test.each do |hex, name|
    if output.include?(hex.downcase) || output.include?(hex.upcase)
      puts "  #{hex} should be #{name} (saves #{hex.length - name.length} chars)"
    end
  end
end