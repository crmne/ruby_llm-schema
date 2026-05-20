# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module Conditionals
        def conditions
          @conditions ||= []
        end

        def dependencies
          @dependencies ||= {}
        end

        def dependent(property, &block)
          builder = ConditionalBuilder.new
          builder.instance_eval(&block)

          dependencies[property.to_s] = builder
        end

        def given(**properties, &block)
          raise ArgumentError, "given requires at least one property condition" if properties.empty?

          if_schema = {
            properties: properties.transform_keys(&:to_s).transform_values { |v| coerce_condition(v) },
            required: properties.keys.map(&:to_s)
          }

          then_builder = ConditionalBuilder.new
          else_builder = ConditionalBuilder.new

          context = ConditionalContext.new(then_builder, else_builder)
          context.instance_eval(&block)

          condition = {if: if_schema, then: then_builder.to_schema}
          condition[:else] = else_builder.to_schema unless else_builder.empty?

          conditions << condition
        end

        private

        def merge_conditions(schema, schema_class)
          if schema_class.respond_to?(:conditions) && schema_class.conditions.any?
            if schema_class.conditions.length == 1
              schema.merge!(schema_class.conditions.first)
            else
              schema[:allOf] = schema_class.conditions
            end
          end

          if schema_class.respond_to?(:dependencies) && schema_class.dependencies.any?
            dependent_required = {}
            dependent_schemas = {}

            schema_class.dependencies.each do |property, builder|
              if builder.validations_empty?
                dependent_required[property] = builder.required_fields
              else
                dependent_schemas[property] = builder.to_schema
              end
            end

            schema[:dependentRequired] = dependent_required if dependent_required.any?
            schema[:dependentSchemas] = dependent_schemas if dependent_schemas.any?
          end

          schema
        end

        def coerce_condition(value)
          case value
          when Array then {enum: value}
          when Regexp then {pattern: value.source}
          when Hash then value
          else {const: value}
          end
        end
      end

      class ConditionalContext
        def initialize(then_builder, else_builder)
          @then_builder = then_builder
          @else_builder = else_builder
        end

        def requires(*fields)
          @then_builder.requires(*fields)
        end

        def validates(field, **options)
          @then_builder.validates(field, **options)
        end

        def otherwise(&block)
          @else_builder.instance_eval(&block)
        end
      end

      class ConditionalBuilder
        def requires(*fields)
          required.concat(fields.map(&:to_s))
        end

        VALIDATES_KEY_MAP = {
          type: :type,
          const: :const,
          enum: :enum,
          not_value: :not,
          min_length: :minLength,
          max_length: :maxLength,
          pattern: :pattern,
          minimum: :minimum,
          maximum: :maximum
        }.freeze

        def validates(field, **options)
          constraints = {}

          options.each do |key, value|
            schema_key = VALIDATES_KEY_MAP[key]
            raise ArgumentError, "unknown validates option: #{key.inspect}" unless schema_key

            case key
            when :type then constraints[:type] = value.to_s
            when :not_value then constraints[:not] = {const: value}
            when :pattern then constraints[:pattern] = value.is_a?(Regexp) ? value.source : value
            else constraints[schema_key] = value
            end
          end

          validations[field.to_s] = constraints
        end

        def to_schema
          schema = {}

          schema[:required] = required if required.any?
          schema[:properties] = validations if validations.any?

          schema
        end

        def empty?
          required.empty? && validations.empty?
        end

        def required_fields
          required.dup
        end

        def validations_empty?
          validations.empty?
        end

        private

        def required
          @required ||= []
        end

        def validations
          @validations ||= {}
        end
      end
    end
  end
end
