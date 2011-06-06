require 'base64'

module RubyAMF
  class Envelope < RocketAMF::Envelope
    attr_accessor :mapping_scope

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

    def serialize class_mapper=nil
      cm = class_mapper || RubyAMF::ClassMapper.new
      cm.mapping_scope = mapping_scope if cm.respond_to?(:mapping_scope=)
      super cm
    end
  end
end