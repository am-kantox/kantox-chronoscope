module Kantox
  module Chronoscope
    # Dummy module to be used in production-like environments.
    module Generic
      COLOR_NONE  = "\033[0m".freeze
      DEFAULT_TAG = 'N/A'.freeze
      LOGGER_TAG = 'CHRONOS'.freeze

      @@chronoscope_data = {}

      # rubocop:disable Style/MethodName
      # rubocop:disable Style/OpMethod
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Style/SpecialGlobalVars

      def ⌚(arg = DEFAULT_TAG)
        return (@@chronoscope_data[arg.to_s] = nil) unless block_given? # pass no block to reset

        result = nil # needed for it to be defined in this scope
        @@★ = arg.to_s
        @@chronoscope_data[arg.to_s] ||= { count: 0, total: 0 }
        (Benchmark.measure { result = yield }).tap do |bm|
          @@chronoscope_data[arg.to_s][:count] += 1
          @@chronoscope_data[arg.to_s][:total] += bm.real
          LOGGER.debug [
            "  #{COLOR_PALE}[#{LOGGER_TAG}] #{arg}#{COLOR_NONE}",
            '::',
            "#{COLOR_PALE}#{@@chronoscope_data[arg.to_s][:count]}#{COLOR_NONE}",
            '::',
            "#{COLOR_VIVID}#{@@chronoscope_data[arg.to_s][:total].round(3)}#{COLOR_NONE}",
            bm.to_s
          ].join(' ')
        end
        @@★ = nil
        result
      end

      # FIXME: total currently adds up all calls, including nested
      #        I am not sure if it is correct ot not, so leaving it for now
      def ⌛(cleanup: true, count: 18, log: true) # Yes, 18 is my fave number)
        return if @@chronoscope_data.empty?

        len = [@@chronoscope_data.keys.max_by(&:length).length, 5].max
        count = @@chronoscope_data.size if count <= 0
        delim = '—' * count

        [
          '',
          "#{COLOR_PALE}#{delim} ⇓⇓ [#{LOGGER_TAG}] ⇓⇓ #{delim}#{COLOR_NONE}",
          "#{'method'.rjust(len + 2, ' ')}  ⇒  times :: total time",
          (@@chronoscope_data.sort_by { |_, v| -v[:total] }.take(count).map do |what, bms|
            [
              "  #{COLOR_PALE}#{what.rjust(len, ' ')}#{COLOR_NONE}",
              ' ⇒ ',
              "#{COLOR_VIVID}#{bms[:count].to_s.rjust(5, ' ')}#{COLOR_NONE}",
              '::',
              "#{COLOR_VIVID}#{bms[:total].round(5)}#{COLOR_NONE}"
            ].join(' ')
          end),
          "#{COLOR_PALE}#{delim}#{'—' * (10 + LOGGER_TAG.length)}#{delim}#{COLOR_NONE}",
          "  #{COLOR_VIVID}#{'total'.rjust(len, ' ')}#{COLOR_NONE}  ⇒           #{COLOR_VIVID}#{@@chronoscope_data.values.map { |v| v[:total] }.inject(:+).round(5)}#{COLOR_NONE}",
          "#{COLOR_PALE}#{delim} ⇑⇑ [#{LOGGER_TAG}] ⇑⇑ #{delim}#{COLOR_NONE}"
        ].flatten.join($/).tap do |log_string|
          LOGGER.debug(log_string) if log
          @@chronoscope_data.clear if cleanup
        end
      end

      # rubocop:enable Style/SpecialGlobalVars
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Style/OpMethod
      # rubocop:enable Style/MethodName

      def inject(top = nil)
        top ||= Object
        top.send :prepend, Kantox::Chronoscope::Generic
      end
      module_function :inject
    end
  end
end
