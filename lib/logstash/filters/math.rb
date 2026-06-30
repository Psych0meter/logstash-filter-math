# frozen_string_literal: true
# encoding: UTF-8

require "logstash/namespace"
require "logstash/filters/base"

require_relative "event_register_context"
require_relative "math_functions"
require_relative "math_calculation_elements"

module LogStash
  module Filters
    class Math < LogStash::Filters::Base
      config_name "math"

      # List of calculations to perform
      # Binary: [op, left, right, target]
      # Unary:  [op, operand, target]
      config :calculate, :validate => :array, :required => true

      # Tags to add to an event if a calculation raises an unexpected runtime error
      # (e.g. a non-integer operand passed to `round`). The calculation is skipped
      # for that one entry and processing continues with the remaining calculations
      # rather than crashing the pipeline.
      config :tag_on_failure, :validate => :array, :default => ["_mathexception"]

      public

      def register
        functions = {}

        # Add standard math functions
        [
          [MathFunctions::Add.new, '+', 'add', 'plus'],
          [MathFunctions::Subtract.new, '-', 'sub', 'subtract'],
          [MathFunctions::Multiply.new, '*', 'mpx', 'times', 'multiply'],
          [MathFunctions::Round.new, 'round'],
          [MathFunctions::Power.new, '**', '^', 'to the power of'],
          [MathFunctions::Divide.new, '/', 'div', 'divide'],
          [MathFunctions::Modulo.new, 'mod', 'modulo'],
          [MathFunctions::FloatDivide.new, 'fdiv', 'float divide'],
          [MathFunctions::Abs.new, 'abs'],
          [MathFunctions::Negate.new, 'neg', 'negate'],
          [MathFunctions::PercentChange.new, 'percent_change']
        ].each do |list|
          func = list.shift
          list.each { |key| functions[key] = func }
        end

        # Add conversions
        MathFunctions.default_conversions.each do |key, conv|
          functions[key] = conv
        end

        @calculate_copy = []
        all_function_keys = functions.keys

        calculate.each do |calc|
          unless calc.is_a?(Array) && [3, 4].include?(calc.size)
            raise LogStash::ConfigurationError,
              "Invalid calculation size: expected 3 (unary) or 4 (binary), got #{calc.size}. You specified: #{calc}"
          end

          function_key = calc[0]
          unless all_function_keys.include?(function_key)
            raise LogStash::ConfigurationError,
              "Invalid function key '#{function_key}'. Must be one of: #{all_function_keys.join(', ')}"
          end

          function = functions[function_key]

          if calc.size == 4
            # binary
            operand1, operand2, target = calc[1], calc[2], calc[3]
            left_element  = MathCalculationElements.build(operand1, 1)
            right_element = MathCalculationElements.build(operand2, 2)
          else
            # unary
            operand1, target = calc[1], calc[2]
            left_element  = MathCalculationElements.build(operand1, 1)
            right_element = nil
          end

          if right_element&.literal?
            lhs = left_element.literal? ? left_element.get : 1
            warning = function.invalid?(lhs, right_element.get)
            unless warning.nil?
              raise LogStash::ConfigurationError,
                "Numeric literals are specified as in the calculation but the function invalidates with '#{warning}'. Calculation: #{calc.join(', ')}"
            end
          end

          result_element = MathCalculationElements.build(target, 3)
          @calculate_copy << [function, left_element, right_element, result_element]
        end

        if @calculate_copy.last.last.is_a?(MathCalculationElements::RegisterElement)
          raise LogStash::ConfigurationError,
            "The final target is a Register, the overall calculation result will not be set in the event"
        end
      end

      def filter(event)
        event_changed = false
        context = EventRegisterContext.new(event)

        @calculate_copy.each do |function, left_element, right_element, result_element|
          if logger.debug?
            logger.debug("executing",
                         "function" => function.name,
                         "left_field" => left_element,
                         "right_field" => right_element,
                         "target" => result_element)
          end

          operand1 = left_element.get(context)
          operand2 = right_element&.get(context)

          # Skip invalid operands
          next if operand1.nil? || (right_element && operand2.nil?)
          next if function.invalid?(operand1, operand2, event)

          begin
            result = if right_element
                       function.call(operand1, operand2)
                     else
                       function.call(operand1)
                     end
          rescue StandardError => e
            logger.warn("math calculation raised an exception, skipping this calculation",
                         "function" => function.name,
                         "operand1" => operand1,
                         "operand2" => operand2,
                         "error" => e.message)
            tag_on_failure.each { |tag| event.tag(tag) }
            next
          end

          result_element.set(result, context)
          if logger.debug?
            logger.debug("calculation result stored",
                         "function" => function.name,
                         "target" => result_element,
                         "result" => result)
          end
          event_changed = true
        end

        filter_matched(event) if event_changed
      end
    end
  end
end
