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

desc 'Run specs'
task test: :spec

desc 'Run RuboCop and specs'
task default: %i[rubocop spec]
