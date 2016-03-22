module Kantox
  module Chronoscope
    # Dummy module to be used in production-like environments.
    module Generic
      COLOR_VIVID   = "\033[#{Kantox::Chronoscope.config.colors!.vivid || '01;38;05;226'}m".freeze
      COLOR_PALE    = "\033[#{Kantox::Chronoscope.config.colors!.pale || '01;38;05;178'}m".freeze
      COLOR_WARN    = "\033[#{Kantox::Chronoscope.config.colors!.warn || '01;38;05;173'}m".freeze
      LOGGER        = Kantox::Chronoscope.config.logger && Kernel.const_get(Kantox::Chronoscope.config.logger).new ||
                      Kernel.const_defined?(:Rails) && ::Rails.logger ||
                      Logger.new(STDOUT)

      BM_DELIMITER  = (Kantox::Chronoscope.config.i18n!.bm_delimiter || ' :: ').to_s.freeze
      ARROW         = (Kantox::Chronoscope.config.i18n!.arrow || '  ⇒  ').to_s.freeze
      METHOD_LABEL  = Kantox::Chronoscope.config.i18n!.name || 'method'.freeze
      TIMES_LABEL   = Kantox::Chronoscope.config.i18n!.times || 'times'.freeze
      AVERAGE_LABEL = Kantox::Chronoscope.config.i18n!.average || 'average'.freeze
      TOTAL_LABEL   = Kantox::Chronoscope.config.i18n!.total || 'total'.freeze

      COLOR_NONE    = "\033[0m".freeze
      DEFAULT_TAG   = 'N/A'.freeze
      LOGGER_TAG    = 'CHRONOS'.freeze

      @@chronoscope_data = {}
      @@★ = []

      # rubocop:disable Style/MethodName
      # rubocop:disable Style/OpMethod
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Style/SpecialGlobalVars

      def ⌚(arg = DEFAULT_TAG)
        return (@@chronoscope_data[arg.to_s] = nil) unless block_given? # pass no block to reset

        result = nil # needed for it to be defined in this scope
        @@chronoscope_data[arg.to_s] ||= { count: 0, total: 0, stack: @@★.dup }
        @@★.unshift arg.to_s
        begin
          (Benchmark.measure { result = yield }).tap do |bm|
            @@chronoscope_data[arg.to_s][:count] += 1
            @@chronoscope_data[arg.to_s][:total] += bm.real
            LOGGER.debug log_bm arg, bm
          end
          result
        rescue => e
          LOGGER.debug log_problem arg, e
          yield # re-try without any wrappers. If it will raise anyway— fine
        ensure
          @@★.shift
        end
      end

      # FIXME: total currently adds up all calls, including nested
      #        I am not sure if it is correct ot not, so leaving it for now
      def ⌛(cleanup: true, count: 18, log: true) # Yes, 18 is my fave number)
        return if @@chronoscope_data.empty?

        log_report(count).tap do |log_string|
          LOGGER.debug(log_string) if log
          puts '—' * 80
          puts @@chronoscope_data.inspect
          puts '—' * 80
          @@chronoscope_data.clear if cleanup
        end
      end

      def log_bm(arg, bm)
        [
          "  #{COLOR_PALE}[#{LOGGER_TAG}] #{arg}#{COLOR_NONE}",
          BM_DELIMITER,
          "#{COLOR_PALE}#{@@chronoscope_data[arg.to_s][:count]}#{COLOR_NONE}",
          BM_DELIMITER,
          "#{COLOR_VIVID}#{@@chronoscope_data[arg.to_s][:total].round(3)}#{COLOR_NONE}",
          bm.to_s
        ].join(' ')
      end

      def log_problem(arg, e)
        [
          "  #{COLOR_WARN}[#{LOGGER_TAG}] #{arg}#{COLOR_NONE} #{BM_DELIMITER} threw “#{COLOR_WARN}#{e.message}#{COLOR_NONE}”",
          e.backtrace.map { |s| "#{COLOR_WARN}#{s}#{COLOR_NONE}" }
        ].join("#{$/}⮩\t")
      end

      def log_report(count)
        count = @@chronoscope_data.size if count <= 0

        delim_label = [" ⇓⇓ [#{LOGGER_TAG}] ⇓⇓ ", " ⇑⇑ [#{LOGGER_TAG}] ⇑⇑ "].map do |label|
          delim = '—' * ((log_width - label.length) / 2)
          "#{COLOR_PALE}#{delim}#{label}#{delim}#{COLOR_NONE}"
        end

        method_len = [@@chronoscope_data.keys.max_by(&:length).length, 5].max + 2
        total = @@chronoscope_data.values.map { |v| v[:total] }.inject(:+).round(5)

        [
          '',
          delim_label.first,
          "#{METHOD_LABEL.rjust(method_len, ' ')}#{ARROW}#{TIMES_LABEL}#{BM_DELIMITER}#{AVERAGE_LABEL}#{BM_DELIMITER}#{TOTAL_LABEL}",
          (@@chronoscope_data.sort_by { |_, v| -v[:total] }.take(count).map do |what, bms|
            [
              "#{COLOR_PALE}#{what.rjust(method_len, ' ')}#{COLOR_NONE}",
              ARROW,
              "#{COLOR_VIVID}#{bms[:count].to_s.rjust(5, ' ')}#{COLOR_NONE}",
              BM_DELIMITER,
              "#{COLOR_VIVID}#{(bms[:total] / bms[:count]).round(5)}#{COLOR_NONE}",
              BM_DELIMITER,
              "#{COLOR_VIVID}#{bms[:total].round(5)}#{COLOR_NONE}"
            ].join
          end),
          '—' * log_width,
          "#{COLOR_VIVID}#{'total'.rjust(method_len, ' ')}#{COLOR_NONE}#{ARROW}#{' ' * TIMES_LABEL.length}#{COLOR_VIVID}#{total}#{COLOR_NONE}",
          delim_label.last
        ].flatten.join($/)
      end

      def log_width
        # rubocop:disable Style/RescueModifier
        $stdin.winsize.last - 10 rescue 80
        # rubocop:enable Style/RescueModifier
      end

      protected :log_problem, :log_bm, :log_report, :log_width
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
