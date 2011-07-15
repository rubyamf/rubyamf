module RubyAMF::Rails
  # Rack middleware that handles dispatching AMF calls to the appropriate controller
  # and action.
  class RequestProcessor
    def initialize app
      @app = app
    end

    # Processes the AMF request and forwards the method calls to the corresponding
    # rails controllers. No middleware beyond the request processor will receive
    # anything if the request is a handleable AMF request.
    def call env
      return @app.call(env) unless env['rubyamf.response']

      # Handle each method call
      req = env['rubyamf.request']
      res = env['rubyamf.response']
      res.each_method_call req do |method, args|
        handle_method method, args, env
      end
    end

    # Actually dispatch a fake request to the appropriate controller and extract
    # the response for serialization
    def handle_method method, args, env
      # Parse method and load service
      path = method.split('.')
      method_name = path.pop
      controller_name = path.pop
      controller = get_service controller_name, method_name

      # Setup request and controller
      new_env = env.dup
      new_env['HTTP_ACCEPT'] = RubyAMF::MIME_TYPE # Force amf response only
      if defined? ActionDispatch::Request then
        # rails 3.1
        req = ActionDispatch::Request.new(new_env)
      else
        # older rails
        req = ActionController::Request.new(new_env)
      end
      con = controller.new

      # Populate with AMF data
      amf_req = env['rubyamf.request']
      params_hash = amf_req.params_hash(controller.name, method_name, args)
      req.params.merge!(params_hash) if RubyAMF.configuration.populate_params_hash
      con.instance_variable_set("@is_amf", true)
      con.instance_variable_set("@rubyamf_params", params_hash)
      con.instance_variable_set("@credentials", amf_req.credentials)

      # Dispatch the request to the controller
      rails_version = ::Rails::VERSION::MAJOR
      if rails_version == 3
        res = con.dispatch(method_name, req)
      else # Rails 2
        req.params['controller'] = controller.controller_name
        req.params['action'] = method_name
        con.process(req, ActionController::Response.new)
      end

      # Copy mapping scope over to response so it can be used when serialized
      env['rubyamf.response'].mapping_scope = con.send(:mapping_scope)

      return con.send(:amf_response)
    end

    # Validate the controller and method name and return the controller class
    def get_service controller_name, method_name
      # Check controller and validate against hacking attempts
      begin
        controller_name += "Controller" unless controller_name =~ /^.+Controller$/
        controller = controller_name.constantize
        raise "not controller" unless controller.respond_to?(:controller_name) && controller.respond_to?(:action_methods)
      rescue Exception => e
        raise "Service #{controller_name} does not exist"
      end

      # Check action
      unless controller.action_methods.include?(method_name)
        raise "Service #{controller_name} does not respond to #{method_name}"
      end

      return controller
    end
  end
end
