class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game, only: [:show, :edit, :update, :destroy, :destroy_image]

  def index
    @games = current_user.games.order(created_at: :desc)
    @games = @games.where(status: params[:status]) if params[:status].present?
    @total_count = current_user.games.count
    @clear_rate = @total_count > 0 ? (current_user.games.where(status: "クリア済").count * 100 / @total_count) : 0
  end

  def show
  end

  def new
    @game = current_user.games.build
  end

  def create
    @game = current_user.games.build(game_params)
    if @game.save
      attach_rawg_image
      redirect_to @game, notice: "ゲームを登録しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      attach_rawg_image
      redirect_to @game, notice: "更新しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    redirect_to games_path, notice: "削除しました！"
  end

  def destroy_image
    @game.image.purge if @game.image.attached?
    redirect_to edit_game_path(@game), notice: "画像を削除しました！"
  end

  def search
    render json: params[:query].present? ? RawgApiService.search(params[:query]) : []
  end


  private

  def set_game
      @game = current_user.games.find_by(id: params[:id])
      if @game.nil?
        redirect_to games_path, alert: "ゲームが見つかりません"
      end
  end
  
  def game_params
    params.require(:game).permit(:title, :platform, :genre, :status, :memo, :rating, :purchased_at, :image, :play_time, :played_at, :started_at, :finished_at, :metascore, :average_playtime)
  end

  def attach_rawg_image
    return if params.dig(:game, :image).present?

    RawgApiService.attach_image(@game, params[:rawg_image_url]) if params[:rawg_image_url].present?
  end
end