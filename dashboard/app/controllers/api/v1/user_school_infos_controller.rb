class Api::V1::UserSchoolInfosController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user_school_info
  load_and_authorize_resource except: [:update_end_date, :update_school_info_id]
  skip_before_action :verify_authenticity_token

  # PATCH /api/v1/users_school_infos/<id>/update_last_confirmation_date
  def update_last_confirmation_date
    @user_school_info.update!(last_confirmation_date: DateTime.now)

    head :no_content
  end

  # PATCH /api/v1/users_school_infos/<id>/update_end_date
  def update_end_date
    ActiveRecord::Base.transaction do
      @user_school_info.update!(end_date: DateTime.now, last_confirmation_date: DateTime.now)
    end
    @user_school_info.user.last_seen_school_info_interstitial = DateTime.now
    @user_school_info.user.save(validate: false)

    head :no_content
  end

  # PATCH /api/v1/user_school_infos/<id>/update_school_info_id
  # A new row is added to the user school infos table when a teacher updates current school to a different school,
  # then the school_info_id is updated in the users table.

  def update_school_info_id
    ActiveRecord::Base.transaction do
      school = @user_school_info.school_info.school
      unless school
        school = School.create!(new_school_params)
        school.school_info.create!(school_info_params)
      end

      school_info = school.school_info.order(created_at: :desc).first

      user = @user_school_info.user

      # require 'pry'
      # binding.pry

      user.user_school_infos.create!({school_info_id: school_info.id, last_confirmation_date: DateTime.now, start_date: user.created_at})

      user.update!({school_info_id: school_info.id})
    end
    # ActiveRecord::Base.transaction do
    #   # Set end date of existing school info
    #   @user_school_info.update(end_date: DateTime.now)

    #   # ? do we need to set the end date of the existing user?

    #   # Create new school info record
    #   school_info = SchoolInfo.create(school_info_params)

    #   # Create new user school info record
    #   UserSchoolInfo.create(
    #     user: current_user,
    #     school_info: school_info,
    #     last_confirmation_date: DateTime.now,
    #     start_date: current_user.created_at
    #   )

    #   # Update user (legacy connection)
    #   current_user.update!(school_info: school_info)
    # end
  end

  private

  def load_user_school_info
    @user_school_info = UserSchoolInfo.find(params[:id])
  end

  def new_school_params
    params.require(:school).permit(:name, :city, :state)
  end

  def school_info_params
    params.require(:school_info).permit(:school_type, :state, :school_name, :country)
  end
end
