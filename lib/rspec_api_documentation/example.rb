module RspecApiDocumentation
  class Example
    attr_reader :example, :configuration

    def initialize(example, configuration)
      @example = example
      @configuration = configuration
    end

    def method_missing(method_sym, *args, &block)
      if example.metadata.has_key?(method_sym)
        example.metadata[method_sym]
      else
        example.send(method_sym, *args, &block)
      end
    end

    def respond_to?(method_sym, include_private = false)
      super || example.metadata.has_key?(method_sym) || example.respond_to?(method_sym, include_private)
    end

    def http_method
      metadata[:method].to_s.upcase
    end

    def should_document?
      return false if pending? || !metadata[:resource_name] || !metadata[:document]
      return false if (Array(metadata[:document]) & Array(configuration.exclusion_filter)).length > 0
      return true if (Array(metadata[:document]) & Array(configuration.filter)).length > 0
      return true if configuration.filter == :all
    end

    def public?
      metadata[:public]
    end

    def has_parameters?
      respond_to?(:parameters) && parameters.present?
    end

    def has_attributes?
      respond_to?(:attributes) && attributes.present?
    end

    def has_response_fields?
      respond_to?(:response_fields) && response_fields.present?
    end

    def resource_explanation
      metadata[:resource_explanation] || nil
    end

    def explanation
      metadata[:explanation] || nil
    end

    def requests
      filter_headers(metadata[:requests]) || []
    end

    def clean_resource_name
      clean_name(resource_name.downcase)
    end

    def clean_description
      clean_name(description.downcase).gsub(Pathname::SEPARATOR_PAT, '_')
    end

    private

    CONTROL_CHARACTERS = /[\s#&?:.]+/
    def clean_name(name)
      name.gsub(CONTROL_CHARACTERS, '_').gsub(/[-_]{2,}/, '_')
    end

    def filter_headers(requests)
      return if requests.nil?

      requests = remap_headers(requests, :request_headers,
                               configuration.request_headers_to_include,
                               configuration.request_headers_to_exclude)

      requests = remap_headers(requests, :response_headers,
                               configuration.response_headers_to_include,
                               configuration.response_headers_to_exclude)
      requests
    end

    def remap_headers(requests, key, headers_to_include, headers_to_exclude)
      return requests unless headers_to_include || headers_to_exclude

      requests.each do |request_hash|
        next unless request_hash.key?(key)
        request_hash[key].delete_if do |key, _|
          if headers_to_include
            !headers_to_include.map(&:downcase).include?(key.downcase)
          elsif headers_to_exclude
            headers_to_exclude.map(&:downcase).include?(key.downcase)
          end
        end
      end
    end
  end
end
