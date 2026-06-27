/**
 * Firebase Cloud Functions - Push Notifications
 */

import * as admin from "firebase-admin";
import {
    onDocumentCreated,
    onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";

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
            const choyxona = choyxonaDoc.exists ? choyxonaDoc.data() : undefined;
            const choyxonaName = choyxona?.name || "choyxona";

            // Получатели: админы этой чайханы + владелец (если задан).
            // Уведомления формируются на сервере (Admin SDK), поэтому клиенту
            // не нужно ни читать чужие user-документы, ни писать в notifications.
            const recipients = new Set<string>();
            const adminsSnap = await db
                .collection("users")
                .where("choyxonaId", "==", choyxonaId)
                .where("role", "==", "choyxona_admin")
                .get();
            adminsSnap.forEach((d) => recipients.add(d.id));
            const ownerId = choyxona?.ownerId as string | undefined;
            if (ownerId) recipients.add(ownerId);

            await Promise.all(
                Array.from(recipients).map((uid) =>
                    db.collection("notifications").add({
                        userId: uid,
                        title: "Yangi bron! 🔔",
                        body: `${guestName} ${choyxonaName}da joy bron qildi.`,
                        data: {
                            type: "new_booking",
                            bookingId: event.params.bookingId,
                            choyxonaId: choyxonaId,
                        },
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    })
                )
            );

            console.log(`Booking notification sent to ${recipients.size} recipient(s)`);
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

            // Уведомляем клиента об изменении статуса (на сервере, чтобы клиент
            // не имел права писать в notifications напрямую).
            const userId = after.userId as string | undefined;
            const choyxonaName = (after.choyxonaName as string) || "Choyxona";
            const roomNumber = after.roomNumber as string | undefined;
            if (userId) {
                let title = "";
                let body = "";
                if (after.status === "confirmed") {
                    title = "Bron tasdiqlandi! ✅";
                    body = roomNumber
                        ? `${choyxonaName} · Xona ${roomNumber}`
                        : `${choyxonaName}dagi broningiz tasdiqlandi.`;
                } else if (after.status === "cancelled") {
                    title = "Bron rad etildi ❌";
                    body = `${choyxonaName}dagi broningiz bekor qilindi.`;
                } else if (after.status === "completed") {
                    title = "Tashrif yakunlandi 🎉";
                    body = "Tashrifingiz uchun rahmat! Xizmatimizni baholang.";
                }
                if (title) {
                    await db.collection("notifications").add({
                        userId: userId,
                        title: title,
                        body: body,
                        data: {
                            type: "booking_status_update",
                            bookingId: event.params.bookingId,
                            status: after.status,
                        },
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    console.log(`Status notification (${after.status}) sent to ${userId}`);
                }
            }
        } catch (error) {
            console.error("Error in onBookingStatusChanged:", error);
        }
    }
);

/**
 * Ежедневная очистка устаревших замков комнат (room_locks).
 * Замки храняться по дате (id = "{roomId}_{bookingDate}"). Замки прошедших дат
 * больше не нужны, поэтому удаляем их, чтобы коллекция не разрасталась и не
 * влияла на запросы занятости. Сравнение строк YYYY-MM-DD лексикографически
 * совпадает с хронологией. Только одно неравенство по одному полю — индекс не нужен.
 */
export const cleanupExpiredRoomLocks = onSchedule("every 24 hours", async () => {
    const now = new Date();
    const todayStr = now.toISOString().slice(0, 10); // YYYY-MM-DD (UTC)

    try {
        const snap = await db
            .collection("room_locks")
            .where("bookingDate", "<", todayStr)
            .get();

        if (snap.empty) {
            console.log("No expired room locks to clean up");
            return;
        }

        // Удаляем партиями по 400 (лимит batch — 500).
        const docs = snap.docs;
        for (let i = 0; i < docs.length; i += 400) {
            const batch = db.batch();
            docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
            await batch.commit();
        }
        console.log(`Cleaned up ${docs.length} expired room lock(s)`);
    } catch (error) {
        console.error("Error in cleanupExpiredRoomLocks:", error);
    }
});

/**
 * При создании заказа уведомляем нужную сторону на сервере (клиент не имеет
 * права писать в notifications). addedBy=client -> уведомляем админов чайханы;
 * addedBy=admin -> уведомляем клиента.
 */
