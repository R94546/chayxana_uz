importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyBeoTm7QCDXCFrLpKraTB2nf_fzvIqCgZg",
    authDomain: "choyxona-uz-app.firebaseapp.com",
    projectId: "choyxona-uz-app",
    storageBucket: "choyxona-uz-app.firebasestorage.app",
    messagingSenderId: "693886142798",
    appId: "1:693886142798:web:0c1fcc0a063ced0596f61f"
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);

    const notificationTitle = payload.notification?.title || 'Choyxona UZ';
    const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data: payload.data
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
