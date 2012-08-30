require 'diff/lcs'
require 'diff/lcs/string'
require 'json'

class String
# colorization
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red
    colorize(self, 31)
end
def green
    colorize(self, 32)
end
def yellow
    colorize(self, 33)
end
def pink
    colorize(self, 35)
end
end

av0 = File.read(File.join(File.dirname(__FILE__), "fixture", "article_rv0.md"))
av1 = File.read(File.join(File.dirname(__FILE__), "fixture", "article_rv1.md"))

# print Diff::LCS.LCS(av0,av1)
# puts Diff::LCS.diff(av0, av1)
# Diff::LCS.sdiff(av0, av1).each { |d|
#   puts d.inspect
# }

# puts new_article = Dif::LCS.patch!()
# Diff::LCS.traverse_sequences(av0, av1) { |d|
#   puts d.inspect
# }

# Patching
# diffs = Diff::LCS.diff(av0.split("\n"), av1.split("\n"))
diffs = Diff::LCS.diff(av0.split("\n"), [])
# diffs = av0.sdiff(av1)
dump = Marshal.dump(diffs)

puts dump.length

dump_json = Marshal.load(dump)
# puts dump_json
diffs = dump_json
av0_1 = Diff::LCS.patch!(av0.split("\n"), diffs).join("\n")
# puts av0_1
puts av1 == av0_1
av1_0 = Diff::LCS.unpatch!(av1.split("\n"), diffs).join("\n")
# puts av1_0
puts av0 == av1_0

diffs.each { |dset|
  dset.each { |d|
    colored_element = d.action == '-' ? d.element.red : d.element.green
    puts "#{d.position+1} #{d.action} #{colored_element}"
  }
}
puts dump.length