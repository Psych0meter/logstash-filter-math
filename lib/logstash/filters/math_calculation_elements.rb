# encoding: utf-8
require "logstash/util/loggable"

module LogStash module Filters
  # MathCalculationElements provides a factory and element classes for handling
  # different types of operands and results in mathematical calculations.
  # It supports literal values, event field references, and register/memory references.
  module MathCalculationElements
    # Regular expression to match register/memory references like "MEM[123]"
    REGISTER_REFERENCE_RE = /^MEM\[(\d+)]$/

    # Factory method to create the appropriate element based on the reference type
    #
    # @param reference [Numeric, String] The value reference (number, field name, or register reference)
    # @param position [Integer] The operand position (1, 2) or result position (3)
    # @return [RegisterElement, FieldElement, LiteralElement, nil] Appropriate element instance
    def self.build(reference, position)
      case reference
      when Numeric
        if position == 3
          # literal reference for result element
          nil
        else
          LiteralElement.new(reference, position)
        end
      when String
        match = REGISTER_REFERENCE_RE.match(reference)
        if match
          RegisterElement.new(reference, position, match[1].to_i)
        else
          FieldElement.new(reference, position)
        end
      else
        nil
      end
    end

    # Represents a reference to a value stored in a register/memory slot
    class RegisterElement
      # @param reference [String] The original reference string (e.g., "MEM[123]")
      # @param position [Integer] The operand position (1, 2) or result position (3)
      # @param index [Integer] The register index number
      def initialize(reference, position, index)
        @reference = reference
        @position = position
        @index = index
        @description = (position == 3 ? "#{@index}" : "operand #{@position}").prepend("register ").concat(": '#{@reference}'")
      end

      # @return [Integer] The register index used as a key
      def key
        @index
      end

      # @return [Boolean] Always false for register elements
      def literal?
        false
      end

      # Stores a value in the register
      #
      # @param value [Numeric] The value to store
      # @param event_register_context [Object] Context providing register access
      def set(value, event_register_context)
        # raise usage error if called when position != 3 ??
        event_register_context.set(self, value)
      end

      # Retrieves a value from the register
      #
      # @param event_register_context [Object] Context providing register access
      # @return [Numeric, nil] The stored value or nil if not found
      def get(event_register_context)
        event_register_context.get(self) #log warning if nil
      end

      # @return [String] Debug representation
      def inspect
        "\"#{@description}\""
      end

      # @return [String] Human-readable description
      def to_s
        @description
      end
    end

    # Represents a reference to a value stored in an event field
    class FieldElement
      include LogStash::Util::Loggable

      # @param field [String] The event field name
      # @param position [Integer] The operand position (1, 2) or result position (3)
      def initialize(field, position)
        @field = field
        @position = position
        @description = (position == 3 ? "result" : "operand #{@position}").prepend("event ").concat(": '#{@field}'")
      end

      # @return [String] The field name used as a key
      def key
        @field
      end

      # @return [Boolean] Always false for field elements
      def literal?
        false
      end

      # Stores a value in the event field
      #
      # @param value [Numeric] The value to store
      # @param event_register_context [Object] Context providing field access
      def set(value, event_register_context)
        event_register_context.set(self, value)
      end

      # Retrieves a value from the event field, converting string numbers to numeric types
      #
      # @param event_register_context [Object] Context providing field access
      # @return [Numeric, nil] The field value converted to number, or nil if not convertible
      def get(event_register_context)
        value = event_register_context.get(self)
        if value.nil?
          logger.warn("field not found", "field" => @field, "event" => event_register_context.event.to_hash)
          return nil
        end
        
        # Convert string representations of numbers to actual numeric types
        numeric_value = convert_to_numeric(value)
        
        if numeric_value
          numeric_value
        elsif value.is_a?(LogStash::Timestamp) || value.is_a?(Time)
          value.to_f
        else
          logger.warn("field value is not numeric or time", "field" => @field, "value" => value, "event" => event_register_context.event.to_hash)
          nil
        end
      end

      # @return [String] Debug representation
      def inspect
        "\"#{@description}\""
      end

      # @return [String] Human-readable description
      def to_s
        @description
      end

      private

      # Converts various value types to numeric representation
      #
      # @param value [Object] The value to convert
      # @return [Numeric, nil] Converted numeric value or nil if not convertible
      def convert_to_numeric(value)
        case value
        when Numeric
          value
        when String
          convert_string_to_numeric(value)
        when TrueClass, FalseClass
          value ? 1 : 0 # Convert booleans to numbers
        else
          nil
        end
      end

      # Converts string representations to numeric values with robust validation
      #
      # @param str [String] The string to convert
      # @return [Integer, Float, nil] Converted number or nil if not a valid numeric string
      def convert_string_to_numeric(str)
        cleaned = str.to_s.strip
        return nil if cleaned.empty?
        
        # Check for integer pattern (optional sign, digits only)
        if cleaned.match?(/\A-?\d+\z/)
          begin
            return Integer(cleaned)
          rescue ArgumentError
            return nil
          end
        end
        
        # Check for float pattern (optional sign, digits with optional decimal and exponent)
        if cleaned.match?(/\A-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\z/)
          begin
            return Float(cleaned)
          rescue ArgumentError
            return nil
          end
        end
        
        nil
      end
    end

    # Represents a literal numeric value (cannot be set, only read)
    class LiteralElement
      # @param literal [Numeric] The literal numeric value
      # @param position [Integer] The operand position (1, 2)
      def initialize(literal, position)
        @literal = literal
        @position = position
      end

      # @return [nil] Literal elements don't have a key
      def key
        nil
      end

      # @return [Boolean] Always true for literal elements
      def literal?
        true
      end

      # Returns the literal value
      #
      # @param event_register_context [Object] Ignored for literal elements
      # @return [Numeric] The literal value
      def get(event_register_context = nil)
        @literal
      end

      # @return [String] Debug representation showing the literal value
      def inspect
        "\"operand #{@position}: #{@literal.inspect}\""
      end

      # @return [String] Same as inspect
      def to_s
        inspect
      end
    end
  end
end end