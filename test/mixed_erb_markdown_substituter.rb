mixed = File.read(File.join("fixture", "greeting.html"))

btag = '<markdown>'
etag = '</markdown>'

marker_begin = mixed.index(btag)
while marker_begin && marker_begin >= 0

  marker_end = mixed.index(etag, marker_begin)
  puts "Found a Markdown block @ #{marker_begin}-#{marker_end}:"
  md = mixed[marker_begin+btag.length..marker_end-1]
  md = md.lines.map { |l| l.gsub(/^[ ]+/, '') }.join
  puts md
  # mixed[marker_begin..marker_end+etag.length-1] = "MARKDOWN HERE"

  marker_begin = mixed.index(btag, marker_end+1)
end

# puts mixed