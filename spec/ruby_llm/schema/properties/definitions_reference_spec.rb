# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "definitions and references" do
  let(:schema_class) { Class.new(described_class) }

  it "supports defining and referencing reusable schemas" do
    schema_class.define :address do
      string :street
      string :city
    end

    schema_class.object :user do
      string :name
      array :addresses, of: :address
    end

    ref_hash = schema_class.reference(:address)
    expect(ref_hash).to eq({"$ref" => "#/$defs/address"})

    instance = schema_class.new
    json_output = instance.to_json_schema

    expect(json_output[:schema]["$defs"][:address]).to include(
      type: "object",
      properties: {
        street: {type: "string"},
        city: {type: "string"}
      },
      required: %i[street city]
    )

    user_props = json_output[:schema][:properties][:user][:properties]
    expect(user_props[:addresses][:items]).to eq({"$ref" => "#/$defs/address"})
  end

  it "supports reference to the root schema" do
    schema_class.string :element_type, enum: %w[input button]
    schema_class.string :label
    schema_class.object :sub_schema, of: :root

    instance = schema_class.new
    json_output = instance.to_json_schema

    expect(json_output[:schema][:properties][:sub_schema]).to eq({"$ref" => "#"})
  end

  it "supports reference to a defined schema by block" do
    schema_class.define :address do
      string :street
      string :city
    end

    schema_class.object :user do
      string :name
      object :address do
        reference :address
      end
    end

    instance = schema_class.new
    json_output = instance.to_json_schema

    expect(json_output[:schema][:properties][:user][:properties][:address]).to eq({"$ref" => "#/$defs/address"})
    expect(json_output[:schema]["$defs"][:address]).to eq({
      type: "object",
      properties: {
        street: {type: "string"},
        city: {type: "string"}
      },
      required: %i[street city],
      additionalProperties: false
    })
  end

  it "supports reference to a defined schema by of option" do
    schema_class.define :address do
      string :street
      string :city
    end

    schema_class.object :user do
      string :name
      object :address, of: :address
    end

    instance = schema_class.new
    json_output = instance.to_json_schema

    expect(json_output[:schema][:properties][:user][:properties][:address]).to eq({"$ref" => "#/$defs/address"})
    expect(json_output[:schema]["$defs"][:address]).to eq({
      type: "object",
      properties: {
        street: {type: "string"},
        city: {type: "string"}
      },
      required: %i[street city],
      additionalProperties: false
    })
  end

  it "supports object with symbol reference" do
    schema_class.define :address do
      string :street
      string :city
    end

    schema_class.object :headquarters, of: :address

    properties = schema_class.properties
    expect(properties[:headquarters]).to eq({"$ref" => "#/$defs/address"})
  end

  it "includes given conditions in $defs" do
    schema_class.define :address do
      string :country
      string :state, required: false

      given country: "US" do
        requires :state
      end
    end

    schema_class.object :address, of: :address

    defs = schema_class.new.to_json_schema[:schema]["$defs"][:address]

    expect(defs[:if]).to eq({
      properties: {"country" => {const: "US"}},
      required: ["country"]
    })
    expect(defs[:then]).to eq({required: ["state"]})
  end

  it "includes dependent in $defs" do
    schema_class.define :payment do
      number :credit_card, required: false
      string :billing_address, required: false

      dependent :credit_card do
        requires :billing_address
      end
    end

    schema_class.object :payment, of: :payment

    defs = schema_class.new.to_json_schema[:schema]["$defs"][:payment]

    expect(defs[:dependentRequired]).to eq({"credit_card" => ["billing_address"]})
  end

  it "includes inline requires: in $defs" do
    schema_class.define :payment do
      number :credit_card, required: false, requires: :billing_address
      string :billing_address, required: false
    end

    schema_class.object :payment, of: :payment

    defs = schema_class.new.to_json_schema[:schema]["$defs"][:payment]

    expect(defs[:dependentRequired]).to eq({"credit_card" => ["billing_address"]})
  end

  it "shows deprecation warning if using reference option" do
    schema_class.define :address do
      string :street
      string :city
    end

    expect do
      schema_class.object :user do
        string :name
        object :address, reference: :address
      end
    end.to output(/DEPRECATION.*reference/).to_stderr
  end
end
