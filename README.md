# RubyLLM::Schema

[![Gem Version](https://badge.fury.io/rb/ruby_llm-schema.svg)](https://rubygems.org/gems/ruby_llm-schema)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/danielfriis/ruby_llm-schema/blob/main/LICENSE.txt)
[![CI](https://github.com/danielfriis/ruby_llm-schema/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/danielfriis/ruby_llm-schema/actions/workflows/ci.yml)

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API. Perfect for defining structured data schemas for LLM function calling or structured outputs.

## Use Cases

Structured output is a powerful tool for LLMs to generate consistent and predictable responses.

Some ideal use cases:

- Extracting *metadata, topics, and summary* from articles or blog posts
- Organizing unstructured feedback or reviews with *sentiment and summary*
- Defining structured *actions* from user messages or emails
- Extracting *entities and relationships* from documents

### Simple Example

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  number :age, description: "Age in years", minimum: 0, maximum: 120
  boolean :active, required: false

  object :address do
    string :street
    string :city
    string :country, required: false
  end

  array :tags, of: :string, description: "User tags"

  array :contacts do
    object do
      string :email, format: "email"
      string :phone, required: false
    end
  end

  any_of :status do
    string enum: ["active", "pending", "inactive"]
    null
  end
end

# Usage
schema = PersonSchema.new
puts schema.to_json
```

### Most common use case with RubyLLM

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  integer :age, description: "Person's age in years"
  string :city, required: false, description: "City where they live"
end

# Use it natively with RubyLLM
chat     = RubyLLM.chat
response = chat.with_schema(PersonSchema)
               .ask("Generate a person named Alice who is 30 years old and lives in New York")

# The response is automatically parsed from JSON
puts response.content # => {"name" => "Alice", "age" => 30}
puts response.content.class # => Hash
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_llm-schema'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ruby_llm-schema
```

## Usage

Three approaches for creating schemas:

### Class Inheritance

```ruby
class PersonSchema < RubyLLM::Schema
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false

  object :address do
    string :street
    string :city
  end

  array :tags, of: :string
end

schema = PersonSchema.new
puts schema.to_json
```

### Factory Method

```ruby
PersonSchema = RubyLLM::Schema.create do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false

  object :address do
    string :street
    string :city
  end

  array :tags, of: :string
end

schema = PersonSchema.new
puts schema.to_json
```

### Global Helper

```ruby
require 'ruby_llm/schema'
include RubyLLM::Helpers

person_schema = schema "PersonData", description: "A person object" do
  string :name, description: "Person's full name"
  number :age
  boolean :active, required: false

  object :address do
    string :street
    string :city
  end

  array :tags, of: :string
end

puts person_schema.to_json
```

## Schema Property Types

A schema is a collection of properties, which can be of different types. Each type has its own set of properties you can set.

All property types can (along with the required `name` key) be set with a `description` and a `required` flag (default is `true`).

```ruby
string :name, description: "Person's full name"
number :age, description: "Person's age", required: false
boolean :is_active, description: "Whether the person is active"
null :placeholder, description: "A placeholder property"
```

⚠️ Please consult the LLM provider documentation for any limitations or restrictions. For example, as of now, OpenAI requires all properties to be required. In that case, you can use the `any_of` method to make a property optional.

```ruby
any_of :name, description: "Person's full name" do
  string
  null
end
```

### Strings

String types support the following properties:

- `enum`: an array of allowed values (e.g. `enum: ["on", "off"]`)
- `pattern`: a regex pattern (e.g. `pattern: "\\d+"`)
- `format`: a format string (e.g. `format: "email"`)
- `min_length`: the minimum length of the string (e.g. `min_length: 3`)
- `max_length`: the maximum length of the string (e.g. `max_length: 10`)

Please consult the LLM provider documentation for the available formats and patterns.

```ruby
string :name, description: "Person's full name"
string :email, format: "email"
string :phone, pattern: "\\d+"
string :status, enum: ["on", "off"]
string :code, min_length: 3, max_length: 10
```

### Numbers

Number types support the following properties:

- `multiple_of`: a multiple of the number (e.g. `multiple_of: 0.01`)
- `minimum`: the minimum value of the number (e.g. `minimum: 0`)
- `maximum`: the maximum value of the number (e.g. `maximum: 100`)

```ruby
number :price, minimum: 0, maximum: 100
number :amount, multiple_of: 0.01
```

### Booleans

```ruby
boolean :is_active
```

Boolean types doesn't support any additional properties.

### Null

```ruby
null :placeholder
```

Null types doesn't support any additional properties.

### Arrays

An array is a list of items. You can set the type of the items in the array with the `of` option or by passing a block with the `object` method.

An array can have a `min_items` and `max_items` option to set the minimum and maximum number of items in the array.

```ruby
array :tags, of: :string              # Array of strings
array :scores, of: :number            # Array of numbers
array :items, min_items: 1, max_items: 10  # Array with size constraints

array :items do                       # Array of objects
  object do
    string :name
    number :price
  end
end
```

### Objects

Objects types expect a block with the properties of the object.

```ruby
object :user do
  string :name
  number :age
end

object :settings, description: "User preferences" do
  boolean :notifications
  string :theme, enum: ["light", "dark"]
end
```

### Union Types (anyOf)

Union types are a way to specify that a property can be one of several types.

```ruby
any_of :value do
  string
  number  
  null
end

any_of :identifier do
  string description: "Username"
  number description: "User ID"
end
```

### Schema Definitions and References

You can define sub-schemas and reference them in other schemas, or reference the root schema to generate recursive schemas.

```ruby
class MySchema < RubyLLM::Schema
  define :location do
    string :latitude
    string :longitude
  end

  # Using a reference in an array
  array :coordinates, of: :location

  # Using a reference in an object via the `reference` option
  object :home_location, reference: :location

  # Using a reference in an object via block
  object :user do
    reference :location
  end

  # Using a reference to the root schema
  object :ui_schema do
    string :element, enum: ["input", "button"]
    string :label
    object :sub_schema, reference: :root
  end
end
```

### Nested Schemas

You can embed existing schema classes directly within objects or arrays for reusable schema composition.

```ruby
class PersonSchema < RubyLLM::Schema
  string :name
  integer :age
end

class CompanySchema < RubyLLM::Schema
  # Using 'of' parameter
  object :ceo, of: PersonSchema
  array :employees, of: PersonSchema

  # Using Schema.new in block
  object :founder do
    PersonSchema.new
  end
end

schema = CompanySchema.new
schema.to_json_schema
# =>
# {
#    "name":"CompanySchema",
#    "description":"nil",
#    "schema":{
#       "type":"object",
#       "properties":{
#          "ceo":{
#             "type":"object",
#             "properties":{
#                "name":{
#                   "type":"string"
#                },
#                "age":{
#                   "type":"integer"
#                }
#             },
#             "required":[
#                :"name",
#                :"age"
#             ],
#             "additionalProperties":false
#          },
#          "employees":{
#             "type":"array",
#             "items":{
#                "type":"object",
#                "properties":{
#                   "name":{
#                      "type":"string"
#                   },
#                   "age":{
#                      "type":"integer"
#                   }
#                },
#                "required":[
#                   :"name",
#                   :"age"
#                ],
#                "additionalProperties":false
#             }
#          },
#          "founder":{
#             "type":"object",
#             "properties":{
#                "name":{
#                   "type":"string"
#                },
#                "age":{
#                   "type":"integer"
#                }
#             },
#             "required":[
#                :"name",
#                :"age"
#             ],
#             "additionalProperties":false
#          }
#       },
#       "required":[
#          :"ceo",
#          :"employees",
#          :"founder"
#       ],
#       "additionalProperties":false,
#       "strict":true
#    }
# }
```

### Dependencies

> [!NOTE]
> `dependentRequired` and `dependentSchemas` were introduced in JSON Schema Draft 2019-09. Not all LLM providers or validators support these keywords, check your provider's documentation for compatibility.

Use `requires:` inline or `dependent` block to express that the presence of one property requires other properties. This maps to JSON Schema's [`dependentRequired`](https://json-schema.org/understanding-json-schema/reference/conditionals#dependentRequired) and [`dependentSchemas`](https://json-schema.org/understanding-json-schema/reference/conditionals#dependentSchemas).

The simplest form uses inline `requires:` on the property declaration:

```ruby
class PaymentSchema < RubyLLM::Schema
  string :name
  number :credit_card, required: false, requires: %i[billing_address cvv]
  string :billing_address, required: false
  string :cvv, required: false
end

# Generates:
# {
#   "dependentRequired": {
#     "credit_card": ["billing_address", "cvv"]
#   }
# }
```

For a single dependency, use a symbol:

```ruby
number :credit_card, required: false, requires: :billing_address
```

Use `dependent` block when you need validations. When only `requires` is used, the output uses the simpler `dependentRequired`. When `validates` is also used, it upgrades to `dependentSchemas`:

```ruby
class PaymentSchema < RubyLLM::Schema
  string :name
  number :credit_card, required: false
  string :billing_address, required: false

  dependent :credit_card do
    requires :billing_address
    validates :billing_address, type: :string, min_length: 1
  end
end

# Generates:
# {
#   "dependentSchemas": {
#     "credit_card": {
#       "required": ["billing_address"],
#       "properties": {
#         "billing_address": { "type": "string", "minLength": 1 }
#       }
#     }
#   }
# }
```

### Conditionals

> [!NOTE]
> `if`/`then`/`else` was introduced in JSON Schema Draft 7. Not all LLM providers or validators support these keywords, check your provider's documentation for compatibility.

Use `given` to add [JSON Schema `if`/`then`/`else`](https://json-schema.org/understanding-json-schema/reference/conditionals#ifthenelse) rules. The condition values are automatically coerced:

| Ruby value               | JSON Schema                      |
|--------------------------|----------------------------------|
| `"string"`               | `{ "const": "string" }`          |
| `123` / `true` / `false` | `{ "const": 123 }`               |
| `["a", "b"]`             | `{ "enum": ["a", "b"] }`         |
| `/pattern/`              | `{ "pattern": "pattern" }`       |
| `{ minimum: 18 }`        | `{ "minimum": 18 }` (raw schema) |


Require a field when a property has a specific value:

```ruby
class OrderSchema < RubyLLM::Schema
  string :status, enum: ["pending", "shipped", "cancelled"]
  string :tracking_number, required: false
  string :cancellation_reason, required: false

  given status: "shipped" do
    requires :tracking_number
  end

  given status: "cancelled" do
    requires :cancellation_reason
  end
end
```

Multiple property conditions:

```ruby
class EmployeeSchema < RubyLLM::Schema
  string :country
  string :role
  string :tax_id, required: false

  given country: "US", role: "employee" do
    requires :tax_id
  end
end
```

Array conditions (enum), regexp conditions (pattern), and hash conditions (raw schema):

* Array → enum
* Regexp → pattern
* Hash → raw JSON Schema

```ruby
class AccountSchema < RubyLLM::Schema
  string :status
  string :reason, required: false
  string :email
  string :employee_id, required: false
  integer :age, required: false
  boolean :parental_consent, required: false

  given status: ["suspended", "banned"] do
    requires :reason
  end

  given email: /@acme\.com$/ do
    requires :employee_id
  end

  given age: { maximum: 17 } do
    requires :parental_consent
  end
end
```

Validate property values in the `then` branch:

```ruby
class EventSchema < RubyLLM::Schema
  string :format
  string :date, required: false

  given format: "iso8601" do
    requires :date
    validates :date, type: :string, min_length: 10, pattern: "^\\d{4}-\\d{2}-\\d{2}"
  end
end
```

`validates` supports: `type:`, `not_value:`, `min_length:`, `max_length:`, `pattern:` (`String` or `Regexp`), `enum:`, `const:`, `minimum:`, `maximum:`.

Use `otherwise` for an `else` branch:

```ruby
class ShippingSchema < RubyLLM::Schema
  boolean :domestic
  string :state, required: false
  string :country, required: false

  given domestic: true do
    requires :state

    otherwise do
      requires :country
    end
  end
end
```

Conditions propagate through nested schemas via `of:`:

```ruby
class AddressSchema < RubyLLM::Schema
  string :country
  string :state, required: false

  given country: "US" do
    requires :state
  end
end

class PersonSchema < RubyLLM::Schema
  string :name
  array :addresses, of: AddressSchema, required: false
end
```

The generated JSON Schema for addresses items will include the if/then rule.

## JSON Output

```ruby
schema = PersonSchema.new
schema.to_json_schema
# => {
#   name: "PersonSchema",
#   description: nil,
#   schema: {
#     type: "object",
#     properties: { ... },
#     required: [...],
#     additionalProperties: false,
#     strict: true
#   }
# }

puts schema.to_json  # Pretty JSON string
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
