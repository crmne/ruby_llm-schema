# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# Load custom tasks
Dir.glob('lib/tasks/**/*.rake').each { |r| load r }

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

FLAY_FILES = FileList['lib/ruby_llm/**/*.rb'].to_a.freeze

desc 'Run specs'
task test: :spec

desc 'Run Flay duplication analysis'
task :flay do
  sh "bundle exec flay --mass 70 #{FLAY_FILES.join(' ')}"
end

desc 'Run RuboCop and specs'
task default: %i[rubocop flay spec]
