# Buffer structure.
#
class Tidybuf

  extend DL::Importable
  
  # Access TidyBuffer instance.
  #
  attr_reader(:struct)

  # Mimic TidyBuffer.
  #
  TidyBuffer = struct [
    "byte* bp",
    "uint size",
    "uint allocated",
    "uint next"
  ]

  def initialize
    @struct = TidyBuffer.malloc
  end
    
  # Free current contents and zero out.
  #
  def free
    Tidylib.buf_free(@struct)
  end

  # Convert to array.
  #
  def to_a
    to_s.split("\r\n")
  end

  # Convert to string.
  #
  def to_s
    @struct.bp ? @struct.bp.to_s(@struct.size) : ''
  end

end
