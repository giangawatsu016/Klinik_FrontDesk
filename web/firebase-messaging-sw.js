importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: 'AIzaSyBVkFmgS634G0gRXvEseiW_a164uyw2Lmg',
    appId: '1:171721344232:web:3cf9ee6d9f254be8fc755d',
    messagingSenderId: '171721344232',
    projectId: 'homecare-eb529',
    authDomain: 'homecare-eb529.firebaseapp.com',
    storageBucket: 'homecare-eb529.firebasestorage.app',
    measurementId: 'G-2FWLN3G6PZ',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
