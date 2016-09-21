require 'test_helper'
require 'integration/personnel_requests_test_helper'

# Integration test for the StaffRequest edit page
class StaffRequestsEditTest < ActionDispatch::IntegrationTest
  include PersonnelRequestsTestHelper

  def setup
    @staff_request = staff_requests(:fac)
    @division1 = divisions_with_records[0]
    @division1_user = User.create(cas_directory_id: 'division1', name: 'Division1 User')
    Role.create!(user: @division1_user,
                 role_type: RoleType.find_by_code('division'),
                 division: @division1)
  end

  test 'currency field values show with two decimal places' do
    get edit_staff_request_path(@staff_request)

    currency_fields = %w(staff_request_annual_base_pay staff_request_nonop_funds)
    currency_fields.each do |field|
      assert_select "[id=#{field}]" do |e|
        verify_two_digit_currency_field(field, e.attribute('value'))
      end
    end
  end

  test '"Edit" button should only be shown if policy allows edit' do
    run_as_user(@division1_user) do
      staff_requests_all = StaffRequest.all

      staff_requests_all.each do |r|
        get staff_request_path(r)
        if Pundit.policy!(@division1_user, r).edit?
          assert_select "[id='button_edit']", 1,
                        "'#{@division1.code}' user could NOT edit " \
                        "'#{r.id}' with division '#{r.department.division.code}'"
        else
          assert_select "[id='button_edit']", 0,
                        "'#{@division1.code}' user could edit " \
                        "'#{r.id}' with division '#{r.department.division.code}'"
        end
      end
    end

    Role.destroy_all(user: @division1_user)
    @division1_user.destroy!
  end

  test 'can edit review_status or review_comments' do
    get edit_staff_request_path(@staff_request)
    assert_select "select#staff_request_review_status_id[disabled='disabled']", false
    assert_select "textarea#staff_request_review_comment[disabled='disabled']", false
  end

  test 'Non-admins cannot edit review_status or review_comments' do
    run_as_user(@division1_user) do
      get edit_staff_request_path(@staff_request)
      assert_select "select#staff_request_review_status_id[disabled='disabled']"
      assert_select "textarea#staff_request_review_comment[disabled='disabled']"
    end
  end

  test 'can only see departments/units allowed by role in drop-downs' do
    staff_request_with_unit = staff_requests(:fac_with_unit)
    with_temp_user(units: [staff_request_with_unit.unit.code]) do |temp_user|
      run_as_user(temp_user) do
        get edit_staff_request_path(staff_request_with_unit)

        # Verify department options
        expected_options = [staff_request_with_unit.unit.department.name]
        verify_options(response, 'staff_request_department_id', expected_options)

        # Verify unit options
        expected_options = ['<Clear Unit>', staff_request_with_unit.unit.name]
        verify_options(response, 'staff_request_unit_id', expected_options)
      end
    end
  end

  test 'can only see departments/units allowed by role in drop-downs with role cutoffs' do
    staff_request = staff_requests(:fac) # c1 is in PRG department
    department_for_role = staff_request.department
    unit_for_role = units(:one)
    with_temp_user(departments: [department_for_role.code], units: [unit_for_role.code]) do |temp_user|
      run_as_user(temp_user) do
        unit_role_cutoff = role_cutoffs(:unit)
        unit_role_cutoff.cutoff_date = 1.day.from_now
        unit_role_cutoff.save!

        get edit_staff_request_path(staff_request)

        # Verify department options
        expected_options = [unit_for_role.department.name, staff_request.department.name]
        verify_options(response, 'staff_request_department_id', expected_options)

        # Verify unit options
        expected_options = [unit_for_role.name]
        verify_options(response, 'staff_request_unit_id', expected_options)

        unit_role_cutoff = role_cutoffs(:unit)
        unit_role_cutoff.cutoff_date = 1.day.ago
        unit_role_cutoff.save!

        get edit_staff_request_path(staff_request)

        # Verify department options - should no longer include department for unit
        expected_options = [staff_request.department.name]
        verify_options(response, 'staff_request_department_id', expected_options)

        # Verify unit options - should have no options
        expected_options = []
        verify_options(response, 'staff_request_unit_id', expected_options)
      end
    end
  end
end
