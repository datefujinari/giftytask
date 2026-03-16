const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * タスクドキュメント更新時に、status に応じて FCM プッシュを送信する。
 * - pending_approval になったとき → 送信者に「〇〇さんがタスクを完了しました！承認してください」
 * - completed になったとき → 受信者に「おめでとう！タスクが承認され、ギフトが解禁されました！」
 */
exports.onTaskUpdated = onDocumentUpdated(
  { document: "tasks/{taskId}", region: "us-central1" },
  async (event) => {
    const snapBefore = event.data?.before;
    const snapAfter = event.data?.after;
    if (!snapBefore || !snapAfter) return;
    const before = snapBefore.data();
    const after = snapAfter.data();
    const taskId = event.params.taskId;

    // pending_approval に変わった → 送信者に通知
    if (after.status === "pending_approval" && before.status !== "pending_approval") {
      const senderId = after.sender_id;
      const receiverId = after.receiver_id;
      if (!senderId) return;

      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderToken = senderDoc.exists ? (senderDoc.data().fcm_token || "").trim() : "";
      if (!senderToken) {
        console.log("onTaskUpdated: no fcm_token for sender", senderId);
        return;
      }

      let receiverDisplayName = "受信者";
      if (receiverId) {
        const receiverDoc = await db.collection("users").doc(receiverId).get();
        if (receiverDoc.exists) {
          const name = receiverDoc.data().display_name;
          if (name && typeof name === "string" && name.trim()) receiverDisplayName = name.trim();
        }
      }

      const message = {
        notification: {
          title: "完了報告",
          body: `${receiverDisplayName}さんがタスクを完了しました！承認してください`,
        },
        token: senderToken,
        apns: {
          payload: { aps: { sound: "default" } },
        },
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
      const receiverToken = receiverDoc.exists ? (receiverDoc.data().fcm_token || "").trim() : "";
      if (!receiverToken) {
        console.log("onTaskUpdated: no fcm_token for receiver", receiverId);
        return;
      }

      const message = {
        notification: {
          title: "タスクが承認されました",
          body: "おめでとう！タスクが承認され、ギフトが解禁されました！",
        },
        token: receiverToken,
        apns: {
          payload: { aps: { sound: "default" } },
        },
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
