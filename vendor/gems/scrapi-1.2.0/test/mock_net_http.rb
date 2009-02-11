require "net/http"

class Net::HTTP

  @@on_get = nil

  # Reset get method to default behavior.
  def self.reset_on_get
    @@on_get = nil
  end


  # :call-seq:
  #   on_get { |address, path, headers| ... => [response, body] }
  #
  # Specify alternative behavior for next execution of get method.
  # This change applies to all instances of Net::HTTP, so do not use
  # this method when running tests in parallel.
  #
  # The method takes a single block that accepts three arguments:
  # the address (host), path and headers (hash). It must return an
  # array with two values: the Net::HTTPResponse object and the
  # content of the response body.
  def self.on_get(&block)
    @@on_get = block
  end


  unless method_defined?(:mocked_request_get)
    alias :mocked_request_get :request_get

    def request_get(path, headers)
      # If we have prescribed behavior for the next search, execute it,
      # otherwise, go with the default.
      if @@on_get
        response, body = @@on_get.call(@address, path, headers)
        # Stuff the body into the response. No other way, since read_body
        # attempts to read from a socket and we're too lazy to stub a socket.
        response.instance_variable_set(:@mock_body, body.to_s)
        class << response
          def read_body()
            @mock_body
          end
        end
        response
      else
        mocked_request_get(path, headers)
      end
    end

  end

end

