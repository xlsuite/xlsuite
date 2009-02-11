$LOAD_PATH.unshift('../lib')
require 'tidy'
Tidy.path = '/usr/lib/tidylib.so'
html = '<html><title>title</title>Body</html>'
xml = Tidy.open(:show_warnings=>true) do |tidy|
  tidy.options.output_xml = true
  puts tidy.options.show_warnings
  xml = tidy.clean(html)
  puts tidy.errors
  puts tidy.diagnostics
  xml
end
puts xml
