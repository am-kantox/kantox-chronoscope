require 'logger'
require 'benchmark'
require 'kungfuig'
require 'hashie/mash'

require "kantox/chronoscope/version"

module Kantox
  module Chronoscope
    module Generic; end
    module Dummy; end

    CHAIN_PREFIX = '⚑'.freeze

    DEFAULT_ENV = :development
    CONFIG_LOCATION = 'config/chronoscope.yml'.freeze

    include Kungfuig
    kungfuig(CONFIG_LOCATION) rescue nil # FIXME: report
    kungfuig(File.join(File.expand_path('..', __FILE__), CONFIG_LOCATION)) rescue nil # FIXME: report
    kungfuig(File.join(Rails.root, CONFIG_LOCATION)) rescue nil

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
      #  TODO: Permit monitoring of private methods
      # `methods` parameter accepts:
      #    none for all instance methods
      #    :method for explicit method
      def attach(klazz, *methods, cms: nil)
        klazz = Kernel.const_get(klazz) unless klazz.is_a?(Class)
        methods = klazz.instance_methods(false) if methods.empty?
        do_log = !option(ENV, 'options.silent')

        methods.each do |m|
          next if m.to_s =~ /\A#{CHAIN_PREFIX}/ # skip wrappers
          next if methods.include?("#{CHAIN_PREFIX}#{m}".to_sym) # skip already wrapped functions
          next if (klazz.instance_method(m).parameters.to_h[:block] rescue false) # FIXME: report

          receiver, arg_string = m.to_s.end_with?('=') ? ['self.', 'arg'] : [nil, '*args'] # to satisfy setter

          klazz.class_eval %Q|
            alias_method :'#{CHAIN_PREFIX}#{m}', :'#{m}'
            def #{m}(#{arg_string})
              ⌚('#{klazz}##{m}', #{do_log}) { #{receiver}#{CHAIN_PREFIX}#{m} #{arg_string} }
            end
          |
        end

        # class methods now
        return unless cms
        cms = [*cms]
        cms = klazz.methods(false) if cms.empty?
        cms.each do |m|
          next if m.to_s =~ /\A#{CHAIN_PREFIX}/ # skip wrappers
          next if methods.include?("#{CHAIN_PREFIX}#{m}".to_sym) # skip already wrapped functions
          next if (klazz.instance_method(m).parameters.to_h[:block] rescue false) # FIXME: report

          klazz.class_eval %Q|
            class << self
              alias_method :'#{CHAIN_PREFIX}#{m}', :'#{m}'
              def #{m}(*args)
                ⌚('#{klazz}::#{m}', #{do_log}) { #{klazz}.#{CHAIN_PREFIX}#{m} *args }
              end
            end
          |
        end

      rescue NameError
        Generic::LOGGER.debug [
          "  #{Generic::COLOR_WARN}[#{Generic::LOGGER_TAG}] ERROR#{Generic::COLOR_NONE} #{Generic::BM_DELIMITER} “#{Generic::COLOR_WARN}#{e.message}#{Generic::COLOR_NONE}”",
          e.backtrace.map { |s| "#{Generic::COLOR_WARN}#{s}#{Generic::COLOR_NONE}" }
        ].join("#{$/}⮩\t")
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    extend ClassMethods
  end
end
