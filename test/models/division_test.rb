require 'test_helper'

# Tests for the "Division" model
class DivisionTest < ActiveSupport::TestCase
  def setup
    @division = Division.new(code: 'TD', name: 'Test Division')
  end

  test 'should be valid' do
    assert @division.valid?
  end

  test 'code should be present' do
    @division.code = '  '
    assert_not @division.valid?
  end

  test 'name should be present' do
    @division.name = '  '
    assert_not @division.valid?
  end
end
