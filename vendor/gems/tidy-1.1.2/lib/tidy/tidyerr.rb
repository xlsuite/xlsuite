# Parameterized error message.
#
class Tidyerr < String
  
  # Error parameter.
  #
  attr_reader :severity, :line, :column, :message

  # Create new instance.
  #
  def initialize(error)
    super(error.to_s)
    parameterize
  end
  
  # Parse error message into parameters (where applicable).
  #
  def parameterize
    if to_str[0,4] == 'line'
      tokens    = to_str.split(' ', 7)
      @severity = tokens[5][0,1] # W or E
      @line     = tokens[1].to_i
      @column   = tokens[3].to_i
      @message  = tokens[6]
    end
  end

  protected :parameterize

end
