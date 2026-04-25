importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyDXL3ilirCKrif-_HS9CIa_ELr1avgQF8E",
  authDomain: "lenchat-fc7be.firebaseapp.com",
  databaseURL: "https://lenchat-fc7be-default-rtdb.firebaseio.com",
  projectId: "lenchat-fc7be",
  storageBucket: "lenchat-fc7be.firebasestorage.app",
  messagingSenderId: "28641557685",
  appId: "1:28641557685:web:7e6577449c7db9cb9f92fc",
  measurementId: "G-ZRM88WCDC2"
};

const messaging = firebase.messaging();

// معالجة الرسائل في الخلفية للويب
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png' // اختياري
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});