class GamesController < ApplicationController
  before_action :set_game, only: [ :show, :edit, :update, :destroy, :destroy_image ]

  def index
    @games = current_app_user.games.with_attached_image.order(created_at: :desc)
    @games = @games.where(status: params[:status]) if params[:status].present?

    # 全ゲーム数
    @total_count = current_app_user.games.count

    # 各ステータスごとのゲーム数を計算
    @cleared_count = current_app_user.games.where(status: "クリア済").count
    @playing_count = current_app_user.games.where(status: "プレイ中").count
    @unplayed_count = current_app_user.games.where(status: "未着手").count

    # クリア率の計算
    @clear_rate = @total_count > 0 ? (@cleared_count * 100 / @total_count) : 0
  end

  def show
  end

  def new
    @game = current_app_user.games.build
  end

  def create
    @game = current_app_user.games.build(game_params)
    if @game.description.present? && @game.description !~ /[\p{Hiragana}\p{Katakana}\p{Han}]/
      original_description = @game.description
      @game.description = IgdbApiService.translate_text(original_description).presence || original_description
    end

    if @game.save
      attach_igdb_image
      redirect_to @game, notice: "ゲームを登録しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      attach_igdb_image
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
    render json: params[:query].present? ? IgdbApiService.search(params[:query]) : []
  end


  private

  def set_game
      @game = current_app_user.games.find_by(id: params[:id])
      if @game.nil?
        redirect_to games_path, alert: "ゲームが見つかりません"
      end
  end

  def game_params
    params.require(:game).permit(:title, :platform, :genre, :status, :memo, :rating, :purchased_at, :image, :play_time, :play_time_hours, :play_time_minutes, :played_at, :started_at, :finished_at, :igdb_rating, :developer, :description)
  end

  def attach_igdb_image
    return if params.dig(:game, :image).present?

    IgdbApiService.attach_cover_image(@game, params[:igdb_image_url]) if params[:igdb_image_url].present?
  end
end
