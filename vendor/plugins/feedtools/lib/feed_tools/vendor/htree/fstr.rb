# :stopdoc:
require 'htree/modules'

module HTree
  def HTree.with_frozen_string_hash
    if Thread.current[:htree_frozen_string_hash]
      yield
    else
      begin
        Thread.current[:htree_frozen_string_hash] = {}
        yield
      ensure
        Thread.current[:htree_frozen_string_hash] = nil
      end
    end
  end

  def HTree.frozen_string(str)
    if h = Thread.current[:htree_frozen_string_hash]
      if s = h[str]
        s
      else
        h[str] = str unless str.frozen?
        str = str.dup.freeze
        h[str] = str
      end
    else
      str = str.dup.freeze unless str.frozen?
      str
    end
  end
end
# :startdoc:
