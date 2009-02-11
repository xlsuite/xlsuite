# Ruby interface to Tidylib.
#
class Tidyobj

  # Diagnostics Buffer (Array of String).
  #
  attr_reader(:diagnostics)

  # Access the tidy instance.
  #
  attr_reader(:doc)

  # Error Buffer (Array of Tidyerr).
  #
  attr_reader(:errors)

  # Options interface (Tidyopt).
  #
  attr_reader(:options)
  
  # Construct a new instance.
  # Receives a hash of options to be set.
  #
  def initialize(options=nil)
    @diagnostics = Array.new
    @doc = Tidylib.create
    @errors = Array.new
    @errbuf = Tidybuf.new
    @outbuf = Tidybuf.new
    @options = Tidyopt.new(@doc)
    rc = Tidylib.set_error_buffer(@doc, @errbuf.struct)
    verify_severe(rc)
    unless options.nil?
      options.each { |name, value| Tidylib.opt_parse_value(@doc, name, value) }
    end
  end

  # Clean and Repair.
  #
  def clean(str)
    verify_doc
    rc = -1

    # Clean and repair the string.
    #
    rc = Tidylib.parse_string(@doc, str)                                               # Parse the input
    rc = Tidylib.clean_and_repair(@doc) if rc >= 0                                     # Tidy it up!
    rc = (Tidylib.opt_parse_value(@doc, :force_output, true) == 1 ? rc : -1) if rc > 1 # If error, force output
    rc = Tidylib.save_buffer(@doc, @outbuf.struct) if rc >= 0                          # Pretty Print
    verify_severe(rc)

    # Save and clear output/errors.
    #
    output = @outbuf.to_s
    @errors = @errbuf.to_a.collect { |e| Tidyerr.new(e) }
    @outbuf.free
    @errbuf.free
    
    # Save diagnostics.
    #
    rc = Tidylib.run_diagnostics(@doc)
    verify_severe(rc)
    @diagnostics = @errbuf.to_a
    @errbuf.free

    output
  end
  
  # Load a tidy config file.
  #
  def load_config(file)
    verify_doc
    rc = Tidylib.load_config(@doc, file)
    case rc
      when -1 then raise LoadError, "#{file} does not exist"
      when  1 then raise LoadError, "errors parsing #{file}"
    end
    rc
  end

  # Clear the tidy instance.
  #
  def release
    verify_doc
    Tidylib.release(@doc)
    @doc = nil
  end
  
  # Raise an error if the tidy document is invalid.
  #
  def verify_doc
    raise TypeError, 'Invalid Tidy document' unless @doc.class == DL::PtrData
  end

  # Raise severe error based on tidy status value.
  #
  def verify_severe(rc)
    raise "A severe error (#{rc}) occurred.\n" if rc < 0
  end

  protected :verify_doc, :verify_severe

end
