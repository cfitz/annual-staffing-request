# rubocop:disable Metrics/MethodLength
class StaffRequestsController < ApplicationController
  include PersonnelRequestController
  before_action :set_staff_request, only: [:show, :edit, :update, :destroy]
  after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  # GET /staff_requests
  # GET /staff_requests.json
  def index
    @q = archive? ? ArchivedStaffRequest.ransack(params[:q]) : StaffRequest.ransack(params[:q])

    default_sorts!
    @staff_requests = scope_records(params)

    respond_to do |format|
      format.html
      format.xlsx { send_xlsx(@staff_requests, StaffRequest) }
    end
  end

  # GET /staff_requests/1
  # GET /staff_requests/1.json
  def show
    authorize @staff_request
  end

  # GET /staff_requests/new
  def new
    authorize StaffRequest
    @staff_request = StaffRequest.new
    assign_selectable_departments_and_units(@staff_request)
  end

  # GET /staff_requests/1/edit
  def edit
    authorize @staff_request
    assign_selectable_departments_and_units(@staff_request)
  end

  # POST /staff_requests
  # POST /staff_requests.json
  def create
    @staff_request = StaffRequest.new(staff_request_params)
    authorize @staff_request

    respond_to do |format|
      if @staff_request.save
        format.html do
          redirect_to @staff_request,
                      notice: "Staff request for #{@staff_request.description} was successfully created."
        end
        format.json { render :show, status: :created, location: @staff_request }
      else
        format.html do
          assign_selectable_departments_and_units(@staff_request)
          render :new
        end
        format.json { render json: @staff_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /staff_requests/1
  # PATCH/PUT /staff_requests/1.json
  def update
    authorize @staff_request
    respond_to do |format|
      if @staff_request.update(staff_request_params)
        format.html do
          redirect_to @staff_request,
                      notice: "Staff request for #{@staff_request.description} was successfully updated."
        end
        format.json { render :show, status: :ok, location: @staff_request }
      else
        format.html do
          assign_selectable_departments_and_units(@staff_request)
          render :new
        end
        format.json { render json: @staff_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /staff_requests/1
  # DELETE /staff_requests/1.json
  def destroy
    authorize @staff_request
    @staff_request.destroy
    respond_to do |format|
      format.html do
        redirect_to staff_requests_url,
                    notice: "Staff request for #{@staff_request.description} was successfully destroyed."
      end
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_staff_request
      @staff_request = find_active_or_archived('StaffRequest')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def staff_request_params
      localized_fields = { annual_base_pay: :number, nonop_funds: :number }
      allowed = [:employee_name, :employee_type_id, :position_title, :request_type_id,
                 :annual_base_pay, :nonop_funds, :nonop_source, :department_id,
                 :unit_id, :justification] + policy(@staff_request || StaffRequest.new).permitted_attributes
      params.require(:staff_request).permit(allowed).delocalize(localized_fields)
    end
end
