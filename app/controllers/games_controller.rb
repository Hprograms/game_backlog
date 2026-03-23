class GamesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game, only: [:show, :edit, :update, :destroy]

  def index
    @games = current_user.games.order(created_at: :desc)
  end

  def show
  end

  def new
    @game = current_user.games.build
  end

  def create
    @game = current_user.games.build(game_params)
    if @game.save
      redirect_to @game, notice: "ゲームを登録しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      redirect_to @game, notice: "更新しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    redirect_to games_path, notice: "削除しました！"
  end

  private

  def set_game
      @game = current_user.games.find_by(id: params[:id])
      if @game.nil?
        redirect_to games_path, alert: "ゲームが見つかりません"
      end
  end
  
  def game_params
    params.require(:game).permit(:title, :platform, :genre, :status, :memo, :rating, :purchased_at)
  end
end