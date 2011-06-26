require 'base64'

module RubyAMF
  # Adds several important features to RocketAMF::Envelope. None of these features
  # are dependent on Rails, and as such can be used by any Rack compliant framework.
  # Features are credentials support, easy parameter mapping based on configured
  # parameter mappings, mapping scope support for serialization, and error handling
  # for method dispatch using <tt>each_method_call</tt>.
  class Envelope < RocketAMF::Envelope
    attr_accessor :mapping_scope

    # Finds and returns credentials set on the request as a hash with keys
    # <tt>username</tt> and <tt>password</tt>, with the type dependent on the
    # <tt>hash_key_access</tt> setting. <tt>setHeader('Credentials')</tt>
    # credentials are used first, followed by new-style <tt>DSRemoteCredentials</tt>.
    # If no credentials are found, a hash is returned with a username and password
    # of <tt>nil</tt>.
    def credentials
      ds_cred_key = RubyAMF.configuration.translate_case ? "ds_remote_credentials" : "DSRemoteCredentials"
      if RubyAMF.configuration.hash_key_access == :symbol
        userid_key = :userid
        username_key = :username
        password_key = :password
        ds_cred_key = ds_cred_key.to_sym
      else
        userid_key = "userid"
        username_key = "username"
        password_key = "password"
      end

      # Old style setHeader('Credentials', CREDENTIALS_HASH)
      if @headers['Credentials']
        h = @headers['Credentials']
        return {username_key => h.data[userid_key], password_key => h.data[password_key]}
      end

      # New style DSRemoteCredentials
      messages.each do |m|
        if m.data.is_a?(RocketAMF::Values::RemotingMessage)
          if m.data.headers && m.data.headers[ds_cred_key]
            username,password = Base64.decode64(m.data.headers[ds_cred_key]).split(':')
            return {username_key => username, password_key => password}
          end
        end
      end

      # Failure case sends empty credentials, because rubyamf_plugin does it
      {username_key => nil, password_key => nil}
    end

    # Given a controller, action, and the flash arguments array, returns a hash
    # containing the arguments indexed by number as well as named key if a named
    # mapping has been configured. Returned hash respects <tt>hash_key_access</tt>
    # setting for named keys.
    #
    # Example:
    #
    #   RubyAMF.configuration.map_params "c", "a", ["param1", "param2"]
    #   params = envelope.params_hash "c", "a", ["asdf", "fdsa"]
    #   params.should == {:param1 => "asdf", :param2 => "fdsa", 0 => "asdf", 1 => "fdsa"}
    def params_hash controller, action, arguments
      conf = RubyAMF.configuration
      mapped = {}
      mapping = conf.param_mappings[controller+"#"+action]
      arguments.each_with_index do |arg, i|
        mapped[i] = arg
        if mapping && mapping[i]
          mapping_key = conf.hash_key_access == :symbol ? mapping[i].to_sym : mapping[i].to_s
          mapped[mapping_key] = arg
        end
      end
      mapped
    end

    # Extends default RocketAMF implementation to log caught exceptions and
    # translate them into a RocketAMF::Values::ErrorMessage for return to flash
    # after removing the backtrace (for safety).
    def dispatch_call p
      begin
        ret = p[:block].call(p[:method], p[:args])
        raise ret if ret.is_a?(Exception) # If they return FaultObject like you could in rubyamf_plugin
        ret
      rescue Exception => e
        # Log exception
        RubyAMF.logger.log_error(e)

        # Clear backtrace so that RocketAMF doesn't send back the full backtrace
        e.set_backtrace([])

        # Create ErrorMessage object using the source message as the base
        RocketAMF::Values::ErrorMessage.new(p[:source], e)
      end
    end

    def serialize class_mapper=nil #:nodoc:
      # Create a ClassMapper and set the mapping scope to pass to super implementation.
      cm = class_mapper || RubyAMF::ClassMapper.new
      cm.mapping_scope = mapping_scope if cm.respond_to?(:mapping_scope=)
      super cm
    end
  end
end