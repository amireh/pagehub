$ROOT = File.join(File.dirname(__FILE__), "..")
$LOAD_PATH << $ROOT

require 'nokogiri'
require 'lib/common'

f = File.read("Configuring-grind")
html_doc = Nokogiri::HTML(f) do |config| config.noerror end
# html_doc.xpath("//*[@id]").each { |node| node.remove_attribute "id" }
set = html_doc.xpath("//div[@class='markdown-body']")
h = ["h1","h2","h3","h4","h5","h6"]
i = 0
set.children.each { |n|
  if h.include? n.name then
    n['id'] = "toc_#{i}"
    i += 1

    puts "Modified #{n.name} => #{n.text} \##{n['id']}"
  end
}