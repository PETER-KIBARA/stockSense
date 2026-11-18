// StockSense CRM snapshot endpoint (Firebase Cloud Functions v2 + Firestore).
// Read-only: CRM calls this URL with a Bearer key and reads a JSON snapshot.
// Customers are business admin accounts (role 'admin') in the `users`
// collection. Demo visitors are anonymous staff accounts and are not counted.
const crypto = require('node:crypto');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { FieldPath, getFirestore } = require('firebase-admin/firestore');

initializeApp();
const crmReadKey = defineSecret('CRM_READ_API_KEY');

// Must match the product slug configured in CRM exactly.
const PRODUCT_SLUG = 'stocksense';
const PRODUCT_NAME = 'StockSense';
const CUSTOMER_COLLECTION = 'users';

function matchesKey(supplied, expected) {
  if (!supplied || !expected) return false;
  const left = crypto.createHash('sha256').update(supplied).digest();
  const right = crypto.createHash('sha256').update(expected).digest();
  return crypto.timingSafeEqual(left, right);
}

function isDate(value) {
  return value === null || (typeof value === 'string' && !Number.isNaN(Date.parse(value)));
}

function validMoney(value) {
  return value && Number.isFinite(value.amount) && value.amount >= 0 &&
    typeof value.currency === 'string' && /^[A-Z]{3}$/.test(value.currency);
}

function validAccount(account) {
  return account && typeof account.external_id === 'string' && account.external_id.length > 0 &&
    typeof account.name === 'string' && account.name.length > 0 &&
    (account.location === null || typeof account.location === 'string') &&
    (account.admin_name === null || typeof account.admin_name === 'string') &&
    account.subscription &&
    ['plan', 'status', 'cycle'].every((field) =>
      account.subscription[field] === null || typeof account.subscription[field] === 'string') &&
    (account.last_payment === null || (
      validMoney(account.last_payment) && account.last_payment.status === 'completed' &&
      isDate(account.last_payment.paid_at) &&
      (account.last_payment.reference === null || typeof account.last_payment.reference === 'string')
    )) &&
    Number.isSafeInteger(account.open_tickets) && account.open_tickets >= 0 &&
    isDate(account.updated_at);
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
      !summary.subscription_revenue.every(validMoney)) return 'summary';
  if (accounts.length > limit) return 'accounts.length';
  const badIndex = accounts.findIndex((account) => !validAccount(account));
  if (badIndex !== -1) return `accounts[${badIndex}]`;
  if (next_cursor !== null && typeof next_cursor !== 'string') return 'next_cursor';
  return null;
}

function requestId(req) {
  const supplied = req.get('x-request-id');
  return supplied && /^[A-Za-z0-9_-]{8,64}$/.test(supplied)
    ? supplied : crypto.randomUUID();
}

function failure(res, status, code, error, id) {
  return res.status(status).json({ code, error, request_id: id });
}

function toIso(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string' && !Number.isNaN(Date.parse(value))) return new Date(value).toISOString();
  return null;
}

// Product-wide totals (not just the current page).
async function loadCounts(db) {
  const count = async (query) => (await query.count().get()).data().count;
  const admins = db.collection(CUSTOMER_COLLECTION).where('role', '==', 'admin');
  const anonymousAdmins = admins.where('isAnonymous', '==', true);

  // Old anonymous demo admins are not real customers, so they are subtracted.
  const [all, active, anonymous, anonymousActive] = await Promise.all([
    count(admins),
    count(admins.where('isActive', '==', true)),
    count(anonymousAdmins),
    count(anonymousAdmins.where('isActive', '==', true)),
  ]);
  return {
    customers: all - anonymous,
    activeCustomers: active - anonymousActive,
    // StockSense does not store support tickets yet; reports are sent by email.
    openTickets: 0,
  };
}

// StockSense takes no online payments (Cloudora's team arranges upgrades), so
// there are no completed subscription payments to add up yet.
async function loadSubscriptionRevenue(db) {
  return [];
}

