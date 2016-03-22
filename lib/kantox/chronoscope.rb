require 'logger'
require 'benchmark'
require 'kungfuig'
require 'hashie/mash'

require "kantox/chronoscope/version"

module Kantox
  module Chronoscope
    module Generic; end
    module Dummy; end

    CHAIN_PREFIX = '⚑'

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

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    module ClassMethods
      # `methods` parameter accepts:
      #    none for all instance methods
      #    :method for explicit method
      def attach(klazz, *methods)
        klazz = Kernel.const_get(klazz) unless klazz.is_a?(Class)
        methods = klazz.instance_methods(false) if methods.empty?

        methods.each do |m|
          next if m.to_s =~ /\A#{CHAIN_PREFIX}/ # skip wrappers
          next if m.to_s.end_with?('=')         # skip attr_writers # FIXME: WTF?????
          next if methods.include?("#{CHAIN_PREFIX}#{m}".to_sym) # skip already wrapped functions
          next if (klazz.instance_method(m).parameters.to_h[:block] rescue false) # FIXME: report

          klazz.class_eval %Q|
            alias_method :'#{CHAIN_PREFIX}#{m}', :'#{m}'
            def #{m}(*args)
              ⌚('#{klazz}##{m}') { #{CHAIN_PREFIX}#{m} *args }
            end
          |
        end
      rescue NameError
        # FIXME: report
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    extend ClassMethods
  end
end
