class BackfillExpForExistingClearedGames < ActiveRecord::Migration[8.0]
  def up
    # 本番環境で実行された時だけ、既存のクリア済ゲームにEXPを付与する
    Game.where(status: "クリア済", exp_awarded_for_clear: false).find_each do |game|
      game.send(:award_exp_for_clear)
      Rails.logger.info "Game ID: #{game.id} のEXPを本番環境で付与しました"
    end
  end

  def down
    # ロールバック時の処理（今回はデータを戻す必要はないため空でOKです）
  end
end