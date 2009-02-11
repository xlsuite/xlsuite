# :stopdoc:
require 'htree/modules'

module HTree::Container # :nodoc:
  # +children+ returns children nodes as an array.
  def children
    @children.dup
  end
end
# :startdoc:
