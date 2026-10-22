class ProfilesController < ApplicationController
  skip_before_action :require_name_setup

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if current_user.update(user_params)
      redirect_to root_path, notice: "冒険の書に 名前を 刻んだ！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end
end
