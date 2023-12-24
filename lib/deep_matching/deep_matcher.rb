module DeepMatching
  class DeepMatcher
    include DeepMatching
    include ActiveModel::Model
    attr_accessor :nested_expectation_parameters, :obj, :expected_obj

    delegate :evaluation_context, :nesting, :ignore_list, to: :nested_expectation_parameters

    def matches?
      return true if ignore?

      case expected_obj
      when Array
        array_matches?
      when Hash
        hash_matches?
      else
        false
      end
    end

    def array_matches?
      within_example do |obj, expected_obj, nested_expectation_parameters|
        expected_obj.each_with_index do |expected_value, index|
          child_level_expect(obj, index, expected_value, nested_expectation_parameters)
        end
      end
    end

    def hash_matches?
      within_example do |obj, expected_obj, nested_expectation_parameters|
        expected_obj.each do |key, expected_value|
          child_level_expect(obj, key, expected_value, nested_expectation_parameters)
        end
      end
    end

    def to_indifferent(hash)
      hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access : hash
    end

    private

    def child_level_expect(obj, key, expected_value, nested_expectation_parameters)
      nested = nested_expectation_parameters.dup
      nested.nesting += [key]

      expect_deep_matching(obj&.try(:[], key), expected_value, nested_expectation_parameters: nested)
    end

    # this exists so we can make assertions within the example
    # but have the benefits of using a class
    def within_example
      # this is so we have access to the current self from within
      # the instance_eval
      this = self

      evaluation_context.instance_eval do
        obj = this.to_indifferent(this.obj)
        expected_obj = this.to_indifferent(this.expected_obj)

        yield obj, expected_obj, this.nested_expectation_parameters
      end
    end

    def ignore?
      nesting.in?(ignore_list)
    end
  end
end
