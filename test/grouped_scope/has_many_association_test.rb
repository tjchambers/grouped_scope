require 'helper'

class GroupedScope::HasManyAssociationTest < GroupedScope::TestCase
  
  setup do
    setup_environment
  end
  
  context 'For an Employee' do
    
    setup do 
      @employee = FactoryGirl.create(:employee)
    end
    
    should 'scope existing association to owner' do
      assert_sql(/employee_id = #{@employee.id}/) do
        @employee.reports(true)
      end
    end
    
    should 'scope group association to group' do
      assert_sql(/employee_id IN \(#{@employee.id}\)/) do
        @employee.group.reports(true)
      end
    end
    
    context 'for counting sql' do
      
      setup do
        @e1 = FactoryGirl.create(:employee_with_reports, :group_id => 1)
        @e2 = FactoryGirl.create(:employee_with_reports, :group_id => 1)
      end
      
      should 'scope count sql to owner' do
        assert_sql(/SELECT count\(\*\)/,/employee_id = #{@e1.id}/) do
          @e1.reports(true).count
        end
      end
      
      should 'scope count sql to group' do
        assert_sql(/SELECT count\(\*\)/,/employee_id IN \(#{@e1.id},#{@e2.id}\)/) do
          @e1.group.reports(true).count
        end
      end
      
      should 'have a group count equal to sum of seperate owner counts' do
        assert_equal @e1.reports(true).count + @e2.reports(true).count, @e2.group.reports(true).count
      end
      
    end
    
    context 'training association extensions' do
    
      setup do
        @e1 = FactoryGirl.create(:employee_with_urgent_reports, :group_id => 1)
        @e2 = FactoryGirl.create(:employee, :group_id => 1)
        @urgent_reports = @e1.reports.select(&:urgent_title?)
      end
      
      should 'find urgent report via normal ungrouped association' do
        assert_same_elements @urgent_reports, @e1.reports(true).urgent
      end
      
      should 'find urgent report via grouped reflection' do
        assert_same_elements @urgent_reports, @e2.group.reports(true).urgent
      end
      
      should 'use assoc extension SQL along with group reflection' do
        assert_sql(select_from_reports, where_for_groups, where_for_urgent_title) do
          @e2.group.reports.urgent
        end
      end
    
    end
    
    context 'training named scopes' do
      
      setup do
        @e1 = FactoryGirl.create(:employee_with_urgent_reports, :group_id => 1)
        @e2 = FactoryGirl.create(:employee, :group_id => 1)
        @urgent_titles = @e1.reports.select(&:urgent_title?)
        @urgent_bodys = @e1.reports.select(&:urgent_body?)
      end
      
      should 'find urgent reports via normal named scopes by normal owner' do
        assert_same_elements @urgent_titles, @e1.reports(true).with_urgent_title
        assert_same_elements @urgent_bodys, @e1.reports(true).with_urgent_body
      end
      
      should 'find urgent reports via group reflection by group member' do
        assert_same_elements @urgent_titles, @e2.group.reports(true).with_urgent_title
        assert_same_elements @urgent_bodys, @e2.group.reports(true).with_urgent_body
      end
      
      should 'use named scope SQL along with group reflection' do
        assert_sql(select_from_reports, where_for_groups, where_for_urgent_body, where_for_urgent_title) do
          @e2.group.reports.with_urgent_title.with_urgent_body.inspect
        end
      end
      
      context 'with will paginate' do
        
        should 'use group reflection, named scope, and paginate SQL' do
          where_ends_with_limits = /WHERE.*LIMIT 2 OFFSET 0/
          assert_sql(select_from_reports, where_for_groups, where_for_urgent_body, where_for_urgent_title, where_ends_with_limits) do
            @e2.group.reports.with_urgent_title.with_urgent_body.paginate(:page=>1,:per_page=>2)
          end
        end
        
      end
      
    end
    
  end
  
  context 'For a LegacyEmployee' do
  
    setup do
      @employee = FactoryGirl.create(:legacy_employee)
    end
  
    should 'scope existing association to owner' do
      assert_sql(/"?legacy_reports"?.email = '#{@employee.id}'/) do
        @employee.reports(true)
      end
    end
    
    should 'scope group association to group' do
      assert_sql(/"?legacy_reports"?.email IN \('#{@employee.id}'\)/) do
        @employee.group.reports(true)
      end
    end
    
  end
  
  
  protected
  
  def select_from_reports
    /SELECT \* FROM "?reports"?/
  end
  
  def where_for_groups
    /WHERE.*"?reports"?.employee_id IN \(2,3\)/
  end
  
  def where_for_urgent_body
    /WHERE.*body LIKE '%URGENT%'/
  end
  
  def where_for_urgent_title
    /WHERE.*"?reports"?."?title"? = 'URGENT'/
  end
  
  
end
