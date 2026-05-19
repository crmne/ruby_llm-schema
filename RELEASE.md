# Release process

1. Bump the version in `lib/ruby_llm/schema/version.rb`
2. Run `bundle install`
3. Commit the changes with a message like "Bump version to X.Y.Z"
4. Run `bundle exec rake release:prepare`
5. Push to `main`
6. GitHub Actions will publish the gem if the version is not already on RubyGems
7. GitHub Actions will create the `vX.Y.Z` tag and GitHub Release if they do not already exist
