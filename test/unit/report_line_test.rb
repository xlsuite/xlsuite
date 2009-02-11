require File.dirname(__FILE__) + "/../test_helper"

class ReportLineTest < Test::Unit::TestCase
  class SomeReportLine < ReportLine
    def value; @value.to_s; end
    def operator; "="; end
  end

  context "A report line" do
    setup do
      @sql_name = "report.column_name"
      @column_name = "report_column_name"
      @alias_name = "report_column_name"

      @line = SomeReportLine.new(:field => @column_name, :value => "some value")
      @sql = {:conditions => [[], []], :having => [[], []], :order => []}
    end

    should "have modified the SQL to add it's condition" do
      @line.add_conditions!(@sql, @column_name, @alias_name)
      assert_equal ["#{@column_name} = :#{@alias_name}"], @sql[:conditions][0]
    end

    should "have modified the SQL to add it's value" do
      @line.add_conditions!(@sql, @column_name, @alias_name)
      assert_equal [{@alias_name => @line.value.to_s}], @sql[:conditions][1]
    end

    should "NOT add an order clause" do
      assert_equal [], @sql[:order]
    end

    context "with an order" do
      setup do
        @line.order = "ASC"
      end

      should "have modified the SQL to add it's order" do
        @line.add_conditions!(@sql, @column_name, @alias_name)
        assert_equal ["#{@column_name} ASC"], @sql[:order]
      end
    end
  end
end
