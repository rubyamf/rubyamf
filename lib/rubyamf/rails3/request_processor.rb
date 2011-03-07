require 'active_support/dependencies'

module RubyAMF
  module Rails3
    class RequestProcessor < RubyAMF::RequestProcessor
      def handle_method method, args, env
        # Parse method and load service
        path = method.split('.')
        method_name = path.pop
        controller_name = path.pop
        controller = get_service controller_name, method_name

        # Create rack request
        new_env = env.dup
        new_env['HTTP_ACCEPT'] = RubyAMF::MIME_TYPE # Force amf response
        req = ActionDispatch::Request.new(new_env)

        # Run it
        con = controller.new
        res = con.dispatch(method_name, req)
        return con.amf_response
      end

      def get_service controller_name, method_name
        # Check controller and validate against hacking attempts
        begin
          controller_name += "Controller" unless controller_name =~ /^[A-Za-z:]+Controller$/
          controller = ActiveSupport::Dependencies.ref(controller_name).get
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
end