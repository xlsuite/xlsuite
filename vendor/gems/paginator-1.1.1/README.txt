paginator
    by Bruce Williams
    http://codefluency.com

== DESCRIPTION:
  
Paginator is a simple pagination class that provides a generic interface suitable
for use in any Ruby program.

== FEATURES/PROBLEMS:
  
Paginator doesn't make any assumptions as to how data is retrieved; you just
have to provide it with the total number of objects and a way to pull a specific
set of objects based on the offset and number of objects per page.

== SYNOPSIS:

In both of these examples I'm using a PER_PAGE constant (the number of items per page), but it's merely for labeling purposes.

You could, of course, just pass in the number of items per page directly to the initializer without assigning it somewhere beforehand.

=== In a Rails Application

  def index
    @pager = ::Paginator.new(Foo.count, PER_PAGE) do |offset, per_page|
      Foo.find(:all, :limit => per_page, :offset => offset)
    end
    @page = @pager.page(params[:page])
    # respond_to here if you want it
  end

  # In your view
  <% @page.each do |foo| %>
    <%# Show something for each item %>
  <% end %>
  <%= @page.number %>
  <%= link_to("Prev", foos_url(:page => @page.prev.number)) if @page.prev? %>
  <%= link_to("Next", foos_url(:page => @page.next.number)) if @page.next? %>

=== Anything else

  bunch_o_data = (1..60).to_a
  pager = Paginator.new(bunch_o_data.size, PER_PAGE) do |offset, per_page|
    bunch_o_data[offset,per_page]
  end
  pager.each do |page|
    puts "Page ##{page.number}"
    page.each do |item|
      puts item
    end
  end

== REQUIREMENTS:

None.

== INSTALL:

No special instructions.

== LICENSE:

(The MIT License)

Copyright (c) 2006-2007 Bruce Williams (http://codefluency.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
