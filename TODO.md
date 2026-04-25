# Firebase Messages Not Saving Fix Plan

## Steps:
- [x] Create this TODO.md
- [x] Update lib/main.dart: Add FirebaseOptions to initializeApp
- [x] Enhance error handling in lib/view/Chat/chat_room_page.dart
- [x] Added UI fixes: Auto-scroll to bottom, update room metadata on send, safe keys
- [ ] Update Firestore Rules (Firebase Console → Firestore → Rules):
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /chatRooms/{roomId} {
        allow read, write: if request.auth != null;
      }
      match /chatRooms/{roomId}/messages/{msgId} {
        allow read, write: if request.auth != null;
      }
      match /users/{userId} {
        allow read, write: if request.auth != null;
      }
    }
  }
  ```
- [ ] Verify messages appear in Firestore Data tab

Progress: Rules fix likely solves silent fails (no console errors confirm permission denial).

