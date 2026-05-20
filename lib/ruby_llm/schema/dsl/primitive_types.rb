# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module PrimitiveTypes
        def string(name, description: nil, required: true, requires: nil, **options)
          add_property(name, string_schema(description: description, **options), required: required, requires: requires)
        end

        def number(name, description: nil, required: true, requires: nil, **options)
          add_property(name, number_schema(description: description, **options), required: required, requires: requires)
        end

        def integer(name, description: nil, required: true, requires: nil, **options)
          add_property(name, integer_schema(description: description, **options), required: required, requires: requires)
        end

        def boolean(name, description: nil, required: true, requires: nil, **options)
          add_property(name, boolean_schema(description: description, **options), required: required, requires: requires)
        end

        def null(name, description: nil, required: true, requires: nil, **options)
          add_property(name, null_schema(description: description, **options), required: required, requires: requires)
        end
      end
    end
  end
end
