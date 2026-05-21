# frozen_string_literal: true

require_relative 'lib/ruby_llm/schema/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_llm-schema'
  spec.version       = RubyLLM::Schema::VERSION
  spec.authors       = ['Daniel Friis', 'Carmine Paolino']
  spec.email         = ['d@friis.me', 'carmine@paolino.me']

  spec.summary       = 'A simple Ruby DSL for creating JSON schemas.'
  spec.description   = 'A compact Ruby DSL for building standards-oriented JSON Schema documents from Ruby.'
  spec.homepage      = 'https://github.com/crmne/ruby_llm-schema#readme'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.3')

  source_uri = 'https://github.com/crmne/ruby_llm-schema'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = source_uri
  spec.metadata['changelog_uri'] = "#{source_uri}/releases"
  spec.metadata['bug_tracker_uri'] = "#{source_uri}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('lib/**/*') + ['README.md', 'LICENSE']
  spec.require_paths = ['lib']
end
