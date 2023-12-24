# frozen_string_literal: true

require 'active_model'

require 'deep_matching/deep_matcher'
require 'deep_matching/nested_expectation_parameters'

module DeepMatching
  # I tried writing this as an RSpec matcher, but couldn't easily make it
  # find all nested failures with aggregate_failures, rather than just the
  # first one
  def expect_deep_matching(obj, expected_obj, ignore_list: [], nested_expectation_parameters: nil,
                           failure_message_extra_context: '')
    nested_expectation_parameters ||= NestedExpectationParameters.new(
      nesting: [],
      ignore_list: ignore_list,
      evaluation_context: self,
      failure_message_extra_context: failure_message_extra_context
    )

    return true if deep_matches?(
      obj, expected_obj,
      nested_expectation_parameters: nested_expectation_parameters
    )

    failure_message = deep_matching_failure_message_for(
      obj,
      nested_expectation_parameters.nesting,
      nested_expectation_parameters.failure_message_extra_context
    )

    make_assertion_about!(obj, expected_obj, failure_message, nested_expectation_parameters.evaluation_context)
  end

  def deep_matches?(obj, expected_obj, nested_expectation_parameters:)
    DeepMatcher.new(
      obj: obj,
      expected_obj: expected_obj,
      nested_expectation_parameters: nested_expectation_parameters
    ).matches?
  end

  private

  def make_assertion_about!(obj, expected_obj, failure_message, evaluation_context)
    evaluation_context.instance_eval do
      case expected_obj
      when RSpec::Mocks::ArgumentMatchers::KindOf
        make_assertion_about_kind_of(obj, expected_obj, failure_message)
      when Regexp
        expect(obj).to match(expected_obj), failure_message.call(:match, expected_obj)
      else
        expect(obj).to eq(expected_obj), failure_message.call(:eq, expected_obj)
      end
    end
  end

  def make_assertion_about_kind_of(obj, expected, _failured_message)
    expected = expected.instance_eval { @klass }
    expect(obj).to be_a(expected), failure_message.call(:be_a, expected)
  end

  def deep_matching_failure_message_for(obj, nesting, failure_message_extra_context)
    lambda do |comparison, expected|
      nesting_message = nesting.length > 1 ? 'Expected nested hash key at' : 'Expected hash key at'
      [failure_message_extra_context.presence,
       "#{nesting_message} '#{nesting.join('.')}'",
       "to #{comparison}",
       "#{expected.inspect},",
       'but got',
       obj.inspect].compact.join("\n")
    end
  end
end
