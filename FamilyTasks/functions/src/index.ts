import * as admin from "firebase-admin";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

function statusLabel(status: string): string {
  switch (status) {
    case "completed":
      return "выполнено";
    case "declined":
      return "не выполнено";
    default:
      return "открыта";
  }
}

async function getSpaceMemberUids(spaceId: string): Promise<string[]> {
  const spaceDoc = await db.collection("spaces").doc(spaceId).get();
  return (spaceDoc.data()?.memberUids as string[]) ?? [];
}

async function getFcmTokens(uid: string): Promise<string[]> {
  const userDoc = await db.collection("users").doc(uid).get();
  return (userDoc.data()?.fcmTokens as string[]) ?? [];
}

async function sendToUser(uid: string, title: string, body: string): Promise<void> {
  const tokens = await getFcmTokens(uid);
  if (tokens.length === 0) return;
  await messaging.sendEachForMulticast({
    tokens,
    notification: {title, body},
  });
}

async function notifyOtherMember(spaceId: string, excludeUid: string, title: string, body: string): Promise<void> {
  const memberUids = await getSpaceMemberUids(spaceId);
  const recipient = memberUids.find((uid) => uid !== excludeUid);
  if (recipient) await sendToUser(recipient, title, body);
}

export const onTaskCreate = onDocumentCreated("spaces/{spaceId}/tasks/{taskId}", async (event) => {
  const task = event.data?.data();
  if (!task) return;
  await sendToUser(task.assignedTo, "Новая задача", task.title);
});

export const onTaskUpdate = onDocumentUpdated("spaces/{spaceId}/tasks/{taskId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || !event.data) return;

  const spaceId = event.params.spaceId;
  const taskRef = event.data.after.ref;

  if (before.status !== after.status) {
    const eventsSnap = await taskRef.collection("events")
      .where("type", "==", "status_changed")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();
    const byUid = eventsSnap.docs[0]?.data()?.byUid ?? after.assignedTo;
    await notifyOtherMember(spaceId, byUid, "Статус задачи изменён", `«${after.title}»: ${statusLabel(after.status)}`);
  }

  const beforeDueAt = before.dueAt?.toMillis?.();
  const afterDueAt = after.dueAt?.toMillis?.();
  if (beforeDueAt !== afterDueAt) {
    const eventsSnap = await taskRef.collection("events")
      .where("type", "==", "date_changed")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();
    const lastEvent = eventsSnap.docs[0]?.data();
    const byUid = lastEvent?.byUid ?? after.assignedTo;
    const reason = lastEvent?.reason ?? "";
    const body = reason ? `«${after.title}»: ${reason}` : `«${after.title}»`;
    await notifyOtherMember(spaceId, byUid, "Дата перенесена", body);
  }
});

export const onCommentCreate = onDocumentCreated(
  "spaces/{spaceId}/tasks/{taskId}/comments/{commentId}",
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;

    const spaceId = event.params.spaceId;
    await notifyOtherMember(spaceId, comment.authorUid, "Новый комментарий", comment.text);
  }
);
