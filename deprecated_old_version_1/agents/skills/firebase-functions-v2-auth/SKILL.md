---
name: firebase-functions-v2-auth
description: Troubleshooting Guide for 401 Unauthorized errors in Firebase Functions v2 when calling onRequest HTTP endpoints directly.
---

# Firebase Functions Gen 2 Auth Fix (401 Unauthorized)

## The Issue 

When using `onRequest` with Firebase Functions v2 (deployed on Google Cloud Run), the underlying Cloud Run service defaults to denying "unauthenticated" invocations. 

If your Flutter application or any other client makes direct HTTP or SSE (Server-Sent Events) requests to this URL bypassing the Firebase SDK (for instance, using `Dio`, `http` or `fetch` directly with an `Authorization: Bearer <Firebase_ID_Token>` header), **the request will be blocked by Cloud Run at the load balancer** and reject the connection returning an HTML 401 Unauthorized page: `Your client does not have permission to the requested URL`. 

Since the request gets rejected by Cloud IAM, it won't even reach your custom `verifyAuth` logic or the Node.js function itself.

## The Fix

To ensure these custom HTTP requests are permitted to reach the Node function where the Firebase Auth token can be properly validated locally (using Firebase Admin SDK), you must instruct Firebase Functions / Cloud Run to allow **public unauthenticated invocation**.

You must set the `invoker: "public"` option inside every `onRequest` definition that needs to be accessed by a client over HTTP using custom Auth headers.

### Example

**INCORRECT**
```typescript
import { onRequest } from "firebase-functions/v2/https";

export const chatHttp = onRequest(
  { cors: true, memory: "512MiB" },
  async (req, res) => {
    // This will never be reached because of the Cloud Run 401 blocker.
    await verifyAuth(req, res, () => {});
    // ...
  }
);
```

**CORRECT**
```typescript
import { onRequest } from "firebase-functions/v2/https";

export const chatHttp = onRequest(
  { cors: true, memory: "512MiB", invoker: "public" }, // <-- ADD THIS
  async (req, res) => {
    // Request successfully hits the function and verifyAuth safely validates the token.
    await verifyAuth(req, res, () => {});
    // ...
  }
);
```
