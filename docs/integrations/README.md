# Firebase Cloud Functions implementation

Use this example for a product whose backend is Firebase Cloud Functions v2
and whose records are in Firestore. The [shared connection guide](../product-connection.md)
defines the HTTP and data contract. This file explains only the Firebase
implementation. No Supabase URL, Supabase SDK, LMS SQL, or Express
`backend/server.js` is involved.

## 1. Add the function

Copy [`crmSnapshot.example.js`](./crmSnapshot.example.js) into the Firebase
functions source. If the product's entry point is `functions/index.js`, copy
the code there or export the `crmSnapshot` function from its own module in
`index.js`. Install `firebase-functions` and `firebase-admin` in the
functions package if they are not already dependencies. The example uses
CommonJS, matching a standard JavaScript functions project; adapt imports
and exports if that project uses TypeScript or ESM.

Complete **all** `CHANGE ME` markers before deployment:

| Marker | Replace with |
| --- | --- |
| 1 | The exact CRM product slug and display name. |
| 2 | The Firestore collection containing customer accounts. If accounts are spread across collections, replace `loadCustomerPage` with a stable indexed query over the correct source. |
| 3 | Product-wide customer, active customer, and unresolved support ticket totals. |
| 4 | Completed **product subscription** revenue grouped by currency. Exclude fees or unrelated transactions. |
| 5 | Batched lookups of primary admins, latest completed subscription payments, and unresolved ticket counts for the page. Return Maps keyed by customer document ID. |
| 6 | The actual Firestore document fields for name, location, subscription, and dates. Convert Firestore Timestamps to ISO strings. |

The example throws for unimplemented queries so an unfinished integration
returns an error instead of invented zeros. Keep each page at 100 accounts or
fewer. Use Firestore indexes and aggregate or maintained summary records where
needed so the endpoint answers within the CRM's eight-second timeout.
See [Firestore query cursors](https://firebase.google.com/docs/firestore/query-data/query-cursors).

## 2. Add the dedicated read key

Use the dedicated read key supplied for this product. In the product's
Firebase project, set it as a Functions secret:

```sh
firebase functions:secrets:set CRM_READ_API_KEY
```

Enter the key when prompted. The function binds this secret through
`defineSecret` and `onRequest({ secrets: [...] })`; it is not a frontend
Firebase API key or a Firestore credential. See the
[Firebase Functions secrets documentation](https://firebase.google.com/docs/functions/config-env).
Do not commit the value to source control.

## 3. Deploy and connect CRM

```sh
firebase deploy --only functions:crmSnapshot
```

Copy the **full HTTPS function URL** from the deployment output and send it
to the CRM owner with the product slug. CRM calls that exact URL; it does not
append `/api/crm/v1/snapshot`. The function accepts `GET`, checks the
Bearer key, and returns the same JSON contract as the Express example. See
[Firebase HTTP functions](https://firebase.google.com/docs/functions/http-events).

## 4. Verify before handoff

Call the deployed function without a key and confirm `401`. With the key,
confirm `200` and compare totals, subscription revenue, payments, and
support tickets to Firestore. Check `limit=2` and follow `next_cursor`
without repeating accounts. Change one source record and confirm the next
request reflects it. Share the slug, endpoint URL, and a redacted sample
response with the CRM owner. Never share Firebase Admin credentials.

## 5. If a request fails

Use the `code` and `request_id` in the response to find the matching
`[CRM snapshot]` Cloud Function log. The
[shared troubleshooting table](../product-connection.md#troubleshooting-and-recovery)
explains every code. Common Firebase checks:

| Code | First check |
| --- | --- |
| `INTEGRATION_NOT_CONFIGURED` | The `CRM_READ_API_KEY` secret is bound to this deployed function and has a value of at least 32 characters. Redeploy after changing bindings. |
| `ADAPTER_INCOMPLETE` | Implement every `CHANGE ME` query; the example deliberately throws until then. |
| `INVALID_CURSOR` | Start again without a cursor. The Firestore customer document used as the previous cursor may have been deleted. |
| `SOURCE_UNAVAILABLE` | Read the logged Firebase error code. Check Firestore indexes, service account permissions, query limits, and source availability. Run the failing query on its own with a small page. |
| `INVALID_SNAPSHOT` | Use the logged field name. Convert Firestore Timestamps to ISO strings and return `null` for absent optional values. |

Keep source errors in server logs; the HTTP response carries only safe codes
and request IDs. Do not substitute stale or fabricated business totals.
