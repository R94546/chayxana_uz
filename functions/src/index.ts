/**
 * Firebase Cloud Functions - Push Notifications
 */

import * as admin from "firebase-admin";
import {
    onDocumentCreated,
    onDocumentUpdated,
} from "firebase-functions/v2/firestore";

admin.initializeApp();

const db = admin.firestore();

/**
 * Notification yaratilganda push notification yuborish
 */
export const onNotificationCreated = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) {
            console.log("No data associated with the event");
            return;
        }

        const notification = snapshot.data();
        const userId = notification.userId as string;
        const title = notification.title as string;
        const body = notification.body as string;
        const data = notification.data as Record<string, string> || {};

        if (!userId) {
            console.log("No userId in notification");
            return;
        }

        try {
            const userDoc = await db.collection("users").doc(userId).get();

            if (!userDoc.exists) {
                console.log(`User ${userId} not found`);
                return;
            }

            const userData = userDoc.data();
            const deviceTokens = userData?.deviceTokens as string[] || [];

            if (deviceTokens.length === 0) {
                console.log(`User ${userId} has no device tokens`);
                return;
            }

            const message: admin.messaging.MulticastMessage = {
                tokens: deviceTokens,
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    ...data,
                    notificationId: event.params.notificationId,
                },
                android: {
                    notification: {
                        channelId: "high_importance_channel",
                        priority: "high",
                        defaultSound: true,
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
                webpush: {
                    notification: {
                        icon: "/icons/Icon-192.png",
                        badge: "/icons/Icon-192.png",
                    },
                    fcmOptions: {
                        link: "https://choyxona-uz-app.web.app",
                    },
                },
            };

            const response = await admin.messaging().sendEachForMulticast(message);
            console.log(`Sent ${response.successCount} messages to user ${userId}`);

            if (response.failureCount > 0) {
                const tokensToRemove: string[] = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.log(`Failed to send to token: ${resp.error?.message}`);
                        tokensToRemove.push(deviceTokens[idx]);
                    }
                });

                if (tokensToRemove.length > 0) {
                    await db.collection("users").doc(userId).update({
                        deviceTokens: admin.firestore.FieldValue.arrayRemove(
                            ...tokensToRemove
                        ),
                    });
                    console.log(`Removed ${tokensToRemove.length} invalid tokens`);
                }
            }

            await snapshot.ref.update({
                sent: true,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        } catch (error) {
            console.error("Error sending notification:", error);
            throw error;
        }
    }
);

/**
 * Yangi bron yaratilganda adminga notification
 */
export const onBookingCreated = onDocumentCreated(
    "bookings/{bookingId}",
    async (event) => {
        const snapshot = event.data;
        if (!snapshot) return;

        const booking = snapshot.data();
        const choyxonaId = booking.choyxonaId as string;
        const guestName = booking.guestName as string || "Mehmon";
        const status = booking.status as string;

        if (status !== "pending") return;

        // Денормализованные счётчики (admin SDK обходит правила; клиент не имеет
        // прав на choyxonas.update, поэтому инкремент перенесён сюда из транзакции).
        try {
            await db.collection("choyxonas").doc(choyxonaId).update({
                bookingCount: admin.firestore.FieldValue.increment(1),
            });
            const userId = booking.userId as string | undefined;
            if (userId) {
                await db.collection("users").doc(userId).update({
                    totalBookings: admin.firestore.FieldValue.increment(1),
                });
            }
        } catch (error) {
            console.error("Error incrementing booking counters:", error);
        }

        try {
            const choyxonaDoc = await db.collection("choyxonas").doc(choyxonaId).get();
            if (!choyxonaDoc.exists) return;

            const choyxona = choyxonaDoc.data();
            const ownerId = choyxona?.ownerId as string;
            if (!ownerId) return;

            await db.collection("notifications").add({
                userId: ownerId,
                title: "Yangi bron! 🔔",
                body: `${guestName} ${choyxona?.name || "choyxona"}da joy bron qildi.`,
                data: {
                    type: "new_booking",
                    bookingId: event.params.bookingId,
                    choyxonaId: choyxonaId,
                },
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`Created notification for owner ${ownerId}`);
        } catch (error) {
            console.error("Error in onBookingCreated:", error);
        }
    }
);

/**
 * При изменении брони:
 *  - status -> cancelled: освобождаем замок комнаты (room_locks)
 *  - status pending -> confirmed: уведомляем клиента
 */
export const onBookingStatusChanged = onDocumentUpdated(
    "bookings/{bookingId}",
    async (event) => {
        const before = event.data?.before.data();
        const after = event.data?.after.data();
        if (!before || !after) return;

        if (before.status === after.status) return; // статус не менялся

        const roomId = after.roomId as string | undefined;
        const bookingDate = after.bookingDate as string | undefined;

        try {
            // Освобождаем замок комнаты при отмене
            if (after.status === "cancelled" && roomId && bookingDate) {
                await db
                    .collection("room_locks")
                    .doc(`${roomId}_${bookingDate}`)
                    .delete()
                    .catch(() => undefined);
                console.log(`Released room lock ${roomId}_${bookingDate}`);
            }

            // Уведомляем клиента о подтверждении
            if (before.status === "pending" && after.status === "confirmed") {
                const userId = after.userId as string;
                if (userId) {
                    await db.collection("notifications").add({
                        userId: userId,
                        title: "Bron tasdiqlandi! ✅",
                        body: `${after.choyxonaName || "Choyxona"}dagi broningiz tasdiqlandi.`,
                        data: {
                            type: "booking_confirmed",
                            bookingId: event.params.bookingId,
                        },
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log(`Confirmation notification sent to ${userId}`);
                }
            }
        } catch (error) {
            console.error("Error in onBookingStatusChanged:", error);
        }
    }
);
