package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// CloudWatchAlarmMessage はSNS経由で届くCloudWatch AlarmのJSON構造体
type CloudWatchAlarmMessage struct {
	AlarmName        string `json:"AlarmName"`
	AlarmDescription string `json:"AlarmDescription"`
	NewStateValue    string `json:"NewStateValue"`
	NewStateReason   string `json:"NewStateReason"`
	Region           string `json:"Region"`
}

// DiscordWebhookPayload はDiscord Webhook APIにPOSTするJSON構造体
type DiscordWebhookPayload struct {
	Username string         `json:"username"`
	Embeds   []DiscordEmbed `json:"embeds"`
}

type DiscordEmbed struct {
	Title       string              `json:"title"`
	Description string              `json:"description"`
	Color       int                 `json:"color"`
	Fields      []DiscordEmbedField `json:"fields"`
	Timestamp   string              `json:"timestamp"`
}

type DiscordEmbedField struct {
	Name   string `json:"name"`
	Value  string `json:"value"`
	Inline bool   `json:"inline"`
}

func handler(ctx context.Context, rawEvent json.RawMessage) error {
	webhookURL := os.Getenv("DISCORD_WEBHOOK_URL")
	if webhookURL == "" {
		return fmt.Errorf("環境変数 DISCORD_WEBHOOK_URL が設定されていません")
	}

	// 1. SNSイベントとしてパースを試みる
	var snsEvent events.SNSEvent
	var alarmMsg CloudWatchAlarmMessage
	isAlarmParsed := false

	if err := json.Unmarshal(rawEvent, &snsEvent); err == nil && len(snsEvent.Records) > 0 {
		rawMsg := snsEvent.Records[0].SNS.Message
		if err := json.Unmarshal([]byte(rawMsg), &alarmMsg); err == nil && alarmMsg.AlarmName != "" {
			isAlarmParsed = true
		} else {
			// SNS経由だがCloudWatch Alarm以外のテキストメッセージだった場合
			alarmMsg = CloudWatchAlarmMessage{
				AlarmName:      snsEvent.Records[0].SNS.Subject,
				NewStateValue:  "INFO",
				NewStateReason: rawMsg,
				Region:         "ap-northeast-1",
			}
			isAlarmParsed = true
		}
	}

	// 2. コンソールのテスト実行などSNS以外のペイロードだった場合のフォールバック
	if !isAlarmParsed {
		alarmMsg = CloudWatchAlarmMessage{
			AlarmName:      "Lambda単体テスト通知",
			NewStateValue:  "TEST",
			NewStateReason: string(rawEvent),
			Region:         "ap-northeast-1",
		}
	}

	// 3. ステータスに応じたカラーコード設定（赤: ALARM / 緑: OK / 青: その他）
	color := 3447003 // 青
	statusEmoji := "ℹ️"
	switch alarmMsg.NewStateValue {
	case "ALARM":
		color = 15158332 // 赤
		statusEmoji = "🚨"
	case "OK":
		color = 3066993 // 緑
		statusEmoji = "✅"
	}

	payload := DiscordWebhookPayload{
		Username: "ツミクエスト AWS監視Bot",
		Embeds: []DiscordEmbed{
			{
				Title:       fmt.Sprintf("%s [%s] %s", statusEmoji, alarmMsg.NewStateValue, alarmMsg.AlarmName),
				Description: alarmMsg.AlarmDescription,
				Color:       color,
				Fields: []DiscordEmbedField{
					{
						Name:   "詳細・検知理由",
						Value:  truncateString(alarmMsg.NewStateReason, 1000),
						Inline: false,
					},
					{
						Name:   "リージョン",
						Value:  alarmMsg.Region,
						Inline: true,
					},
				},
				Timestamp: time.Now().UTC().Format(time.RFC3339),
			},
		},
	}

	return sendToDiscord(ctx, webhookURL, payload)
}

func sendToDiscord(ctx context.Context, webhookURL string, payload DiscordWebhookPayload) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("JSONエンコード失敗: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, webhookURL, bytes.NewBuffer(body))
	if err != nil {
		return fmt.Errorf("HTTPリクエスト作成失敗: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("DiscordへのPOST送信失敗: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		respBody, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("Discord APIエラー (status=%d): %s", resp.StatusCode, string(respBody))
	}

	return nil
}

func truncateString(s string, maxLen int) string {
	if s == "" {
		return "（詳細なし）"
	}
	runes := []rune(s)
	if len(runes) <= maxLen {
		return s
	}
	return string(runes[:maxLen]) + "..."
}

func main() {
	lambda.Start(handler)
}