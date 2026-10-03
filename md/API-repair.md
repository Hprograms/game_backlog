積みゲー管理アプリの外部API連携を、RAWGから「IGDB API ＋ DeepL API（翻訳）」のハイブリッド構成へ移行します。以下の要件に従って、順番にコードを修正・作成してください。

## 1. DBマイグレーションの作成
以下のカラム変更を行うマイグレーションファイルを生成してください。
* 削除: `average_playtime` (integer), `metascore` (integer) または (string)
* 追加: `igdb_rating` (integer), `developer` (string), `description` (text)

## 2. IgdbApiService の新規作成
`app/services/igdb_api_service.rb` を作成し、クラスメソッド `search(query)` を実装してください。
* **Twitch OAuth認証**: `ENV['IGDB_CLIENT_ID']` と `ENV['IGDB_CLIENT_SECRET']` を使い、`https://id.twitch.tv/oauth2/token` にPOSTしてアクセストークンを取得。`Rails.cache.fetch` を使い、有効期限内はキャッシュを再利用すること。
* **IGDB検索 (Apicalypse)**: `https://api.igdb.com/v4/games` へPOST。
  * ヘッダー: `Client-ID: <ID>`, `Authorization: Bearer <Token>`
  * body: `search "#{query}"; fields name, cover.url, platforms.name, genres.name, involved_companies.company.name, summary, total_rating; limit 5;`
* **データ整形**:
  * `total_rating` は `round` で整数にする。
  * `cover.url` は先頭に `https:` を補完し、`t_thumb` を `t_cover_big` に置換する。
  * `developer` は `involved_companies` から会社名を1つ抽出する。
* **DeepL翻訳連携**: `summary`（英語のあらすじ）が存在する場合、`https://api-free.deepl.com/v2/translate` へPOST（ヘッダー: `Authorization: DeepL-Auth-Key #{ENV['DEEPL_API_KEY']}`）。`target_lang: 'JA'` で翻訳し、その結果を `description` としてハッシュに含める。翻訳エラー時は原文を返すこと。

## 3. コントローラーの修正
`games_controller.rb` を以下のように更新してください。
* `search` アクションで `RawgApiService.search` の代わりに `IgdbApiService.search` を呼び出す。
* `game_params` の許可リストから古いカラムを削除し、`igdb_rating`, `developer`, `description` を追加する。

## 4. フォーム画面とStimulusの改修
* `app/views/games/_form.html.erb`: タイトル入力欄の下にあったRAWGバッジ表示用のエリア（`.api-metadata` など）を完全に削除する。また、古い hidden_field を削除し、新たに `igdb_rating`, `developer`, `description` の hidden_field を追加する。
* `app/javascript/controllers/game_form_controller.js`: サジェストからゲームを選択した際、バッジのテキストを書き換えるUI処理をすべて削除し、上記3つの新しい hidden_field にIGDBから取得したデータをセットする処理だけを残す。