export const onOrderCreated = onDocumentCreated(
    "orders/{orderId}",
    async (event) => {
        const order = event.data?.data();
        if (!order) return;

        const choyxonaId = order.choyxonaId as string | undefined;
        const addedBy = (order.addedBy as string) || "client";
        const total = order.total as number | undefined;
        if (!choyxonaId) return;

        try {
            if (addedBy === "client") {
                const recipients = new Set<string>();
                const adminsSnap = await db
                    .collection("users")
                    .where("choyxonaId", "==", choyxonaId)
                    .where("role", "==", "choyxona_admin")
                    .get();
                adminsSnap.forEach((d) => recipients.add(d.id));
                const choyxonaDoc = await db.collection("choyxonas").doc(choyxonaId).get();
                const ownerId = choyxonaDoc.data()?.ownerId as string | undefined;
                if (ownerId) recipients.add(ownerId);

                await Promise.all(
                    Array.from(recipients).map((uid) =>
                        db.collection("notifications").add({
                            userId: uid,
                            title: "Yangi taom buyurtmasi! 🍽️",
                            body: `Mijoz ${total ?? 0} so'mlik buyurtma berdi.`,
                            data: { type: "new_order", orderId: event.params.orderId, choyxonaId },
                            isRead: false,
                            createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        })
                    )
                );
            } else {
                const userId = order.userId as string | undefined;
                if (userId) {
                    await db.collection("notifications").add({
                        userId: userId,
                        title: "Taom buyurtmasi qo'shildi! 🍽️",
                        body: `Admin sizga ${total ?? 0} so'mlik taom qo'shdi.`,
                        data: { type: "order_added", orderId: event.params.orderId },
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            }
        } catch (error) {
            console.error("Error in onOrderCreated:", error);
        }
    }
);

/**
 * Server-authoritative создание брони (callable).
 * Клиент НЕ пишет в room_locks/bookings напрямую — это делает функция через
 * Admin SDK в транзакции, исключая подделку замков и DoS произвольными локами.
 * userId берётся из контекста аутентификации (не доверяем клиенту).
 */
export const createBooking = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "Tizimga kiring");
    }
    const d = request.data || {};

    const choyxonaId = String(d.choyxonaId || "");
    const bookingDate = String(d.bookingDate || ""); // YYYY-MM-DD
    const guestCount = Number(d.guestCount || 0);
    const guestName = String(d.guestName || "").trim();
    const guestPhone = String(d.guestPhone || "").replace(/[\s-]/g, "");
    const roomId = d.roomId ? String(d.roomId) : null;
    const roomNumber = d.roomNumber ? String(d.roomNumber) : null;

    // Валидация
    if (!choyxonaId || !bookingDate) {
        throw new HttpsError("invalid-argument", "Ma'lumot to'liq emas");
    }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(bookingDate)) {
        throw new HttpsError("invalid-argument", "Sana formati noto'g'ri");
    }
    const todayStr = new Date().toISOString().slice(0, 10);
    if (bookingDate < todayStr) {
        throw new HttpsError("invalid-argument", "O'tgan kunga bron qilib bo'lmaydi");
    }
    if (guestCount < 1 || guestCount > 20) {
        throw new HttpsError("invalid-argument", "Mehmonlar soni 1-20 oralig'ida");
    }
    if (guestName.length < 2) {
        throw new HttpsError("invalid-argument", "Ismni kiriting");
    }
    if (!/^\+998\d{9}$/.test(guestPhone)) {
        throw new HttpsError("invalid-argument", "Telefon noto'g'ri (+998XXXXXXXXX)");
    }

    try {
        const bookingId = await db.runTransaction(async (tx) => {
            // Замок комнаты (если выбрана) — детерминированный id гарантирует атомарность
            if (roomId) {
                const lockRef = db.collection("room_locks").doc(`${roomId}_${bookingDate}`);
                const lockSnap = await tx.get(lockRef);
                if (lockSnap.exists) {
                    throw new HttpsError(
                        "already-exists",
                        "Bu xona tanlangan kunga band. Boshqa xona yoki sana tanlang."
                    );
                }
                tx.set(lockRef, {
                    roomId,
                    choyxonaId,
                    bookingDate,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }

            const bookingRef = db.collection("bookings").doc();
            tx.set(bookingRef, {
                userId: uid,
                choyxonaId,
                choyxonaName: String(d.choyxonaName || ""),
                bookingDate,
                bookingTime: null,
                duration: Number(d.duration || 480),
                guestCount,
                guestName,
                guestPhone,
                guestEmail: String(d.guestEmail || ""),
                specialRequests: String(d.specialRequests || ""),
                status: "pending",
                paymentStatus: "unpaid",
                paymentMethod: "cash",
                roomId: roomId,
                roomNumber: roomNumber,
                timeSlot: String(d.timeSlot || "morning"),
                hasOrder: false,
                isRated: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return bookingRef.id;
        });

        return { success: true, bookingId };
    } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("Error in createBooking:", error);
        throw new HttpsError("internal", "Bron yaratishda xatolik");
    }
});
