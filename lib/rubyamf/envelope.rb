require 'base64'

module RubyAMF
  class Envelope < RocketAMF::Envelope
    def credentials
      # Old style setHeader('Credentials', CREDENTIALS_HASH)
      if @headers['Credentials']
        h = @headers['Credentials']
        return {:username => h.data[:userid], :password => h.data[:password]}
      end

      # New style DSRemoteCredentials
      messages.each do |m|
        if m.data.is_a?(RocketAMF::Values::RemotingMessage)
          if m.data.headers && m.data.headers[:DSRemoteCredentials]
            username,password = Base64.decode64(m.data.headers[:DSRemoteCredentials]).split(':')
            return {:username => username, :password => password}
          end
        end
      end

      # Failure case sends empty credentials, because rubyamf_plugin does it
      {:username => nil, :password => nil}
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
  end
end