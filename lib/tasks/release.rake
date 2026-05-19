# frozen_string_literal: true

namespace :release do
  desc 'Prepare for release'
  task :prepare do
    sh 'overcommit --run'
  end
end
