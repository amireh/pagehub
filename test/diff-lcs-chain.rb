require 'diff/lcs'
require 'diff/lcs/string'
require 'diff/lcs/array'

def patch_info p
  stats = { add: 0, rem: 0 }
  p.each { |dset| dset.each { |d| d.action == '-' ? stats[:rem] += 1 : stats[:add] += 1} }
  "#{stats[:add]} additions, #{stats[:rem]} removals"
end

a = "Hello world!"
patch1 = a.diff("Good bye good world!")

puts patch_info patch1

a = Diff::LCS.patch!(a, patch1)
puts a == "Good bye good world!"
puts "2. #{a}"

# p2
patch2 = a.diff("#{a}\nWhat the fuck\n\nis going on here?")

puts patch_info patch2

a = Diff::LCS.patch!(a, patch2)
puts "3. #{a}"

# p3
patch3 = a.diff("This is gonna be bad.")

puts patch_info patch3

a = Diff::LCS.patch!(a, patch3)
puts "4. #{a}"

puts "\nRolling back:\n"

a = a.unpatch!(patch3)
puts "4->3 #{a}"
puts "\n--\n"
a = a.unpatch!(patch2)
puts "3->2 #{a}"

puts "\n--\n"
a = a.unpatch!(patch1)
puts "2->1 #{a}"

