# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "class inheritance approach" do
  include SchemaBuilders

  describe "schema attributes" do
    let(:base_schema) { build_schema_class { string :title } }

    it "derives schema names from constants, instances, and defaults" do
      stub_const("NamedSchema", build_schema_class)
      expect(NamedSchema.new.to_json_schema[:name]).to eq("NamedSchema")

      expect(base_schema.new.to_json_schema[:name]).to eq("Schema")
      expect(base_schema.new("CustomName").to_json_schema[:name]).to eq("CustomName")
    end

    it "honours description precedence" do
      schema_with_description = build_schema_class do
        description "Class-level description"
        string :title
      end

      anonymous_output = base_schema.new.to_json_schema
      expect(anonymous_output[:description]).to be_nil

      class_level_output = schema_with_description.new.to_json_schema
      expect(class_level_output[:description]).to eq("Class-level description")

      instance_override = schema_with_description.new("Test", description: "Instance description").to_json_schema
      expect(instance_override[:description]).to eq("Instance description")
    end

    it "controls additional properties and strictness" do
      default_output = base_schema.new.to_json_schema
      expect(default_output[:schema][:additionalProperties]).to eq(false)
      expect(default_output[:schema][:strict]).to eq(true)

      configured_schema = build_schema_class do
        additional_properties true
        strict false
        string :title
      end

      configured_output = configured_schema.new.to_json_schema
      expect(configured_output[:schema][:additionalProperties]).to eq(true)
      expect(configured_output[:schema][:strict]).to eq(false)
    end

    it "renders structured JSON schema" do
      configured_schema = build_schema_class do
        description "Test description"
        additional_properties false
        string :title
        integer :count, required: false
      end

      output = configured_schema.new("ConfiguredSchema").to_json_schema

      expect(output).to include(
        name: "ConfiguredSchema",
        description: "Test description",
        schema: hash_including(
          type: "object",
          properties: {
            title: {type: "string"},
            count: {type: "integer"}
          },
          required: [:title],
          additionalProperties: false,
          strict: true
        )
      )
    end

    it "does not duplicate required properties when schema classes are re-evaluated" do
      stub_const("RedefinedSchema", build_schema_class)

      2.times do
        RedefinedSchema.class_eval do
          string :name
        end
      end

      expect(RedefinedSchema.required_properties).to eq([:name])
      expect(RedefinedSchema.new.to_json_schema[:schema][:required]).to eq([:name])
    end

    it "updates required properties when a property is redefined as optional" do
      schema_class = build_schema_class

      schema_class.string :name
      schema_class.string :name, required: false

      expect(schema_class.required_properties).to eq([])
      expect(schema_class.new.to_json_schema[:schema][:required]).to eq([])
    end
  end

  describe "comprehensive scenario" do
    let(:schema_class) do
      build_schema_class do
        description "Comprehensive test schema"
        additional_properties true
        strict true

        string :name, description: "Name field"
        integer :count
        boolean :active, required: false

        object :config do
          string :setting
        end

        array :tags, of: :string

        any_of :status do
          string
          null
        end
      end
    end

    it "supports full-feature schemas" do
      json_output = schema_class.new("TestSchema").to_json_schema

      expect(json_output[:name]).to eq("TestSchema")
      expect(json_output[:schema][:additionalProperties]).to eq(true)
      expect(json_output[:schema][:strict]).to eq(true)
      expect(json_output[:schema][:properties].keys).to contain_exactly(
        :name, :count, :active, :config, :tags, :status
      )
      expect(json_output[:schema][:required]).to contain_exactly(:name, :count, :config, :tags, :status)
    end
  end
end
