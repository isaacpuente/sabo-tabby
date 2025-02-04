# frozen_string_literal: true

require "byebug"
require "pry-byebug"
require "json-schema-rspec"
require "dry/container/stub"

SPEC_ROOT = Pathname(__FILE__).dirname

require SPEC_ROOT.join("../system/sabo_tabby/container")

Dir[SPEC_ROOT.join("support/**/*.rb").to_s].sort.each(&method(:require))
Dir[SPEC_ROOT.join("shared/**/*.rb").to_s].sort.each(&method(:require))

SaboTabby::Container.enable_stubs!

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.include JSON::SchemaMatchers
  config.json_schemas[:jsonapi] = "spec/support/schemas/jsonapi"

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on a
    # real object. This is generally recommended, and will default to `true`
    # in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # These two settings work together to allow you to limit a spec run to
  # individual examples or groups you care about by tagging them with `:focus`
  # metadata. When nothing is tagged with `:focus`, all examples get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Allows RSpec to persist some state between runs in order to support the
  # `--only-failures` and `--next-failure` CLI options.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output, unless a formatter
    # has already been configured (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the end of the spec
  # run, to help surface which specs are running particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
end
