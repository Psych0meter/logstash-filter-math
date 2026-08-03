# encoding: utf-8
require_relative "../spec_helper"
require "logstash/filters/math"

describe LogStash::Filters::Math do
  describe "Additions" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [ [ "add", "var1", "var2", "result" ] ] } }
    CONFIG

    describe "should add two integers" do
      sample( "var1" => -2,  "var2" => 7 ) do
        expect( subject.get("result") ).to eq( 5 )
      end
    end

    describe "should add two floats" do
      sample( "var1" => -2.4,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( 5.4  )
      end
    end

    describe "two huge numbers should add to infinity" do
      sample( "var1" => 1.79769313486232e+308,  "var2" => 1e+308 ) do
        expect( subject.get("result") ).to eq( Float::INFINITY )
      end
    end

    describe "one value being 0 should work" do
      sample( "var1" => 0,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( 7.8 )
      end
    end

    describe "first value missing should result in nil" do
      sample( "var2" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "Second value missing should result in nil" do
      sample( "var1" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "Subtractions" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [ [ "-", "var1", "var2", "result" ] ] } }
    CONFIG

    describe "should subtract two integers" do
      sample( "var1" => -2,  "var2" => 7 ) do
        expect( subject.get("result") ).to eq( -9 )
      end
    end

    describe "should subtract two floats" do
      sample( "var1" => -2.4,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( -10.2  )
      end
    end

    describe "two huge negative numbers should subtract to negative infinity" do
      sample( "var1" => -1.79769313486232e+308,  "var2" => -1e+308 ) do
        expect( subject.get("result") ).to eq( -Float::INFINITY )
      end
    end

    describe "one value being 0 should work" do
      sample( "var1" => 0,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( -7.8 )
      end
    end

    describe "first value missing should result in nil" do
      sample( "var2" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "Second value missing should result in nil" do
      sample( "var1" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "Rounding" do
    describe "when using a field as the right hand operand" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "round", "var1", "var2", "result" ] ] } }
      CONFIG

      describe "should round a float field" do
        sample( "var1" => 0.42424242, "var2" => 2 ) do
          expect( subject.get("result") ).to eq( 0.42 )
        end
      end

      describe "should round an integer field" do
        sample( "var1" => 42, "var2" => 2 ) do
          expect( subject.get("result") ).to eq( 42.0 )
        end
      end
    end

    describe "when using a literal as the right hand operand" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "round", "var1", 3, "result" ] ] } }
      CONFIG

      describe "should round a float field" do
        sample( "var1" => 0.42424242 ) do
          expect( subject.get("result") ).to eq( 0.424 )
        end
      end

      describe "should convert an integer to a float" do
        sample( "var1" => 42 ) do
          expect( subject.get("result") ).to eq( 42.0 )
        end
      end

      describe "should convert a float to an integer" do
        config <<-CONFIG
          filter {  math { calculate => [ [ "round", "var1", 0, "result" ] ] } }
        CONFIG
        sample( "var1" => 42.0 ) do
          expect( subject.get("result") ).to eq( 42 )
        end
      end
    end
  end

  describe "Multiplication" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [ [ "*", "var1", "var2", "result" ] ] } }
    CONFIG

    describe "should multiply two integers" do
      sample( "var1" => -2,  "var2" => 7 ) do
        expect( subject.get("result") ).to eq( -14 )
      end
    end

    describe "should multiply two floats" do
      sample( "var1" => -2.4,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( -18.72 )
      end
    end

    describe "two huge numbers should multiply to infinity" do
      sample( "var1" => 1.79769313486232e+300,  "var2" => 1e+300 ) do
        expect( subject.get("result") ).to eq( Float::INFINITY )
      end
    end

    describe "one value being 0 should result in 0" do
      sample( "var1" => 0,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( 0 )
      end
    end

    describe "first value missing should result in nil" do
      sample( "var2" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "Second value missing should result in nil" do
      sample( "var1" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "Exponentiation" do
    # The logstash config.
    describe "verbose operation name" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "to the power of", "var1", "var2", "result" ] ] } }
      CONFIG

      describe "should exponentiate two integers" do
        sample( "var1" => -2,  "var2" => 5 ) do
          expect( subject.get("result") ).to eq( -32 )
        end
      end

      describe "should exponentiate two floats" do
        sample( "var1" => 2.2,  "var2" => 1.2 ) do
          expect( subject.get("result") ).to eq( 2.5757708085227633 )
        end
      end

      describe "two huge numbers should exponentiate to infinity" do
        sample( "var1" => 1.79769313486232e+300,  "var2" => 1e+300 ) do
          expect( subject.get("result") ).to eq( Float::INFINITY )
        end
      end
    end

    describe "terse operation name" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "**", "var1", "var2", "result" ] ] } }
      CONFIG

      describe "base value being negative and the exponent being fractional should result in nil" do
        sample( "var1" => -2.2,  "var2" => 7.8 ) do
          expect( subject.get("result") ).to eq( nil )
        end
      end

      describe "base value being 0 should result in 0" do
        sample( "var1" => 0,  "var2" => 7.8 ) do
          expect( subject.get("result") ).to eq( 0 )
        end
      end

      describe "exponent value being 0 should result in 1" do
        sample( "var1" => 7.8,  "var2" => 0 ) do
          expect( subject.get("result") ).to eq( 1 )
        end
      end

      describe "first value missing should result in nil" do
        sample( "var2" => 3 ) do
          expect( subject.get("result") ).to be_nil
        end
      end

      describe "Second value missing should result in nil" do
        sample( "var1" => 3 ) do
          expect( subject.get("result") ).to be_nil
        end
      end
    end
  end

  describe "Division" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [ [ "/", "var1", "var2", "result" ] ] } }
    CONFIG

    describe "should divide two integers" do
      sample( "var1" => -2,  "var2" => 7 ) do
        expect( subject.get("result") ).to eq( -1 )
      end
    end

    describe "should divide two floats" do
      sample( "var1" => -2.4,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( -0.3076923076923077 )
      end
    end

    describe "1 divided by a huge number should give zero" do
      sample( "var1" => 1, "var2" => 1.79769313486232e+308 ) do
        expect( subject.get("result") ).to eq( 0 )
      end
    end

    describe "First variable being zero should result in 0" do
      sample( "var1" => 0,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( 0 )
      end
    end

    describe "Second variable being zero should result in nil (would be infinity, but this can't be represented in JSON)" do
      sample( "var1" => 2,  "var2" => 0 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "first value missing should result in nil" do
      sample( "var2" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "Second value missing should result in nil" do
      sample( "var1" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "FloatDiv" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [ [ "fdiv", "var1", "var2", "result" ] ] } }
    CONFIG

    describe "should divide two integers" do
      sample( "var1" => -2,  "var2" => 7 ) do
        expect( subject.get("result") ).to eq( -0.2857142857142857 )
      end
    end

    describe "should divide two floats" do
      sample( "var1" => -2.4,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( -0.3076923076923077 )
      end
    end

    describe "1 divided by a huge number should give zero" do
      sample( "var1" => 1, "var2" => 1.79769313486232e+308 ) do
        expect( subject.get("result") ).to eq( 0 )
      end
    end

    describe "First variable being zero should result in 0" do
      sample( "var1" => 0,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( 0 )
      end
    end

    describe "Second variable being zero should result in nil (would be infinity, but this can't be represented in JSON)" do
      sample( "var1" => 2,  "var2" => 0 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "first value missing should result in nil" do
      sample( "var2" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "Second value missing should result in nil" do
      sample( "var1" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "Modulo" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [ [ "mod", "var1", "var2", "result" ] ] } }
    CONFIG

    describe "should get modulo of two integers" do
      sample( "var1" => 53,  "var2" => 13 ) do
        expect( subject.get("result") ).to eq( 1 )
      end
    end

    describe "should get modulo of two floats" do
      sample( "var1" => 53.4,  "var2" => 13.1 ) do
        expect( subject.get("result") ).to eq( 1.0 )
      end
    end

    describe "1 modulo a huge number should give 1.0" do
      sample( "var1" => 1, "var2" => 1.79769313486232e+308 ) do
        expect( subject.get("result") ).to eq( 1.0 )
      end
    end

    describe "First variable being zero should result in 0.0" do
      sample( "var1" => 0,  "var2" => 7.8 ) do
        expect( subject.get("result") ).to eq( 0.0 )
      end
    end

    describe "Second variable being zero should result in nil (would be infinity, but this can't be represented in JSON)" do
      sample( "var1" => 2,  "var2" => 0 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "first value missing should result in nil" do
      sample( "var2" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end

    describe "Second value missing should result in nil" do
      sample( "var1" => 3 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "Unary functions" do
    describe "Abs" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "abs", "var1", "result" ] ] } }
      CONFIG

      describe "should return the absolute value of a negative number" do
        sample( "var1" => -5 ) do
          expect( subject.get("result") ).to eq( 5 )
        end
      end

      describe "should return the same value for a positive number" do
        sample( "var1" => 5.5 ) do
          expect( subject.get("result") ).to eq( 5.5 )
        end
      end

      describe "missing operand should result in nil" do
        sample( "other" => 1 ) do
          expect( subject.get("result") ).to be_nil
        end
      end
    end

    describe "Negate" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "neg", "var1", "result" ] ] } }
      CONFIG

      describe "should negate a positive number" do
        sample( "var1" => 5 ) do
          expect( subject.get("result") ).to eq( -5 )
        end
      end

      describe "should negate a negative number" do
        sample( "var1" => -5.5 ) do
          expect( subject.get("result") ).to eq( 5.5 )
        end
      end
    end

    describe "Floor" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "floor", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 5.7 ) do
        expect( subject.get("result") ).to eq( 5 )
      end

      sample( "var1" => -5.1 ) do
        expect( subject.get("result") ).to eq( -6 )
      end
    end

    describe "Ceil" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "ceil", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 5.1 ) do
        expect( subject.get("result") ).to eq( 6 )
      end

      sample( "var1" => -5.7 ) do
        expect( subject.get("result") ).to eq( -5 )
      end
    end

    describe "Sign" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "sign", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 42 ) do
        expect( subject.get("result") ).to eq( 1 )
      end

      sample( "var1" => -42 ) do
        expect( subject.get("result") ).to eq( -1 )
      end

      sample( "var1" => 0 ) do
        expect( subject.get("result") ).to eq( 0 )
      end
    end

    describe "Sqrt" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "sqrt", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 16 ) do
        expect( subject.get("result") ).to eq( 4.0 )
      end

      describe "a negative operand should result in nil" do
        sample( "var1" => -16 ) do
          expect( subject.get("result") ).to be_nil
        end
      end

      context "a negative literal operand is detected at plugin register" do
        it "raises a validation error" do
          pipeline = new_pipeline_from_string('filter {  math { calculate => [ [ "sqrt", -4, "result" ] ] } }')
          expect { pipeline.instance_eval{ @filters.each(&:register) } }.to raise_exception(LogStash::ConfigurationError, /sqrt of a negative number/)
        end
      end
    end

    describe "Cbrt" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "cbrt", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 27 ) do
        expect( subject.get("result") ).to eq( 3.0 )
      end

      describe "a negative operand should work (unlike sqrt)" do
        sample( "var1" => -27 ) do
          expect( subject.get("result") ).to eq( -3.0 )
        end
      end
    end

    describe "Ln" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "ln", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 1 ) do
        expect( subject.get("result") ).to eq( 0.0 )
      end

      describe "a zero or negative operand should result in nil" do
        sample( "var1" => 0 ) do
          expect( subject.get("result") ).to be_nil
        end
      end
    end

    describe "Log10" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "log10", "var1", "result" ] ] } }
      CONFIG

      sample( "var1" => 100 ) do
        expect( subject.get("result") ).to eq( 2.0 )
      end

      describe "a zero or negative operand should result in nil" do
        sample( "var1" => -1 ) do
          expect( subject.get("result") ).to be_nil
        end
      end
    end
  end

  describe "Min/Max" do
    describe "Min" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "min", "var1", "var2", "result" ] ] } }
      CONFIG

      sample( "var1" => 5, "var2" => 9 ) do
        expect( subject.get("result") ).to eq( 5 )
      end

      sample( "var1" => 9, "var2" => 5 ) do
        expect( subject.get("result") ).to eq( 5 )
      end
    end

    describe "Max" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "max", "var1", "var2", "result" ] ] } }
      CONFIG

      sample( "var1" => 5, "var2" => 9 ) do
        expect( subject.get("result") ).to eq( 9 )
      end

      sample( "var1" => 9, "var2" => 5 ) do
        expect( subject.get("result") ).to eq( 9 )
      end
    end
  end

  describe "PercentChange" do
    config <<-CONFIG
      filter {  math { calculate => [ [ "percent_change", "old_value", "new_value", "result" ] ] } }
    CONFIG

    describe "should calculate a positive percent change" do
      sample( "old_value" => 80, "new_value" => 100 ) do
        expect( subject.get("result") ).to eq( 25.0 )
      end
    end

    describe "should calculate a negative percent change" do
      sample( "old_value" => 100, "new_value" => 80 ) do
        expect( subject.get("result") ).to eq( -20.0 )
      end
    end

    describe "old value being zero should result in nil (would be infinity)" do
      sample( "old_value" => 0, "new_value" => 80 ) do
        expect( subject.get("result") ).to be_nil
      end
    end
  end

  describe "Unit conversions" do
    describe "mi_to_km" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "mi_to_km", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1 ) do
        expect( subject.get("result") ).to be_within(0.0001).of(1.609344)
      end
    end

    describe "km_to_mi" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "km_to_mi", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1.609344 ) do
        expect( subject.get("result") ).to be_within(0.0001).of(1.0)
      end
    end

    describe "m_to_ft" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "m_to_ft", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1 ) do
        expect( subject.get("result") ).to be_within(0.0001).of(3.28084)
      end
    end

    describe "ft_to_m" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "ft_to_m", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 3.28083989501312 ) do
        expect( subject.get("result") ).to be_within(0.0001).of(1.0)
      end
    end

    describe "c_to_f" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "c_to_f", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 0 ) do
        expect( subject.get("result") ).to eq( 32.0 )
      end
      sample( "var1" => 100 ) do
        expect( subject.get("result") ).to eq( 212.0 )
      end
    end

    describe "f_to_c" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "f_to_c", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 32 ) do
        expect( subject.get("result") ).to eq( 0.0 )
      end
      sample( "var1" => 212 ) do
        expect( subject.get("result") ).to eq( 100.0 )
      end
    end

    describe "bytes_to_kb" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "bytes_to_kb", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1024 ) do
        expect( subject.get("result") ).to eq( 1.0 )
      end
    end

    describe "kb_to_bytes" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "kb_to_bytes", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1 ) do
        expect( subject.get("result") ).to eq( 1024.0 )
      end
    end

    describe "bytes_to_mb" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "bytes_to_mb", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1048576 ) do
        expect( subject.get("result") ).to eq( 1.0 )
      end
    end

    describe "mb_to_bytes" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "mb_to_bytes", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1 ) do
        expect( subject.get("result") ).to eq( 1048576.0 )
      end
    end

    describe "bytes_to_gb" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "bytes_to_gb", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1073741824 ) do
        expect( subject.get("result") ).to eq( 1.0 )
      end
    end

    describe "gb_to_bytes" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "gb_to_bytes", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1 ) do
        expect( subject.get("result") ).to eq( 1073741824.0 )
      end
    end

    describe "ms_to_s" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "ms_to_s", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1500 ) do
        expect( subject.get("result") ).to eq( 1.5 )
      end
    end

    describe "s_to_ms" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "s_to_ms", "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 1.5 ) do
        expect( subject.get("result") ).to eq( 1500.0 )
      end
    end
  end

  describe "Resilience" do
    describe "a runtime exception inside a calculation is caught, tagged, and does not crash the filter" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "round", "var1", "var2", "result" ] ] } }
      CONFIG

      # 42.0.round(10**20) raises RangeError: bignum too big to convert into `long'
      sample( "var1" => 42.0, "var2" => 10**20 ) do
        expect( subject.get("result") ).to be_nil
        expect( subject.get("tags") ).to include("_mathexception")
      end
    end

    describe "tag_on_failure can be customized" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "round", "var1", "var2", "result" ] ]  tag_on_failure => ["_my_custom_tag"] } }
      CONFIG

      sample( "var1" => 42.0, "var2" => 10**20 ) do
        expect( subject.get("tags") ).to include("_my_custom_tag")
      end
    end
  end

  describe "Literals" do
    context "how much smaller is one number than another in percent" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "float divide", "var1", "var2", "result" ],[ "times", "result", 100, "percent_difference" ] ] } }
      CONFIG
      sample( "var1" => 13, "var2" => 104 ) do
        expect( subject.get("percent_difference") ).to eq(12.5)
      end
    end

    context "what is the reciprocal of a value" do
      config <<-CONFIG
        filter {  math { calculate => [ [ "float divide", 1, "var1", "result" ] ] } }
      CONFIG
      sample( "var1" => 8 ) do
        expect( subject.get("result") ).to eq(0.125)
      end
    end

    context "when specifying a zero literal, a divide by zero error is detected at plugin register" do
      it "raises a validation error" do
        pipeline = new_pipeline_from_string('filter {  math { calculate => [ [ "divide", "var1", 0, "result" ] ] } }')
        expect { pipeline.instance_eval{ @filters.each(&:register) } }.to raise_exception(LogStash::ConfigurationError, /Numeric literals are specified as in the calculation but the function invalidates with 'a divisor of zero is not permitted'/)
      end
    end

    context "when specifying literals: -2 and 1.2 with the Power function, an error is detected at plugin register" do
      it "raises a validation error" do
        pipeline = new_pipeline_from_string('filter {  math { calculate => [ [ "**", -2, 1.2, "result" ] ] } }')
        expect { pipeline.instance_eval{ @filters.each(&:register) } }.to raise_exception(LogStash::ConfigurationError, /Numeric literals are specified as in the calculation but the function invalidates with 'raising a negative number to a fractional exponent results in a complex number that cannot be stored in an event'/)
      end
    end
  end

  describe "Timestamps" do
    t1 = Time.new(2018, 06, 8, 11, 0, 0,"+00:00")
    t2 = Time.new(2018, 06, 8, 11, 0, 30,"+00:00")
    config <<-CONFIG
      filter {  math { calculate => [ [ "sub", "[var2]", "[var1]", "result" ] ] } }
    CONFIG

    context "subtracting 2 LogStash::Timestamps" do
      sample( "var1" => LogStash::Timestamp.at(t1.to_f),  "var2" =>  LogStash::Timestamp.at(t2.to_f)) do
        expect( subject.get("result") ).to eq(30.0)
      end
    end

    context "subtracting a Time from a Timestamp" do
      sample( "var1" => t1,  "var2" =>  LogStash::Timestamp.at(t2.to_f)) do
        expect( subject.get("result") ).to eq(30.0)
      end
    end
  end

  describe "multithreading" do
    it "should still calculate correctly" do
      array = [
        [ "+", "[var1]", "[var2]", "MEM[0]" ],
        [ "-", "[var3]", "[var4]", "MEM[1]" ],
        [ "*", "MEM[0]", "MEM[1]", "[result]" ]
      ]

      math_hash = {"calculate" => array}

      event1 = LogStash::Event.new("var1" => 3.4,  "var2" => 6.6, "var3" => 4.4, "var4" => 2.4)
      event2 = LogStash::Event.new("var1" => 6.8,  "var2" => 13.2, "var3" => 8.8, "var4" => 4.8)
      plugin = described_class.new(math_hash)
      plugin.register
      expect do
        thread1 = Thread.new(plugin, event1) do |plugin, event|
          100.times do
            plugin.filter(event)
            result = event.get("result")
            raise "Thread 1 failed, result is: #{result}" if result != 20.000000000000004
            sleep 0.011
          end
        end
        thread2 = Thread.new(plugin, event2) do |plugin, event|
          100.times do
            plugin.filter(event)
            result = event.get("result")
            raise "Thread 2 failed, result is: #{result}" if result != 80.00000000000001
            sleep 0.01
          end
        end
        thread1.join
        thread2.join
      end.not_to raise_exception
    end
  end

  describe "Sequence" do
    # The logstash config.
    config <<-CONFIG
      filter {  math { calculate => [
            [ "add", "var1", "var2", "r1" ],
            [ "sub", "var3", "var4", "r2" ],
            [ "mpx", "r1", "r2", "result" ]
          ] } }
    CONFIG

    describe "results of one calculation can be used in the next calculation" do
      sample( "var1" => 3.4,  "var2" => 6.6, "var3" => 4.4, "var4" => 2.4 ) do
        # I would really expect 20.0 here... what kind of floating point error is this?!
        expect( subject.get("result") ).to eq( 20.000000000000004 )
      end
    end
  end

  describe "Sequence with registers" do
    describe "results of one calculation can be used in the next calculation" do
      config <<-CONFIG
        filter {  math { calculate => [
              [ "+", "[var1]", "[var2]", "MEM[0]" ],
              [ "-", "[var3]", "[var4]", "MEM[1]" ],
              [ "*", "MEM[0]", "MEM[1]", "[result]" ]
            ] } }
      CONFIG
      sample( "var1" => 3.4,  "var2" => 6.6, "var3" => 4.4, "var4" => 2.4 ) do
        # I would really expect 20.0 here... what kind of floating point error is this?!
        expect( subject.get("result") ).to eq( 20.000000000000004 )
      end
    end

    describe "when a register is used as the very last target, a configuration error is raised" do
      it "raises a validation error" do
        pipeline = new_pipeline_from_string('filter {  math { calculate => [ [ "**", "[var1]", "[var2]", "MEM[0]" ] ] } }')
        expect { pipeline.instance_eval{ @filters.each(&:register) } }.to raise_exception(LogStash::ConfigurationError, /The final target is a Register, the overall calculation result will not be set in the event/)
      end
    end
  end
end
