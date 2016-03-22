require 'logger'
require 'benchmark'
require 'kungfuig'
require 'hashie/mash'

require "kantox/chronoscope/version"

module Kantox
  module Chronoscope
    module Generic; end
    module Dummy; end

    DEFAULT_ENV = :development
    CONFIG_LOCATION = 'config/chronoscope.yml'.freeze

    include Kungfuig
    config(File.join(File.expand_path('..', __FILE__), CONFIG_LOCATION)) rescue nil # FIXME: report
    config(CONFIG_LOCATION) rescue nil # FIXME: report

    ENV = const_defined?('Rails') && Rails.env || ENV['CHRONOSCOPE_ENV'] || DEFAULT_ENV

    require "kantox/chronoscope/dummy"
    require "kantox/chronoscope/generic"
    general_config = option(ENV, :general) || Hashie::Mash.new
    chronoscope = if general_config.enable
                    begin
                      Kernel.const_get(general_config.handler)
                    rescue NameError, TypeError
                      # FIXME: Log this error
                      Kantox::Chronoscope::Generic
                    end
                  else
                    Kantox::Chronoscope::Dummy
                  end
    chronoscope.inject(general_config.top)

    module ClassMethods
      # `methods` parameter accepts:
      #    none for all instance methods
      #    :method for explicit method
      def attach(klazz, *methods)
        klazz = Kernel.const_get(klazz) unless klazz.is_a?(Class)
        methods = klazz.instance_methods(false) if methods.empty?

        methods.each do |m|
          next if m.to_s =~ /\A⚑/ || methods.include?("⚑#{m}".to_sym)   # skip already wrapped functions
          next if klazz.instance_method(m).parameters.to_h[:block]      # FIXME: report

          klazz.class_eval %Q|
            alias_method '⚑#{m}', '#{m}'
            def #{m} *args
              ⌚('#{klazz}##{m}') { ⚑#{m}(*args) }
            end
          |
        end
      rescue NameError
        # FIXME: report
      end
    end
    extend ClassMethods
  end
end
