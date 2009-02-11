# Ruby wrapper for HTML Tidy Library Project (http://tidy.sf.net).
#
module Tidylib

  extend DL::Importable

  module_function
  
  # Load the library.
  #
  def load(path)
    begin
      dlload(path)
    rescue
      raise LoadError, "Unable to load #{path}"
    end
    extern "void *tidyCreate()"
    extern "void tidyBufFree(void*)"
    extern "int tidyCleanAndRepair(void*)"
    extern "int tidyLoadConfig(void*, char*)"
    extern "int tidyOptGetIdForName(char*)"
    extern "char tidyOptGetValue(void*, unsigned int)"
    extern "int tidyOptParseValue(void*, char*, char*)"
    extern "int tidyParseString(void*, char*)"
    extern "void tidyRelease(void*)"
    extern "char* tidyReleaseDate()"
    extern "int tidyRunDiagnostics(void*)"
    extern "int tidySaveBuffer(void*, void*)"
    extern "int tidySetErrorBuffer(void*, void*)"
  end
  
  # tidyBufFree
  #
  def buf_free(buf)
    tidyBufFree(buf)
  end
  
  # tidyCreate
  #
  def create
    tidyCreate
  end

  # tidyCleanAndRepair
  #
  def clean_and_repair(doc)
    tidyCleanAndRepair(doc)
  end
  
  # tidyLoadConfig
  #
  def load_config(doc, file)
    tidyLoadConfig(doc, file.to_s)
  end

  # tidyOptParseValue
  #
  def opt_parse_value(doc, name, value)
    tidyOptParseValue(doc, translate_name(name), value.to_s)
  end

  # tidyOptGetValue (returns true/false instead of 1/0)
  #
  def opt_get_value(doc, name)
    value = tidyOptGetValue(doc, tidyOptGetIdForName(translate_name(name)))
    Tidy.to_b(value)
  end

  # tidyParseString
  #
  def parse_string(doc, str)
    tidyParseString(doc, str.to_s)
  end
  
  # tidyRelease
  #
  def release(doc)
    tidyRelease(doc)
  end
  
  # tidyReleaseDate
  #
  def release_date
    tidyReleaseDate
  end
  
  # tidyRunDiagnostics
  #
  def run_diagnostics(doc)
    tidyRunDiagnostics(doc)
  end
  
  # tidySaveBuffer
  #
  def save_buffer(doc, buf)
    tidySaveBuffer(doc, buf)
  end
  
  # tidySetErrorBuffer
  #
  def set_error_buffer(doc, buf)
    tidySetErrorBuffer(doc, buf)
  end

  # Convert to string, replace underscores with dashes (:output_xml => 'output-xml').
  #
  def translate_name(name)
    name.to_s.gsub('_', '-')
  end

end
