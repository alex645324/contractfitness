# Tips & Tricks

## Real-Time UI Updates Without Page Refresh

Use Firestore's `.snapshots()` stream instead of `.get()` one-time fetch. Wrap your UI in a `StreamBuilder` that listens to the stream—when any user updates the data, Firestore automatically broadcasts the change to all connected clients, and `StreamBuilder` rebuilds the widget with the new data. No polling or manual refresh needed.
