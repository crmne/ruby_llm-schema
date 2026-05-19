# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "conditional properties" do
  let(:schema_class) { Class.new(described_class) }

  def schema_output
    schema_class.new.to_json_schema[:schema]
  end

  describe "condition coercion" do
    it "coerces string to const" do
      schema_class.string :role
      schema_class.string :permissions, required: false

      schema_class.given role: "admin" do
        requires :permissions
      end

      expect(schema_output[:if][:properties]["role"]).to eq({const: "admin"})
    end

    it "coerces array to enum" do
      schema_class.string :status
      schema_class.string :reason, required: false

      schema_class.given status: %w[suspended banned] do
        requires :reason
      end

      expect(schema_output[:if][:properties]["status"]).to eq({enum: %w[suspended banned]})
    end

    it "coerces regexp to pattern" do
      schema_class.string :email
      schema_class.string :employee_id, required: false

      schema_class.given email: /@acme\.com$/ do
        requires :employee_id
      end

      expect(schema_output[:if][:properties]["email"]).to eq({pattern: "@acme\\.com$"})
    end

    it "passes hash through as raw schema" do
      schema_class.integer :age, required: false
      schema_class.boolean :parental_consent, required: false

      schema_class.given age: {maximum: 17} do
        requires :parental_consent
      end

      expect(schema_output[:if][:properties]["age"]).to eq({maximum: 17})
    end

    it "coerces integer to const" do
      schema_class.integer :level
      schema_class.string :badge, required: false

      schema_class.given level: 10 do
        requires :badge
      end

      expect(schema_output[:if][:properties]["level"]).to eq({const: 10})
    end

    it "coerces boolean to const" do
      schema_class.boolean :active
      schema_class.string :deactivation_reason, required: false

      schema_class.given active: false do
        requires :deactivation_reason
      end

      expect(schema_output[:if][:properties]["active"]).to eq({const: false})
    end
  end

  describe "multiple properties" do
    it "supports conditions on multiple properties" do
      schema_class.string :country
      schema_class.string :role
      schema_class.string :tax_id, required: false

      schema_class.given country: "US", role: "employee" do
        requires :tax_id
      end

      schema = schema_output

      expect(schema[:if][:properties]).to eq({
        "country" => {const: "US"},
        "role" => {const: "employee"}
      })
      expect(schema[:if][:required]).to contain_exactly("country", "role")
    end
  end

  describe "then schema" do
    it "supports requires with multiple fields" do
      schema_class.string :role
      schema_class.string :permissions, required: false
      schema_class.string :department, required: false

      schema_class.given role: "manager" do
        requires :permissions, :department
      end

      expect(schema_output[:then][:required]).to eq(%w[permissions department])
    end

    it "supports validates with type and string constraints" do
      schema_class.string :format
      schema_class.string :date, required: false

      schema_class.given format: "iso8601" do
        validates :date, type: :string, min_length: 10, pattern: "^\\d{4}-\\d{2}-\\d{2}"
      end

      expect(schema_output[:then][:properties]["date"]).to eq({
        type: "string",
        minLength: 10,
        pattern: "^\\d{4}-\\d{2}-\\d{2}"
      })
    end

    it "supports validates without explicit type" do
      schema_class.string :status
      schema_class.string :code, required: false

      schema_class.given status: "error" do
        validates :code, min_length: 3, max_length: 10
      end

      expect(schema_output[:then][:properties]["code"]).to eq({minLength: 3, maxLength: 10})
    end

    it "supports validates with numeric constraints" do
      schema_class.string :membership
      schema_class.number :discount, required: false

      schema_class.given membership: "premium" do
        validates :discount, type: :number, minimum: 10, maximum: 50
      end

      expect(schema_output[:then][:properties]["discount"]).to eq({type: "number", minimum: 10, maximum: 50})
    end

    it "supports validates with enum" do
      schema_class.string :country
      schema_class.string :state, required: false

      schema_class.given country: "US" do
        validates :state, enum: %w[CA NY TX]
      end

      expect(schema_output[:then][:properties]["state"]).to eq({enum: %w[CA NY TX]})
    end

    it "supports validates with not_value" do
      schema_class.string :status
      schema_class.string :notes, required: false

      schema_class.given status: "rejected" do
        requires :notes
        validates :notes, not_value: "N/A"
      end

      schema = schema_output

      expect(schema[:then][:required]).to eq(["notes"])
      expect(schema[:then][:properties]["notes"]).to eq({not: {const: "N/A"}})
    end

    it "supports validates with regexp pattern" do
      schema_class.string :country
      schema_class.string :zip_code, required: false

      schema_class.given country: "US" do
        validates :zip_code, pattern: /^\d{5}(-\d{4})?$/
      end

      expect(schema_output[:then][:properties]["zip_code"]).to eq({pattern: "^\\d{5}(-\\d{4})?$"})
    end
  end

  describe "otherwise (else)" do
    it "includes else when otherwise is used" do
      schema_class.boolean :domestic
      schema_class.string :state, required: false
      schema_class.string :country, required: false

      schema_class.given domestic: true do
        requires :state

        otherwise do
          requires :country
        end
      end

      schema = schema_output

      expect(schema[:then][:required]).to eq(["state"])
      expect(schema[:else][:required]).to eq(["country"])
    end

    it "omits else when otherwise is not used" do
      schema_class.string :role
      schema_class.string :permissions, required: false

      schema_class.given role: "admin" do
        requires :permissions
      end

      expect(schema_output).not_to have_key(:else)
    end

    it "supports validates in otherwise" do
      schema_class.string :membership
      schema_class.integer :max_items, required: false

      schema_class.given membership: "premium" do
        validates :max_items, type: :integer, minimum: 100

        otherwise do
          validates :max_items, type: :integer, maximum: 10
        end
      end

      schema = schema_output

      expect(schema[:then][:properties]["max_items"]).to eq({type: "integer", minimum: 100})
      expect(schema[:else][:properties]["max_items"]).to eq({type: "integer", maximum: 10})
    end
  end

  describe "JSON schema output" do
    it "includes single condition as if/then at top level" do
      schema_class.string :role
      schema_class.string :permissions, required: false

      schema_class.given role: "admin" do
        requires :permissions
      end

      schema = schema_output

      expect(schema[:if]).to eq({
        properties: {"role" => {const: "admin"}},
        required: ["role"]
      })
      expect(schema[:then]).to eq({required: ["permissions"]})
      expect(schema).not_to have_key(:allOf)
    end

    it "wraps multiple conditions in allOf" do
      schema_class.string :role
      schema_class.string :permissions, required: false
      schema_class.string :api_key, required: false

      schema_class.given role: "admin" do
        requires :permissions
      end

      schema_class.given role: "developer" do
        requires :api_key
      end

      schema = schema_output

      expect(schema).not_to have_key(:if)
      expect(schema[:allOf].length).to eq(2)
      expect(schema[:allOf][0][:if][:properties]["role"][:const]).to eq("admin")
      expect(schema[:allOf][1][:if][:properties]["role"][:const]).to eq("developer")
    end

    it "does not include conditions when none are defined" do
      schema_class.string :name

      schema = schema_output

      expect(schema).not_to have_key(:if)
      expect(schema).not_to have_key(:then)
      expect(schema).not_to have_key(:else)
      expect(schema).not_to have_key(:allOf)
    end

    it "propagates conditions through nested schema via of:" do
      address_schema = Class.new(described_class) do
        string :country, required: true
        string :state, required: false

        given country: "US" do
          requires :state
        end
      end

      parent_schema = Class.new(described_class) do
        string :name
        array :addresses, of: address_schema, required: false
      end

      items = parent_schema.new.to_json_schema[:schema][:properties][:addresses][:items]

      expect(items[:if][:properties]["country"]).to eq({const: "US"})
      expect(items[:then][:required]).to eq(["state"])
    end

    it "includes else in JSON schema output" do
      schema_class.boolean :domestic
      schema_class.string :state, required: false
      schema_class.string :country, required: false

      schema_class.given domestic: true do
        requires :state

        otherwise do
          requires :country
        end
      end

      schema = schema_output

      expect(schema[:then][:required]).to eq(["state"])
      expect(schema[:else][:required]).to eq(["country"])
    end
  end

  describe "dependent" do
    it "outputs dependentRequired when only requires are used" do
      schema_class.string :name
      schema_class.number :credit_card, required: false
      schema_class.string :billing_address, required: false

      schema_class.dependent :credit_card do
        requires :billing_address
      end

      schema = schema_output

      expect(schema[:dependentRequired]).to eq({"credit_card" => ["billing_address"]})
      expect(schema).not_to have_key(:dependentSchemas)
    end

    it "outputs dependentRequired with multiple required fields" do
      schema_class.number :credit_card, required: false
      schema_class.string :billing_address, required: false
      schema_class.string :cvv, required: false

      schema_class.dependent :credit_card do
        requires :billing_address, :cvv
      end

      expect(schema_output[:dependentRequired]).to eq({"credit_card" => %w[billing_address cvv]})
    end

    it "supports inline requires: with a single field" do
      schema_class.number :credit_card, required: false, requires: :billing_address
      schema_class.string :billing_address, required: false

      expect(schema_output[:dependentRequired]).to eq({"credit_card" => ["billing_address"]})
    end

    it "supports inline requires: with multiple fields" do
      schema_class.number :credit_card, required: false, requires: %i[billing_address cvv]
      schema_class.string :billing_address, required: false
      schema_class.string :cvv, required: false

      expect(schema_output[:dependentRequired]).to eq({"credit_card" => %w[billing_address cvv]})
    end

    it "supports inline requires: on different property types" do
      schema_class.string :email, requires: :name
      schema_class.string :name, required: false
      schema_class.boolean :active, required: false, requires: :activated_at
      schema_class.string :activated_at, required: false

      expect(schema_output[:dependentRequired]).to eq({
        "email" => ["name"],
        "active" => ["activated_at"]
      })
    end

    it "outputs dependentSchemas when validates are used" do
      schema_class.number :credit_card, required: false
      schema_class.string :billing_address, required: false

      schema_class.dependent :credit_card do
        requires :billing_address
        validates :billing_address, type: :string, min_length: 1
      end

      schema = schema_output

      expect(schema).not_to have_key(:dependentRequired)
      expect(schema[:dependentSchemas]).to eq({
        "credit_card" => {
          required: ["billing_address"],
          properties: {"billing_address" => {type: "string", minLength: 1}}
        }
      })
    end

    it "supports multiple dependencies" do
      schema_class.number :credit_card, required: false
      schema_class.string :billing_address, required: false
      schema_class.string :name, required: false
      schema_class.string :email, required: false

      schema_class.dependent :credit_card do
        requires :billing_address
      end

      schema_class.dependent :name do
        requires :email
      end

      expect(schema_output[:dependentRequired]).to eq({
        "credit_card" => ["billing_address"],
        "name" => ["email"]
      })
    end

    it "mixes dependentRequired and dependentSchemas" do
      schema_class.number :credit_card, required: false
      schema_class.string :billing_address, required: false
      schema_class.string :name, required: false
      schema_class.string :email, required: false

      schema_class.dependent :credit_card do
        requires :billing_address
        validates :billing_address, type: :string, min_length: 1
      end

      schema_class.dependent :name do
        requires :email
      end

      schema = schema_output

      expect(schema[:dependentRequired]).to eq({"name" => ["email"]})
      expect(schema[:dependentSchemas]).to eq({
        "credit_card" => {
          required: ["billing_address"],
          properties: {"billing_address" => {type: "string", minLength: 1}}
        }
      })
    end

    it "propagates through nested schema via of:" do
      payment_schema = Class.new(described_class) do
        number :credit_card, required: false
        string :billing_address, required: false

        dependent :credit_card do
          requires :billing_address
        end
      end

      order_schema = Class.new(described_class) do
        object :payment, of: payment_schema
      end

      payment = order_schema.new.to_json_schema[:schema][:properties][:payment]

      expect(payment[:dependentRequired]).to eq({"credit_card" => ["billing_address"]})
    end

    it "does not include dependencies when none are defined" do
      schema_class.string :name

      schema = schema_output

      expect(schema).not_to have_key(:dependentRequired)
      expect(schema).not_to have_key(:dependentSchemas)
    end
  end

  describe "error handling" do
    it "raises when no property conditions are provided" do
      expect {
        schema_class.given { requires :name }
      }.to raise_error(ArgumentError, /requires at least one property condition/)
    end
  end
end
