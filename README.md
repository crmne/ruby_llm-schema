# RubyLLM::Schema

[![Gem Version](https://badge.fury.io/rb/ruby_llm-schema.svg)](https://rubygems.org/gems/ruby_llm-schema)
[![Gem Downloads](https://img.shields.io/gem/dt/ruby_llm-schema)](https://rubygems.org/gems/ruby_llm-schema)
[![codecov](https://codecov.io/gh/crmne/ruby_llm-schema/branch/main/graph/badge.svg)](https://codecov.io/gh/crmne/ruby_llm-schema)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

A Ruby DSL for creating JSON schemas with a clean, Rails-inspired API.

Originally created by [Daniel Friis](https://github.com/danielfriis).

## Use Cases

JSON Schema is useful wherever Ruby code needs to describe structured data in a portable format.

Some ideal use cases:

- Defining API request and response shapes
- Describing configuration files or structured payloads
- Sharing validation contracts across systems
- Generating structured output schemas for LLM workflows
- Defining structured parameters for RubyLLM tools

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

### RubyLLM structured output

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

### RubyLLM tools

RubyLLM tools can use schema classes for structured parameters. This is useful when the same argument shape is shared across tools or elsewhere in your app.

```ruby
class SearchParams < RubyLLM::Schema
  string :query, description: "Search query"
  integer :limit, required: false, description: "Maximum results"
end

class SearchDocuments < RubyLLM::Tool
  desc "Searches internal documents"
  params SearchParams

  def execute(query:, limit: 10)
    DocumentSearch.call(query:, limit:)
  end
end
```

For tool-specific parameters, define the schema inline with `params do ... end`.

```ruby
class Weather < RubyLLM::Tool
  desc "Gets current weather"

  params do
    string :city, description: "City name"
    string :units, enum: %w[celsius fahrenheit], required: false
  end

  def execute(city:, units: "celsius")
    WeatherAPI.current(city:, units:)
  end
end
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

Use `requires:` inline or `dependent` block to express that the presence of one property requires others. Maps to [`dependentRequired`](https://json-schema.org/understanding-json-schema/reference/conditionals#dependentRequired) (Draft 2019-09) and [`dependentSchemas`](https://json-schema.org/understanding-json-schema/reference/conditionals#dependentSchemas) (Draft 2019-09). Check your provider's documentation for compatibility.

```ruby
class PaymentSchema < RubyLLM::Schema
  string :name
  number :credit_card, required: false, requires: %i[billing_address cvv]
  string :billing_address, required: false
  string :cvv, required: false
end
```

Use a `dependent` block when you also need validations — this upgrades the output to `dependentSchemas`:

```ruby
dependent :credit_card do
  requires :billing_address
  validates :billing_address, type: :string, min_length: 1
end
```

### Conditionals

Use `given` to add [JSON Schema `if`/`then`/`else`](https://json-schema.org/understanding-json-schema/reference/conditionals#ifthenelse) (Draft 7) rules. Condition values are automatically coerced: strings → `const`, arrays → `enum`, regexps → `pattern`, hashes → raw schema.

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
    validates :cancellation_reason, type: :string, min_length: 1
  end
end
```

`validates` supports: `type:`, `not_value:`, `min_length:`, `max_length:`, `pattern:` (string or regexp), `enum:`, `const:`, `minimum:`, `maximum:`.

Use `otherwise` for an `else` branch:

```ruby
given domestic: true do
  requires :state

  otherwise do
    requires :country
  end
end
```

Conditions propagate through nested schemas via `of:`.

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
