const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/** 全プッシュに付与。iOS フォアグラウンドではローカル通知と二重にならないよう AppDelegate で非表示にする */
const CF_DATA = { gifty_cf: "1" };

const apnsSound = {
  payload: {
    aps: {
      sound: "default",
    },
  },
};

/**
 * @param {string} token
 * @param {string} title
 * @param {string} body
 */
async function sendPush(token, title, body) {
  const trimmed = (token || "").trim();
  if (!trimmed) return false;
  const message = {
    notification: { title, body },
    data: CF_DATA,
    token: trimmed,
    apns: apnsSound,
  };
  await admin.messaging().send(message);
  return true;
}

/**
 * 新規タスク（主に status=pending で相手へ届く）→ 受信者へプッシュ
 */
exports.onTaskCreated = onDocumentCreated(
  { document: "tasks/{taskId}", region: "us-central1" },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.status !== "pending") return;

    const receiverId = data.receiver_id;
    if (!receiverId || typeof receiverId !== "string") return;

    const receiverDoc = await db.collection("users").doc(receiverId).get();
    const token = receiverDoc.exists
      ? (receiverDoc.data().fcm_token || "").trim()
      : "";
    if (!token) {
      console.log("onTaskCreated: no fcm_token for receiver", receiverId);
      return;
    }

    let senderName = "ユーザー";
    const sn = data.sender_name;
    if (sn && typeof sn === "string" && sn.trim()) senderName = sn.trim();
    const titleStr = (data.title && String(data.title).trim()) || "タスク";

    try {
      await sendPush(
        token,
        "新着タスク",
        `${senderName}さんから「${titleStr}」が届きました`
      );
      console.log("onTaskCreated: push to receiver", receiverId);
    } catch (e) {
      console.error("onTaskCreated: send failed", e.message);
    }
  }
);

/**
 * タスク削除 → 受信者へ（送信者が取り消した／いずれかが削除した場合も通知）
 */
exports.onTaskDeleted = onDocumentDeleted(
  { document: "tasks/{taskId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    const receiverId = data.receiver_id;
    if (!receiverId || typeof receiverId !== "string") return;

    const receiverDoc = await db.collection("users").doc(receiverId).get();
    const token = receiverDoc.exists
      ? (receiverDoc.data().fcm_token || "").trim()
      : "";
    if (!token) {
      console.log("onTaskDeleted: no fcm_token for receiver", receiverId);
      return;
    }

    const titleStr = (data.title && String(data.title).trim()) || "タスク";
    try {
      await sendPush(
        token,
        "タスクが取り消されました",
        `「${titleStr}」は送信者により削除されました。`
      );
      console.log("onTaskDeleted: push to receiver", receiverId);
    } catch (e) {
      console.error("onTaskDeleted: send failed", e.message);
    }
  }
);

/**
 * ルーティン提案が作成された（pending）→ 受信者へプッシュ
 */
exports.onRoutineSuggestionCreated = onDocumentCreated(
  { document: "routine_suggestions/{suggestionId}", region: "us-central1" },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.status !== "pending") return;

    const receiverId = data.receiver_id;
    if (!receiverId || typeof receiverId !== "string") return;

    const receiverDoc = await db.collection("users").doc(receiverId).get();
    const token = receiverDoc.exists
      ? (receiverDoc.data().fcm_token || "").trim()
      : "";
    if (!token) {
      console.log(
        "onRoutineSuggestionCreated: no fcm_token for receiver",
        receiverId
      );
      return;
    }

    let senderName = "ユーザー";
    const sn = data.sender_name;
    if (sn && typeof sn === "string" && sn.trim()) senderName = sn.trim();
    const titleStr = (data.title && String(data.title).trim()) || "ルーティン";

    try {
      await sendPush(
        token,
        "ルーティン提案",
        `${senderName}さんから「${titleStr}」の提案が届きました`
      );
      console.log("onRoutineSuggestionCreated: push to receiver", receiverId);
    } catch (e) {
      console.error("onRoutineSuggestionCreated: send failed", e.message);
    }
  }
);

/**
 * タスクドキュメント更新時に、status に応じて FCM プッシュを送信する。
 * - pending_approval になったとき → 送信者に「完了報告」
 * - completed になったとき → 受信者に「承認・ギフト解禁」
 */
exports.onTaskUpdated = onDocumentUpdated(
  { document: "tasks/{taskId}", region: "us-central1" },
  async (event) => {
    const snapBefore = event.data?.before;
    const snapAfter = event.data?.after;
    if (!snapBefore || !snapAfter) return;
    const before = snapBefore.data();
    const after = snapAfter.data();

    // pending_approval に変わった → 送信者に通知
    if (
      after.status === "pending_approval" &&
      before.status !== "pending_approval"
    ) {
      const senderId = after.sender_id;
      const receiverId = after.receiver_id;
      if (!senderId) return;

      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderToken = senderDoc.exists
        ? (senderDoc.data().fcm_token || "").trim()
        : "";
      if (!senderToken) {
        console.log("onTaskUpdated: no fcm_token for sender", senderId);
        return;
      }

      let receiverDisplayName = "受信者";
      if (receiverId) {
        const receiverDoc = await db.collection("users").doc(receiverId).get();
        if (receiverDoc.exists) {
          const name = receiverDoc.data().display_name;
          if (name && typeof name === "string" && name.trim())
            receiverDisplayName = name.trim();
        }
      }

      const titleStr =
        (after.title && String(after.title).trim()) || "タスク";
      const message = {
        notification: {
          title: "完了報告",
          body: `${receiverDisplayName}さんが「${titleStr}」の完了報告を送りました。承認してください。`,
        },
        data: CF_DATA,
        token: senderToken,
        apns: apnsSound,
      };

      try {
        await admin.messaging().send(message);
        console.log("onTaskUpdated: sent completion report push to sender", senderId);
      } catch (e) {
        console.error("onTaskUpdated: send to sender failed", e.message);
      }
      return;
    }

    // completed に変わった → 受信者に通知
    if (after.status === "completed" && before.status !== "completed") {
      const receiverId = after.receiver_id;
      if (!receiverId) return;

      const receiverDoc = await db.collection("users").doc(receiverId).get();
      const receiverToken = receiverDoc.exists
        ? (receiverDoc.data().fcm_token || "").trim()
        : "";
      if (!receiverToken) {
        console.log("onTaskUpdated: no fcm_token for receiver", receiverId);
        return;
      }

      const taskTitle =
        (after.title && String(after.title).trim()) || "タスク";
      const giftName =
        (after.gift_name && String(after.gift_name).trim()) || "ギフト";
      const message = {
        notification: {
          title: "ギフトが解放されました",
          body: `「${taskTitle}」が承認されました。「${giftName}」をギフトBOXで確認できます。`,
        },
        data: CF_DATA,
        token: receiverToken,
        apns: apnsSound,
      };

      try {
        await admin.messaging().send(message);
        console.log("onTaskUpdated: sent approval push to receiver", receiverId);
      } catch (e) {
        console.error("onTaskUpdated: send to receiver failed", e.message);
      }
    }
  }
);
