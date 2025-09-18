/*
  Firebase Cloud Messaging Service Worker for Flutter Web

  How to use:
  1) Replace the YOUR_* placeholders in firebaseConfig with your Firebase Web app config.
     These values are safe to expose on the web.
  2) Ensure your Flutter web app runs with matching --dart-define FIREBASE_* values so
     the main app initializes Firebase too (see flutter_app/README.md).
  3) For background notifications to work on web, this file must be present at
     /firebase-messaging-sw.js and the app must have Notification permission.
*/

/* eslint-disable no-undef */
// Import Firebase scripts (compat builds work with the messaging SW)
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

self.addEventListener('install', (event) => {
  // Activate worker immediately after installation
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  // Become available to all pages under the scope without reload
  event.waitUntil(self.clients.claim());
});

// TODO: Fill these from your Firebase project settings (Web app config)
const firebaseConfig = {
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  // Optional fields
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  measurementId: undefined,
};

let messaging = null;
try {
  if (
    firebaseConfig.apiKey && !firebaseConfig.apiKey.startsWith('YOUR_') &&
    firebaseConfig.appId && !firebaseConfig.appId.startsWith('YOUR_') &&
    firebaseConfig.messagingSenderId && !firebaseConfig.messagingSenderId.startsWith('YOUR_') &&
    firebaseConfig.projectId && !firebaseConfig.projectId.startsWith('YOUR_')
  ) {
    firebase.initializeApp(firebaseConfig);
    messaging = firebase.messaging();
  } else {
    // If not configured, background handling will be disabled; foreground still works in app.
    console.warn('[firebase-messaging-sw] Firebase config not set. Background messages disabled.');
  }
} catch (e) {
  console.error('[firebase-messaging-sw] Initialization failed:', e);
}

// Handle background messages (data-only or missing notification payload)
if (messaging) {
  messaging.onBackgroundMessage((payload) => {
    // If the payload contains a notification, the browser may handle display automatically.
    // For data-only payloads, show a basic notification here.
    const title = (payload.notification && payload.notification.title) || payload.data?.title || 'Update';
    const body = (payload.notification && payload.notification.body) || payload.data?.body || '';
    const data = payload.data || {};

    // Basic options; advanced features like custom sounds aren't supported on web notifications
    const options = {
      body,
      data,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      // tag can prevent notification stacking when same event repeats
      tag: data.tag || undefined,
    };
    try {
      self.registration.showNotification(title, options);
    } catch (e) {
      // noop; browser might auto-display if notification key was provided
    }
  });
}
