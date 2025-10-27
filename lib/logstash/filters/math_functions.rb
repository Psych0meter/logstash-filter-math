# frozen_string_literal: true
# encoding: UTF-8
require "logstash/util/loggable"

module LogStash module Filters
  module MathFunctions
    #
    # Shared validity checks
    #
    module DivByZeroValidityCheck
      def invalid?(op1, op2 = nil, event = nil)
        # For unary operations op2 may be nil — no check needed in that case
        if !op2.nil? && op2.zero?
          warning = "a divisor of zero is not permitted"
          if event
            logger.warn(warning, "operand 1" => op1, "operand 2" => op2, "event" => event.to_hash)
            return true
          else
            return warning
          end
        end
        nil
      end
    end

    module NoValidityCheckNeeded
      def invalid?(op1, op2 = nil, event = nil)
        nil
      end
    end

    #
    # Helper base class to declare arity
    #
    module BinaryFunction
      def arity
        2
      end
    end

    module UnaryFunction
      def arity
        1
      end
    end

    #
    # Binary functions
    #
    class Add
      include BinaryFunction
      include NoValidityCheckNeeded

      def name; "add"; end
      def call(op1, op2); op1 + op2; end
    end

    class Subtract
      include BinaryFunction
      include NoValidityCheckNeeded

      def name; "subtract"; end
      def call(op1, op2); op1 - op2; end
    end

    class Multiply
      include BinaryFunction
      include NoValidityCheckNeeded

      def name; "multiply"; end
      def call(op1, op2); op1 * op2; end
    end

    class Round
      include BinaryFunction
      include NoValidityCheckNeeded

      def name; "round"; end
      def call(op1, op2); op1.round(op2); end
    end

    class Power
      include BinaryFunction
      include LogStash::Util::Loggable

      def name; "power"; end
      def call(op1, op2); op1 ** op2; end

      def invalid?(op1, op2 = nil, event = nil)
        # only relevant for binary
        if op1.is_a?(Numeric) && op1 < 0 && !op2.respond_to?(:integer?) ? false : (!op2.integer?)
          warning = "raising a negative number to a fractional exponent results in a complex number that cannot be stored in an event"
          if event
            logger.warn(warning, "operand 1" => op1, "operand 2" => op2, "event" => event.to_hash)
            return true
          else
            return warning
          end
        end
        nil
      end
    end

    class Divide
      include BinaryFunction
      include LogStash::Util::Loggable
      include DivByZeroValidityCheck

      def name; "divide"; end
      def call(op1, op2); op1 / op2; end
    end

    class FloatDivide
      include BinaryFunction
      include LogStash::Util::Loggable
      include DivByZeroValidityCheck

      def name; "float_divide"; end
      def call(op1, op2); op1.fdiv(op2); end
    end

    class Modulo
      include BinaryFunction
      include LogStash::Util::Loggable
      include DivByZeroValidityCheck

      def name; "modulo"; end
      def call(op1, op2); op1 % op2; end
    end

    #
    # Unary functions
    #
    class Abs
      include UnaryFunction
      include NoValidityCheckNeeded

      def name; "abs"; end
      def call(op1); op1.abs; end
    end

    class Negate
      include UnaryFunction
      include NoValidityCheckNeeded

      def name; "neg"; end
      def call(op1); -op1; end
    end

    #
    # Percent change (binary): ((new - old) / old) * 100
    #
    class PercentChange
      include BinaryFunction
      include LogStash::Util::Loggable
      include DivByZeroValidityCheck

      def name; "percent_change"; end
      def call(old_value, new_value)
        ((new_value - old_value).fdiv(old_value)) * 100.0
      end

      # DivByZeroValidityCheck will catch old_value == 0
    end

    #
    # Conversion functions (unary). We'll expose a few common ones.
    # Conversion is implemented as call(value) => value * multiplier + offset
    #
    class Conversion
      include UnaryFunction
      include NoValidityCheckNeeded

      def initialize(name_str, multiplier = 1.0, offset = 0.0)
        @name_str = name_str
        @multiplier = multiplier
        @offset = offset
      end

      def name
        @name_str
      end

      def call(op1)
        (op1 * @multiplier) + @offset
      end
    end

    #
    # Build function instances map used in register
    # (the Math filter's register will still map many aliases to these)
    #
    # Note: the Math filter's register method will create the key=>instance map,
    # but here we expose simple constructors to be used there.
    #
    def self.default_conversions
      {
        # distance
        "mi_to_km" => Conversion.new("mi_to_km", 1.609344, 0.0),
        "km_to_mi" => Conversion.new("km_to_mi", 1.0 / 1.609344, 0.0),
        # length
        "m_to_ft"  => Conversion.new("m_to_ft", 3.28083989501312, 0.0),
        "ft_to_m"  => Conversion.new("ft_to_m", 1.0 / 3.28083989501312, 0.0),
        # temperature
        "c_to_f"   => Conversion.new("c_to_f", 9.0 / 5.0, 32.0),         # (C * 9/5) + 32
        "f_to_c"   => Conversion.new("f_to_c", 5.0 / 9.0, -32.0 * 5.0 / 9.0) # (F - 32) * 5/9  => multiply then add offset
      }
    end
  end
end end
