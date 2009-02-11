module HTML

  class Node

    # Returns the next sibling node.
    def next_sibling()
      if siblings = parent.children
        siblings.each_with_index do |node, i|
          return siblings[i + 1] if node.equal?(self)
        end
      end
      nil
    end


    # Returns the previous sibling node.
    def previous_sibling()
      if siblings = parent.children
        siblings.each_with_index do |node, i|
          return siblings[i - 1] if node.equal?(self)
        end
      end
      nil
    end


    # Return the next element after this one. Skips sibling text nodes.
    #
    # With the +name+ argument, returns the next element with that name,
    # skipping other sibling elements.
    def next_element(name = nil)
      if siblings = parent.children
        found = false
        siblings.each do |node|
          if node.equal?(self)
            found = true
          elsif found && node.tag?
            return node if (name.nil? || node.name == name)
          end
        end
      end
      nil
    end


    # Return the previous element before this one. Skips sibling text
    # nodes.
    #
    # Using the +name+ argument, returns the previous element with
    # that name, skipping other sibling elements.
    def previous_element(name = nil)
      if siblings = parent.children
        found = nil
        siblings.each do |node|
          return found if node.equal?(self)
          found = node if node.tag? && (name.nil? || node.name == name)
        end
      end
      nil
    end


    # Detach this node from its parent.
    def detach()
      if @parent
        @parent.children.delete_if { |child| child.equal?(self) }
        @parent = nil
      end
      self
    end


    # Process each node beginning with the current node.
    def each(value = nil, &block)
      yield self, value
      if @children
        @children.each do |child|
          child.each value, &block
        end
      end
      value
    end

  end

end
