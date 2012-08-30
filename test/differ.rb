require 'differ'

av0 = File.read(File.join(File.dirname(__FILE__), "fixture", "article_rv0.md"))
av1 = File.read(File.join(File.dirname(__FILE__), "fixture", "article_rv1.md"))

Differ.format = :color

puts Differ.diff(av0, av1)