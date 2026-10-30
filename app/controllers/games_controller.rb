class GamesController < ApplicationController
  before_action :set_game, only: [ :show, :edit, :update, :destroy, :destroy_image ]
  before_action :set_timer_game, only: :timer_update

  def index
    load_index_data(params[:status])
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

    @previous_level = current_app_user.level
    @previous_exp = current_app_user.exp
    if @game.save
      attach_igdb_image
      if @game.earned_exp_results.present?
        current_app_user.reload
        session[:exp_result_data] = {
          game_title: @game.title,
          previous_level: @previous_level,
          previous_exp: @previous_exp,
          new_level: current_app_user.level,
          new_exp: current_app_user.exp,
          results: @game.earned_exp_results
        }
      end
      redirect_to @game, notice: "ゲームを保存しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @previous_level = current_app_user.level
    @previous_exp = current_app_user.exp
    if @game.update(game_params)
      attach_igdb_image
      if @game.earned_exp_results.present?
        current_app_user.reload
        session[:exp_result_data] = {
          game_title: @game.title,
          previous_level: @previous_level,
          previous_exp: @previous_exp,
          new_level: current_app_user.level,
          new_exp: current_app_user.exp,
          results: @game.earned_exp_results
        }
      end
      redirect_to @game, notice: "ゲームを保存しました。"
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

  def timer_update
    begin
      play_time_minutes = Integer(params[:play_time_minutes])
    rescue ArgumentError, TypeError
      return head :unprocessable_entity
    end

    status = params[:status]

    unless play_time_minutes >= 0 &&
        (status.blank? || %w[backlog playing cleared 未着手 プレイ中 クリア済].include?(status))
      return head :unprocessable_entity
    end

    @previous_level = current_app_user.level
    @previous_exp = current_app_user.exp
    @game.play_time = (@game.play_time || 0) + play_time_minutes
    @game.status = "クリア済" if %w[cleared クリア済].include?(status)
    @game.used_timer = true

    unless @game.save
      return render plain: @game.errors.full_messages.to_sentence, status: :unprocessable_entity
    end

    @new_level = current_app_user.reload.level
    @new_exp = current_app_user.exp
    load_index_data(params[:filter_status])
    render :exp_result, formats: :turbo_stream
  end


  private

  def load_index_data(status)
    games = current_app_user.games.with_attached_image.order(created_at: :desc)
    @filter_status = status
    @games = status.present? ? games.where(status: status) : games
    @total_count = current_app_user.games.count
    @cleared_count = current_app_user.games.where(status: "クリア済").count
    @playing_count = current_app_user.games.where(status: "プレイ中").count
    @unplayed_count = current_app_user.games.where(status: "未着手").count
    @clear_rate = @total_count.positive? ? (@cleared_count * 100 / @total_count) : 0
  end

  def set_timer_game
    @game = current_app_user.games.find_by(id: params[:id])
    head :not_found unless @game
  end

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
