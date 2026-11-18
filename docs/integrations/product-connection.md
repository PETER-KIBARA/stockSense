# Connect Your Product to Cloudora CRM

Expose one read-only HTTPS endpoint on your product's backend. CRM calls it, reads a JSON snapshot, and shows it on the **Product connections** page.

- You keep your own framework, database and queries.
- CRM never connects to your database.
- No shared SQL migration is needed. (The LMS migration is LMS-only. Don't run it on your database.)

---

## How it works

```
CRM  ──GET /your-endpoint (Bearer key)──▶  Your backend  ──queries──▶  Your database
CRM  ◀────────── JSON snapshot ───────────  Your backend
```

---

## Pick your stack

| Your backend | Go to |
| --- | --- |
| Express (any database, including Firebase Admin) | [Express setup](#express-setup) |
| Firebase Cloud Functions + Firestore | [Firebase setup](#firebase-cloud-functions) |
| Anything else | [The endpoint contract](#the-endpoint-contract) and [Response format](#response-format) |

---

## Before you start

You need:

- Node 18+ and Express (Express setup only)
- The **product slug**: lowercase, 2–40 characters, letters, digits or underscores, starting with a letter. It must exactly match the slug configured in CRM.
- The dedicated **read key** supplied by the CRM owner. Store it as
  `CRM_READ_API_KEY` in your server's secret settings. **Never share your
  database key.**

---

## The endpoint contract

Your endpoint can live at any path. CRM calls it like this:

```
GET https://your-product.com/any/path
Authorization: Bearer <CRM_READ_API_KEY>
Accept: application/json
Query: limit (1–100, default 50), cursor (optional)
```

Your endpoint must:

| Rule | Detail |
| --- | --- |
| Return the [response format](#response-format) | At most `limit` accounts per page |
| Use `next_cursor` | Opaque string for the next page; `null` on the last page |
| Send `Cache-Control: no-store` | Every request reads live data |
| Respond within 8 seconds | CRM times out after that, so test your largest page |
| Use the right status codes | See the table below |
| Match the slug | `product.external_id` must equal the CRM slug exactly |

| Status | When |
| --- | --- |
| `200` | Success |
| `400` | Bad `limit` or `cursor`, or an expired cursor |
| `401` | Missing or wrong key |
| `405` | Wrong HTTP method |
| `502` | Adapter returned an invalid snapshot |
| `503` | Missing configuration, unfinished adapter, or source unavailable |

Errors use `{ "code": "SOURCE_UNAVAILABLE", "error": "Snapshot temporarily unavailable", "request_id": "..." }`.
The same ID is in the `X-Request-Id` response header and product server log.
CRM forwards this ID to the product endpoint. Share the **code, request ID,
product slug, and time** when asking another developer to investigate. Never
send keys or customer records in a bug report.

---

## Express setup

You touch three files. Two are new, and one already exists.

| File | Action | Source |
| --- | --- | --- |
| `backend/utils/crmSnapshotRouter.js` | Create. Copy as-is. | [Router file](./express/crmSnapshotRouter.example.js) or [inline copy](#router-file) |
| `backend/routes/crm_integration.route.js` | Create, then fill in the `CHANGE ME` sections. | [Route template](./express/crm_integration.route.example.js) or [inline copy](#route-template) |
| `backend/server.js` | Edit. Add the mount block. Don't replace the file. | [Mount snippet](./express/server.mount.example.js) or Step 3 below |

### Step 1: Add the router

Copy the [router file](#router-file) to `backend/utils/crmSnapshotRouter.js`. It checks the read key, validates your data and formats responses. You don't need to change it.

### Step 2: Add and complete the route

Copy the [route template](#route-template) to `backend/routes/crm_integration.route.js`. Search for `CHANGE ME` and complete each numbered section:

| # | What to change | What to do |
| --- | --- | --- |
| 1 | `PRODUCT_SLUG`, `PRODUCT_NAME` | Your CRM slug and display name |
| 2 | `getDatabaseClient()` | Return your existing **server-side** database client |
| 3 | `loadCounts()` | Product-wide totals: all customers, active customers, unresolved tickets |
| 4 | `loadSubscriptionRevenue()` | Sum **completed product subscription** payments, grouped by currency |
| 5 | `loadCustomerPage()` | One stable page of customers: `{ rows, nextCursor }` |
| 6 | The three lookup functions | Batch queries for the page's admins, latest payments and open tickets. Return `Map`s keyed by `String(customer.id)`. |
| 7 | `mapCustomer()` | Map your column names to the [response fields](#response-format) |

Unfinished sections throw an error on purpose, so the route can never report invented data.

### Step 3: Mount the route

In your existing `backend/server.js`, add this after your middleware and **before** any catch-all route:

```js
app.use('/api/crm/v1', require('./routes/crm_integration.route.js'));
```

Don't wrap it in user-login middleware. The route checks its own Bearer key.
If the read key is missing, it returns `INTEGRATION_NOT_CONFIGURED` instead
of silently leaving the route unmounted.

Your endpoint is now `GET /api/crm/v1/snapshot`.

---

## Firebase Cloud Functions

Follow the [Firebase setup and example](./firebase/README.md):

1. Copy the function into your functions source (for example `functions/index.js`).
2. Complete every `CHANGE ME` query and mapping.
3. Set `CRM_READ_API_KEY` as a Firebase secret.
4. Deploy, and give CRM the **full deployed function URL**.

No Express mount or `server.js` change is needed.

**Express backend that uses Firebase Admin?** Use the [Express setup](#express-setup) instead. Return the Firestore client from `getDatabaseClient()`:

```js
require('firebase-admin/firestore').getFirestore()
```

Call it after Firebase Admin has initialized, then write the `CHANGE ME` queries with the Firestore API.

---

## Response format

```json
{
  "schema_version": 1,
  "generated_at": "2026-11-13T10:00:00.000Z",
  "product": { "external_id": "example_product", "name": "Example Product" },
  "summary": {
    "customer_count": 120,
    "active_customer_count": 108,
    "open_tickets": 7,
    "subscription_revenue": [{ "amount": 250000, "currency": "KES" }]
  },
  "accounts": [{
    "external_id": "customer-uuid",
    "name": "Customer A",
    "location": "Nairobi",
    "admin_name": "Primary administrator",
    "subscription": { "plan": "pro", "status": "active", "cycle": "monthly" },
    "last_payment": {
      "amount": 5000,
      "currency": "KES",
      "status": "completed",
      "paid_at": "2026-11-12T09:00:00.000Z",
      "reference": "PAY-123"
    },
    "open_tickets": 1,
    "updated_at": "2026-11-12T09:00:00.000Z"
  }],
  "next_cursor": null
}
```

### Field rules

| Field | Rule |
| --- | --- |
| `customer_count`, `active_customer_count`, `open_tickets` (summary) | Totals for the **whole product**, not the current page |
| `subscription_revenue` | Completed **product subscription** payments only, grouped by currency. Exclude school fees, user purchases and pending payments. |
| `external_id` (account) | Must stay the same across syncs |
| `last_payment` | The latest completed **subscription** payment, not any other transaction |
| `open_tickets` (account) | Unresolved support requests for that account |
| `updated_at` | From the source record, or `null`. Never invent it. |
| `generated_at` | When your endpoint built the response |
| Optional values with no source | Use `null`. Never make up a value. |

---

## Test before you hand off

1. **Auth.** Call the **product endpoint**, not CRM's port. Without the key
   you get `401 READ_KEY_INVALID`. With it you get `200` and the JSON above.
   In PowerShell, use `curl.exe`; `curl` may mean `Invoke-WebRequest`.

   ```powershell
   $endpoint = Read-Host 'Full product snapshot URL'
   $readKey = Read-Host 'Dedicated CRM read key'
   curl.exe -i "${endpoint}?limit=2"
   curl.exe -i "${endpoint}?limit=2" -H "Authorization: Bearer $readKey"
   ```

   On macOS or Linux, use `curl` with the same full endpoint URL and
   `Authorization` header. Keep the read key out of committed scripts and
   shared terminal output.

2. **Numbers.** Totals, active counts, revenue by currency, latest payments and ticket counts match your database.
3. **Pagination.** `limit=2` returns at most 2 accounts. Following `next_cursor` gives new accounts with no repeats, and the last page returns `next_cursor: null`.
4. **Live data.** Change a record, and the next request reflects it. Nothing is cached.

---

## Hand off to the CRM owner

Send three things:

1. Your product slug
2. The full HTTPS endpoint URL
3. A sample response with no secrets

Share the read key through a secure channel. Never send your database key.

---

## Troubleshooting and recovery

Start with the error `code` and `request_id`. Find the same request ID in
the product backend's `[CRM snapshot]` log. That log includes a safe field
name for invalid snapshots or the database driver's error code and message
for source failures. The HTTP response does not expose database details.

| Product endpoint code | What to check or try next |
| --- | --- |
| `INVALID_PAGINATION` (400) | Send an integer `limit` from 1 to 100 and a cursor from the preceding response. Retry without a cursor to start over. |
| `INVALID_CURSOR` (400) | Start at the first page. Check that the adapter orders accounts by a stable ID and handles deleted cursor records. |
| `READ_KEY_INVALID` (401) | Compare the dedicated read key on both servers through a secure channel; redeploy or restart after a secret change. Do not use the database key. |
| `METHOD_NOT_ALLOWED` (405) | Send `GET` to the **full** endpoint URL. |
| `INVALID_SNAPSHOT` (502) | Use the logged `field` to fix the adapter mapping. Required counts are nonnegative integers; missing optional values are `null`. Test with `limit=1` to isolate a bad account. |
| `INTEGRATION_NOT_CONFIGURED` (503) | Check that the product backend has a `CRM_READ_API_KEY` of at least 32 characters and that its process loaded the secret. Restart or redeploy. |
| `ADAPTER_INCOMPLETE` (503) | Search the product route for `CHANGE ME` and implement the named query. Do not replace failures with made-up zeros. |
| `SOURCE_UNAVAILABLE` (503) | Check the logged `source_code` and `message`. Run the failing database query independently, restore connectivity or permissions, then retry. A smaller page may help identify a slow page query. |

For an **LMS-only** Supabase adapter, `PGRST202` means the RPC signature is
missing from the API schema cache. Check that the LMS migration was applied
to the correct Supabase project; if the function exists, refresh PostgREST's
[schema cache](https://supabase.com/kb/troubleshooting/refresh-postgrest-schema).
Other products use their own database setup.

If the product endpoint succeeds but CRM fails, inspect the CRM response:

| CRM code | What to check or try next |
| --- | --- |
| `CRM_AUTH_REQUIRED` / `CRM_FORBIDDEN` | Sign in as a CRM superadmin. |
| `CRM_AUTH_UNAVAILABLE` | CRM could not check the login or employee role. CRM owner checks the CRM auth service and server log. |
| `PRODUCT_NOT_CONFIGURED` / `PRODUCT_URL_INVALID` | CRM owner checks the product's full HTTPS URL and read key configuration. A bare origin or `https://` placeholder is insufficient. |
| `PRODUCT_READ_KEY_REJECTED` | Product returned 401; compare the two dedicated read keys securely. |
| `PRODUCT_UNAVAILABLE` / `PRODUCT_HTTP_ERROR` | Use `upstream_code` and `request_id` to find the product server log. Test the product endpoint directly. |
| `PRODUCT_INVALID_JSON` / `PRODUCT_INVALID_SNAPSHOT` | Return the exact JSON contract shown above, including the matching product slug. |
| `PRODUCT_TIMEOUT` / `PRODUCT_NETWORK_ERROR` | Confirm the product URL is reachable **from the CRM server**. For local testing, run both backends locally. Use indexed queries and batched lookups to stay under eight seconds. |

Retry only after fixing the underlying issue or for a brief transient outage.
Do not serve a cached or invented snapshot as a fallback.

---

## Current limits

This connection is read-only. It shows the product overview, customers, packages, last payments and open ticket counts. It does **not** push support tickets into the CRM ticket queue yet.

---

## Reference files

### Router file

Save as `backend/utils/crmSnapshotRouter.js`. Copy without changes.

<details>
<summary>Show crmSnapshotRouter.js</summary>

```js
// Copy this file into an Express product backend, then mount the router as shown
// in docs/integrations/product-connection.md. Node 18+ and Express are required.
const crypto = require('node:crypto');
const express = require('express');

function matchesKey(supplied, expected) {
  if (!supplied || !expected) return false;
  // Hash before comparing so different key lengths do not leak through timing.
  const left = crypto.createHash('sha256').update(supplied).digest();
  const right = crypto.createHash('sha256').update(expected).digest();
  return crypto.timingSafeEqual(left, right);
}

function validDate(value) {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value));
}

function validMoney(value) {
  return value === null || (
    value && Number.isFinite(value.amount) && value.amount >= 0 &&
    typeof value.currency === 'string' && /^[A-Z]{3}$/.test(value.currency)
  );
}

function validAccount(account) {
  return account && typeof account.external_id === 'string' && account.external_id.length > 0 &&
    typeof account.name === 'string' && account.name.length > 0 &&
    (account.location === null || typeof account.location === 'string') &&
    (account.admin_name === null || typeof account.admin_name === 'string') &&
    account.subscription && (account.subscription.plan === null || typeof account.subscription.plan === 'string') &&
    (account.subscription.status === null || typeof account.subscription.status === 'string') &&
    (account.subscription.cycle === null || typeof account.subscription.cycle === 'string') &&
    (account.last_payment === null || (
      validMoney(account.last_payment) &&
      typeof account.last_payment.status === 'string' &&
      (account.last_payment.paid_at === null || validDate(account.last_payment.paid_at)) &&
      (account.last_payment.reference === null || typeof account.last_payment.reference === 'string')
    )) &&
    Number.isSafeInteger(account.open_tickets) && account.open_tickets >= 0 &&
    (account.updated_at === null || validDate(account.updated_at));
}

function invalidSnapshotField(snapshot, limit) {
  if (!snapshot || !snapshot.product || !snapshot.summary || !Array.isArray(snapshot.accounts)) return 'snapshot';
  const { product, summary, accounts, next_cursor } = snapshot;
  if (typeof product.external_id !== 'string' || !product.external_id ||
      typeof product.name !== 'string' || !product.name) return 'product';
  if (!Number.isSafeInteger(summary.customer_count) || summary.customer_count < 0 ||
      !Number.isSafeInteger(summary.active_customer_count) || summary.active_customer_count < 0 ||
      !Number.isSafeInteger(summary.open_tickets) || summary.open_tickets < 0 ||
      !Array.isArray(summary.subscription_revenue) ||
      !summary.subscription_revenue.every((value) => value !== null && validMoney(value))) return 'summary';
  if (accounts.length > limit) return 'accounts.length';
  const badIndex = accounts.findIndex((account) => !validAccount(account));
  if (badIndex !== -1) return `accounts[${badIndex}]`;
  if (next_cursor !== null && typeof next_cursor !== 'string') return 'next_cursor';
  return null;
}

function requestId(req) {
  const supplied = req.get('x-request-id');
  // Reuse CRM's safe identifier so both servers can find the same request.
  return supplied && /^[A-Za-z0-9_-]{8,64}$/.test(supplied)
    ? supplied : crypto.randomUUID();
}

function failure(res, status, code, error, id) {
  return res.status(status).json({ code, error, request_id: id });
}

/**
 * The adapter MUST query this product's live database. It receives { limit,
 * cursor } and returns the contract documented in product-connection.md.
 * Do not fill missing data with invented values; use null for optional fields.
 */
function createCrmSnapshotRouter(adapter, options = {}) {
  if (!adapter || typeof adapter.getSnapshot !== 'function') {
    throw new TypeError('An adapter with getSnapshot({ limit, cursor }) is required');
  }
  const router = express.Router();
  const readKey = options.readKey || process.env.CRM_READ_API_KEY;

  router.get('/snapshot', async (req, res) => {
    res.set('Cache-Control', 'no-store');
    const id = requestId(req);
    res.set('X-Request-Id', id);
    if (!readKey || readKey.length < 32) {
      console.error('[CRM snapshot]', { request_id: id, code: 'INTEGRATION_NOT_CONFIGURED' });
      return failure(res, 503, 'INTEGRATION_NOT_CONFIGURED', 'CRM read key is not configured', id);
    }
    const header = req.get('authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!matchesKey(token, readKey)) {
      return failure(res, 401, 'READ_KEY_INVALID', 'Unauthorized', id);
    }

    const rawLimit = req.query.limit ?? '50';
    const limit = Number(rawLimit);
    const cursor = req.query.cursor ?? null;
    if (typeof rawLimit !== 'string' || !/^([1-9]|[1-9][0-9]|100)$/.test(rawLimit) ||
        (cursor !== null && (typeof cursor !== 'string' || !cursor || cursor.length > 512))) {
      return failure(res, 400, 'INVALID_PAGINATION', 'Invalid limit or cursor', id);
    }

    try {
      // Read current records on every request. The adapter should page accounts
      // with a stable cursor and use indexed queries; never load all customers.
      const snapshot = await adapter.getSnapshot({ limit, cursor });
      const field = invalidSnapshotField(snapshot, limit);
      if (field) {
        console.error('[CRM snapshot]', { request_id: id, code: 'INVALID_SNAPSHOT', field });
        return failure(res, 502, 'INVALID_SNAPSHOT', 'Product adapter returned an invalid snapshot', id);
      }
      return res.json({ ...snapshot, schema_version: 1, generated_at: new Date().toISOString() });
    } catch (error) {
      // Keep vendor error details in server logs. CRM can report this request ID.
      const code = error?.code === 'INVALID_CURSOR' ? 'INVALID_CURSOR'
        : error?.code === 'ADAPTER_INCOMPLETE' ? 'ADAPTER_INCOMPLETE' : 'SOURCE_UNAVAILABLE';
      console.error('[CRM snapshot]', {
        request_id: id, code, source_code: String(error?.code || '').slice(0, 64),
        message: String(error?.message || error).slice(0, 500),
      });
      return failure(res, code === 'INVALID_CURSOR' ? 400 : 503, code,
        code === 'INVALID_CURSOR' ? 'Cursor is no longer valid' : 'Snapshot temporarily unavailable', id);
    }
  });

  router.all('/snapshot', (req, res) => {
    const id = requestId(req);
    res.set('Cache-Control', 'no-store');
    res.set('X-Request-Id', id);
    res.set('Allow', 'GET');
    return failure(res, 405, 'METHOD_NOT_ALLOWED', 'Use GET for this endpoint', id);
  });

  return router;
}

module.exports = { createCrmSnapshotRouter };
```

</details>

### Route template

Save as `backend/routes/crm_integration.route.js`. Complete every `CHANGE ME` before deploying.

<details>
<summary>Show crm_integration.route.js</summary>

```js
// Copy this file to backend/routes/crm_integration.route.js.
// Complete every CHANGE ME section before deploying the product backend.
const { createCrmSnapshotRouter } = require('../utils/crmSnapshotRouter.js');

// Unfinished queries return a clear code instead of invented data.
function unfinished(task) {
  const error = new Error(`CHANGE ME: ${task}`);
  error.code = 'ADAPTER_INCOMPLETE';
  throw error;
}

// CHANGE ME 1: Use the lowercase slug configured in CRM_CONNECTED_PRODUCTS.
// Example: 'stocksense'. The CRM rejects a different product.external_id.
const PRODUCT_SLUG = 'change_me';
const PRODUCT_NAME = 'Change Me';

// CHANGE ME 2: Return THIS product's existing server-side database client.
// Return your existing server-side client (SQL, Firebase Admin, etc.).
// Keep database secret keys on this server; CRM only uses the read key.
function getDatabaseClient() {
  unfinished('connect this route to the product database');
}

// CHANGE ME 3: Query product-wide totals, not just the current page.
// Return { customers: number, activeCustomers: number, openTickets: number }.
// Count unresolved support tickets using this product's actual status values.
async function loadCounts(db) {
  unfinished('query total customers, active customers, and open tickets');
}

// CHANGE ME 4: Sum COMPLETED PRODUCT SUBSCRIPTION payments by currency.
// Return [{ amount: number, currency: 'KES' }, ...] or [] if none.
// Do not include school fees, user purchases, or pending payments.
async function loadSubscriptionRevenue(db) {
  unfinished('query completed product subscription revenue');
}

// CHANGE ME 5: Page product customers using a stable database order.
// Return { rows: customerRows, nextCursor: string | null }.
// Read at most limit + 1 rows, return at most limit, and set nextCursor only
// when another page exists. Treat cursor as an opaque value from the prior page.
// Map a customer to an institution, shop, business, or equivalent account.
// If a cursor no longer exists, throw an error with code 'INVALID_CURSOR'.
async function loadCustomerPage(db, { limit, cursor }) {
  unfinished('query one stable page of product customers');
}

// CHANGE ME 6: Batch the lookups for the current page.
// Each Map is keyed by String(customer.id). Return an empty Map for no match.
// payments values must be { amount, currency, status, paid_at, reference }.
async function loadPrimaryAdmins(db, customerIds) {
  unfinished('query primary admin names for this page');
}
async function loadLatestCompletedPayments(db, customerIds) {
  unfinished('query latest completed subscription payment per customer');
}
async function loadOpenTicketCounts(db, customerIds) {
  unfinished('query unresolved ticket counts per customer');
}

// CHANGE ME 7: Map your real customer column names to the CRM fields.
// Use null for optional data that does not exist; never invent a payment.
// Dates must be ISO strings. Keep external_id stable across requests.
function mapCustomer(row, { admins, payments, ticketCounts }) {
  const id = String(row.id);
  return {
    external_id: id,
    name: row.name,
    location: row.location ?? null,
    admin_name: admins.get(id) ?? null,
    subscription: {
      plan: row.subscription_plan ?? null,
      status: row.subscription_status ?? null,
      cycle: row.subscription_cycle ?? null,
    },
    last_payment: payments.get(id) ?? null,
    open_tickets: ticketCounts.get(id) ?? 0,
    updated_at: row.updated_at ?? row.created_at ?? null,
  };
}

const adapter = {
  async getSnapshot({ limit, cursor }) {
    const db = getDatabaseClient();
    const [counts, revenue, customerPage] = await Promise.all([
      loadCounts(db),
      loadSubscriptionRevenue(db),
      loadCustomerPage(db, { limit, cursor }),
    ]);
    const rows = customerPage.rows;
    const ids = rows.map((row) => String(row.id));

    // Three batch queries are faster than a query for every customer.
    const [admins, payments, ticketCounts] = ids.length
      ? await Promise.all([
          loadPrimaryAdmins(db, ids),
          loadLatestCompletedPayments(db, ids),
          loadOpenTicketCounts(db, ids),
        ])
      : [new Map(), new Map(), new Map()];

    return {
      product: { external_id: PRODUCT_SLUG, name: PRODUCT_NAME },
      summary: {
        customer_count: counts.customers,
        active_customer_count: counts.activeCustomers,
        open_tickets: counts.openTickets,
        subscription_revenue: revenue,
      },
      accounts: rows.map((row) => mapCustomer(row, { admins, payments, ticketCounts })),
      next_cursor: customerPage.nextCursor,
    };
  },
};

// Appendix A checks the read key, validates this data, and serves JSON.
module.exports = createCrmSnapshotRouter(adapter);
```

</details>
