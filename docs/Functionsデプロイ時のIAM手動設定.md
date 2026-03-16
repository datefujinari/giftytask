# Functions デプロイ時の IAM 手動設定

2nd Gen Cloud Functions のデプロイには、次の IAM ロールが必要です。  
Firebase CLI が自動で付与できない場合は、**Google Cloud のオーナー権限があるアカウント**で、以下のコマンドを**ターミナルで順に実行**してください。

## 前提

- **Google Cloud CLI（gcloud）** がインストールされていること  
  - 未導入の場合: https://cloud.google.com/sdk/docs/install  
  - または `brew install google-cloud-sdk`（macOS）
- `gcloud auth login` でログインし、**プロジェクトのオーナー**（または IAM を変更できるロール）で実行すること

## 実行するコマンド（プロジェクト ID が giftytask の場合）

```bash
# 1. プロジェクトを指定
gcloud config set project giftytask

# 2. 必要な IAM を付与（4 本）
gcloud projects add-iam-policy-binding giftytask \
  --member=serviceAccount:service-301876516785@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator

gcloud projects add-iam-policy-binding giftytask \
  --member=serviceAccount:301876516785-compute@developer.gserviceaccount.com \
  --role=roles/run.invoker

gcloud projects add-iam-policy-binding giftytask \
  --member=serviceAccount:301876516785-compute@developer.gserviceaccount.com \
  --role=roles/eventarc.eventReceiver

# Eventarc Service Agent（2nd Gen で "Permission denied while using the Eventarc Service Agent" が出る場合）
gcloud projects add-iam-policy-binding giftytask \
  --member=serviceAccount:service-301876516785@gcp-sa-eventarc.iam.gserviceaccount.com \
  --role=roles/eventarc.serviceAgent
```

## 実行後

以下で再度デプロイしてください。

```bash
cd /Users/itoutatsuya/kaihatu/taskapp
npx firebase-tools deploy --only functions
```

## プロジェクト ID が違う場合

Firebase Console の「プロジェクトの設定」で表示されている**プロジェクト ID** が `giftytask` でない場合は、上記の `giftytask` をその ID に置き換えて実行してください。
