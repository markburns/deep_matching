require 'active_support/all'

module DeepMatching
  class DeepMatcher
    include DeepMatching
    include ActiveModel::Model
    attr_accessor :nested_expectation_parameters, :actual_object, :expected_object

    delegate :evaluation_context, :nesting, :ignore_list, to: :nested_expectation_parameters

    def matches?
      return true if ignore?

      case expected_object
      when Array
        array_matches?
      when Hash
        hash_matches?
      else
        false
      end
    end

    def array_matches?
      within_example do |actual_object, expected_object, nested_expectation_parameters|
        expected_object.each_with_index do |expected_value, index|
          child_level_expect(actual_object, index, expected_value, nested_expectation_parameters)
        end
      end
    end

    def hash_matches?
      within_example do |actual_object, expected_object, nested_expectation_parameters|
        expected_object.each do |key, expected_value|
          child_level_expect(actual_object, key, expected_value, nested_expectation_parameters)
        end
      end
    end

    def to_indifferent(hash)
      hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access : hash
    end

    private

    def child_level_expect(actual_object, key, expected_value, nested_expectation_parameters)
      nested = nested_expectation_parameters.dup
      nested.nesting += [key]

      expect_deep_matching(actual_object&.try(:[], key), expected_value, nested_expectation_parameters: nested)
    end

    # this exists so we can make assertions within the example
    # but have the benefits of using a class
    def within_example
      # this is so we have access to the current self from within
      # the instance_eval
      this = self

      evaluation_context.instance_eval do
        actual_object = this.to_indifferent(this.actual_object)
        expected_object = this.to_indifferent(this.expected_object)

        yield actual_object, expected_object, this.nested_expectation_parameters
      end
    end

    def ignore?
      nesting.in?(ignore_list)
    end
  end
end