// One stable page of customers. The document ID is the cursor.
async function loadCustomerPage(db, { limit, cursor }) {
  const collection = db.collection(CUSTOMER_COLLECTION);
  let query = collection
    .where('role', '==', 'admin')
    .orderBy(FieldPath.documentId())
    .limit(limit + 1);
  if (cursor) {
    const previous = await collection.doc(cursor).get();
    if (!previous.exists) {
      const error = new Error('Customer cursor no longer exists');
      error.code = 'INVALID_CURSOR';
      throw error;
    }
    query = query.startAfter(previous);
  }
  const result = await query.get();
  const visible = result.docs.slice(0, limit);
  return {
    rows: visible
      .filter((doc) => doc.data().isAnonymous !== true)
      .map((doc) => ({ ...doc.data(), id: doc.id })),
    nextCursor: result.docs.length > limit ? visible.at(-1).id : null,
  };
}

// Each customer is its own administrator, and StockSense has no payment or
// ticket collections yet, so these return empty Maps instead of invented data.
async function loadPrimaryAdmins(db, customerIds) {
  return new Map();
}
async function loadLatestCompletedPayments(db, customerIds) {
  return new Map();
}
async function loadOpenTicketCounts(db, customerIds) {
  return new Map();
}

function mapCustomer(row, { payments, ticketCounts }) {
  const id = String(row.id);
  const payment = payments.get(id);
  return {
    external_id: id,
    name: row.displayName || row.email || id,
    location: row.location ?? null,
    admin_name: row.displayName || null,
    subscription: {
      // Cloudora can add a "plan" field (Basic, Pro or Premium) to an admin
      // user document and it will flow through here.
      plan: row.plan ?? null,
      status: row.isActive === false ? 'inactive' : 'active',
      cycle: row.billingCycle ?? null,
    },
    last_payment: payment ? { ...payment, paid_at: toIso(payment.paid_at) } : null,
    open_tickets: ticketCounts.get(id) ?? 0,
    updated_at: toIso(row.updatedAt ?? row.createdAt),
  };
}

async function buildSnapshot(db, { limit, cursor }) {
  const [counts, revenue, page] = await Promise.all([
    loadCounts(db), loadSubscriptionRevenue(db), loadCustomerPage(db, { limit, cursor }),
  ]);
  const ids = page.rows.map((row) => String(row.id));
  const [admins, payments, ticketCounts] = ids.length
    ? await Promise.all([
        loadPrimaryAdmins(db, ids), loadLatestCompletedPayments(db, ids),
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
    accounts: page.rows.map((row) => mapCustomer(row, { admins, payments, ticketCounts })),
    next_cursor: page.nextCursor,
  };
}

// Cloud Functions exports this as an HTTPS endpoint. Give CRM the FULL
// deployed URL that `firebase deploy` prints; Firebase chooses the URL path.
exports.crmSnapshot = onRequest({ secrets: [crmReadKey] }, async (req, res) => {
  res.set('Cache-Control', 'no-store');
  const id = requestId(req);
  res.set('X-Request-Id', id);
  if (req.method !== 'GET') {
    res.set('Allow', 'GET');
    return failure(res, 405, 'METHOD_NOT_ALLOWED', 'Use GET for this endpoint', id);
  }
  const header = req.get('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  const expected = crmReadKey.value();
  if (!expected || expected.length < 32) {
    console.error('[CRM snapshot]', { request_id: id, code: 'INTEGRATION_NOT_CONFIGURED' });
    return failure(res, 503, 'INTEGRATION_NOT_CONFIGURED', 'CRM read key is not configured', id);
  }
  if (!matchesKey(token, expected)) {
    return failure(res, 401, 'READ_KEY_INVALID', 'Unauthorized', id);
  }

  const rawLimit = req.query.limit ?? '50';
  const limit = Number(rawLimit);
  const cursor = req.query.cursor ?? null;
  if (typeof rawLimit !== 'string' || !/^([1-9]|[1-9][0-9]|100)$/.test(rawLimit) ||
      (cursor !== null && (typeof cursor !== 'string' || !cursor ||
        cursor.length > 512 || cursor.includes('/')))) {
    return failure(res, 400, 'INVALID_PAGINATION', 'Invalid limit or cursor', id);
  }
  try {
    const snapshot = await buildSnapshot(getFirestore(), { limit, cursor });
    const field = invalidSnapshotField(snapshot, limit);
    if (field) {
      console.error('[CRM snapshot]', { request_id: id, code: 'INVALID_SNAPSHOT', field });
      return failure(res, 502, 'INVALID_SNAPSHOT', 'Product adapter returned an invalid snapshot', id);
    }
    return res.json({ ...snapshot, schema_version: 1, generated_at: new Date().toISOString() });
  } catch (error) {
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