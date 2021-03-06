module CabbageDoc
  class Action
    include Parser

    METHODS = %w(GET POST PUT DELETE).freeze
    METHODS_REGEXP = METHODS.join('|').freeze

    attr_reader :label, :name, :description, :path, :method, :parameters, :examples

    def initialize
      @parameters = []
      @examples = []
    end

    def parse(text)
      @method, @path = parse_method_and_path(text)
      return unless valid?

      @name = parse_name(text)
      @label = parse_label(text)
      @description = parse_description(text)

      @parameters, @examples = parse_parameters_and_examples(text)

      valid?
    end

    def valid?
      @method && @path
    end

    def param?(key)
      @parameters.any? { |parameter| parameter.name =~ /#{key}/ }
    end

    private

    # FIXME: get rid of this and optimize direct regex matches
    def text_to_lines(text)
      text.gsub(/\r\n?/, "\n").split(/\n/)[0..-2].map do |line|
        line.strip!
        line.slice!(0)
        line.strip!
        line if line.size > 0
      end.compact
    end

    def parse_parameters_and_examples(text)
      # FIXME: rewrite this to do a 'scan' with the right Regexp
      parameters = []
      examples = []

      lines = text_to_lines(text)

      lines.each do |line|
        if parameter = Parameter.parse(line)
          parameters << parameter
        elsif example = Example.parse(line)
          examples << example
        end
      end

      [parameters, examples]
    end

    def parse_method_and_path(text)
      m = text.match(/#\s*(#{METHODS_REGEXP}):\s*(.*?)$/)
      [m[1].strip.upcase, m[2].strip] if m
    end

    def parse_name(text)
      m = text.match(/def\s+(.*?)\s*#\s*#{MARKER}$/)
      m[1].strip if m
    end

    def parse_label(text)
      m = text.match(/#\s*Public:(.*?)$/)
      m[1].strip if m
    end

    def parse_description(text)
      m = text.match(/#\s*Description:(.*?)$/)
      m[1].strip if m
    end
  end
end
