module Kantox
  module Chronoscope
    # Dummy module to be used in production-like environments.
    module Dummy
      # rubocop:disable Style/MethodName
      # rubocop:disable Style/OpMethod
      def ⌚(*args)
        yield(*args) if block_given?
      end

      def ⌛(*)
        {}
      end
      # rubocop:enable Style/OpMethod
      # rubocop:enable Style/MethodName

      def inject(top = nil)
        (top || Object).send :prepend, Kantox::Chronoscope::Dummy
      end
      module_function :inject
    end
  end
end
