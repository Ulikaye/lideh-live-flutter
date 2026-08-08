const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// Bot detection
// ---------------------------------------------------------------------------
// Matches the user-agent strings of major search engine and link-preview
// crawlers. Real browsers never match this list, so they always fall
// through to the normal Flutter app untouched.
const BOT_USER_AGENT_PATTERN = new RegExp(
  [
    'googlebot', 'bingbot', 'slurp', 'duckduckbot', 'baiduspider',
    'yandexbot', 'facebookexternalhit', 'twitterbot', 'linkedinbot',
    'whatsapp', 'telegrambot', 'discordbot', 'slackbot', 'pinterest',
    'redditbot', 'applebot', 'ia_archiver',
  ].join('|'),
  'i'
);

function isBot(userAgent) {
  return !!userAgent && BOT_USER_AGENT_PATTERN.test(userAgent);
}

// ---------------------------------------------------------------------------
// The real Flutter app shell, served as-is to every non-bot request.
//
// IMPORTANT: this must be kept in sync with web/index.html. Whenever
// index.html changes, copy it again with:
//   node functions/scripts/sync-shell.js
// (run from the project root — see README section on SEO prerendering)
// ---------------------------------------------------------------------------
function getAppShellHtml() {
  const shellPath = path.join(__dirname, 'app-shell.html');
  try {
    return fs.readFileSync(shellPath, 'utf8');
  } catch (e) {
    // If the shell was never synced, fail loudly rather than serving a
    // broken page silently — this is a deploy-time mistake, not a
    // runtime one, and should be caught immediately during testing.
    return '<!doctype html><html><body>App shell missing — run node functions/scripts/sync-shell.js and redeploy.</body></html>';
  }
}

// ---------------------------------------------------------------------------
// HTML snapshot builders — plain, semantic, crawlable HTML for each
// SEO-relevant route. These intentionally do NOT try to replicate the
// Flutter app's visuals; they only need to expose real text content,
// a sensible <title>, meta description, and Open Graph tags.
// ---------------------------------------------------------------------------
function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function renderPage({ title, description, imageUrl, canonicalPath, bodyHtml }) {
  const siteName = 'LiDeH Live';
  const baseUrl = 'https://www.lideh.co.tz';
  const fullTitle = title ? `${title} | ${siteName}` : siteName;
  const image = imageUrl || `${baseUrl}/icons/Icon-512.png`;

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${escapeHtml(fullTitle)}</title>
<meta name="description" content="${escapeHtml(description)}">
<link rel="canonical" href="${baseUrl}${canonicalPath}">
<meta property="og:title" content="${escapeHtml(fullTitle)}">
<meta property="og:description" content="${escapeHtml(description)}">
<meta property="og:image" content="${escapeHtml(image)}">
<meta property="og:url" content="${baseUrl}${canonicalPath}">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
</head>
<body>
${bodyHtml}
<p><a href="${baseUrl}${canonicalPath}">View this on LiDeH Live</a></p>
</body>
</html>`;
}

async function renderHome() {
  const snap = await db.collection('musicians').orderBy('avg_rating', 'desc').limit(6).get();
  const musicians = snap.docs.map((d) => d.data());

  const listItems = musicians
    .map((m) => `<li><h2>${escapeHtml(m.stage_name)}</h2><p>${escapeHtml(m.location || '')}</p></li>`)
    .join('\n');

  return renderPage({
    title: null,
    description: 'Connecting Gospel Musicians with the Church. Find and book gospel musicians for your next event, or get discovered as a musician.',
    canonicalPath: '/',
    bodyHtml: `
      <h1>LiDeH Live — Connecting Gospel Musicians with the Church</h1>
      <p>Find the right gospel musician for your next event, or get booked for events near you.</p>
      <h2>Featured Musicians</h2>
      <ul>${listItems}</ul>
    `,
  });
}

async function renderMusicianProfile(id) {
  const doc = await db.collection('musicians').doc(id).get();
  if (!doc.exists) return null;
  const m = doc.data();

  const skillsText = (m.skills || []).join(', ');
  const description = [
    m.location ? `Based in ${m.location}.` : null,
    skillsText ? `Skills: ${skillsText}.` : null,
    m.starting_price ? `Starting price: $${m.starting_price}.` : null,
  ].filter(Boolean).join(' ');

  return renderPage({
    title: m.stage_name,
    description: description || `${m.stage_name} — gospel musician on LiDeH Live.`,
    canonicalPath: `/musicians/${id}`,
    bodyHtml: `
      <h1>${escapeHtml(m.stage_name)}</h1>
      ${m.location ? `<p>Location: ${escapeHtml(m.location)}</p>` : ''}
      ${skillsText ? `<p>Skills: ${escapeHtml(skillsText)}</p>` : ''}
      ${m.starting_price ? `<p>Starting price: $${escapeHtml(String(m.starting_price))}</p>` : ''}
      ${m.availability_notes ? `<p>Availability: ${escapeHtml(m.availability_notes)}</p>` : ''}
    `,
  });
}

async function renderBlogPost(id) {
  const doc = await db.collection('blogPosts').doc(id).get();
  if (!doc.exists || doc.data().is_published !== true) return null;
  const post = doc.data();

  return renderPage({
    title: post.title,
    description: post.excerpt || post.title,
    imageUrl: post.featured_image_url,
    canonicalPath: `/blog/${id}`,
    bodyHtml: `
      <h1>${escapeHtml(post.title)}</h1>
      <p>${escapeHtml(post.content || '')}</p>
    `,
  });
}

async function renderEvent(id) {
  const doc = await db.collection('events').doc(id).get();
  if (!doc.exists) return null;
  const event = doc.data();
  const dateStr = event.date && event.date.toDate ? event.date.toDate().toDateString() : '';

  return renderPage({
    title: event.title,
    description: `${event.title} — ${dateStr} at ${event.location || ''}`.trim(),
    imageUrl: event.image_url,
    canonicalPath: `/events/${id}`,
    bodyHtml: `
      <h1>${escapeHtml(event.title)}</h1>
      <p>Date: ${escapeHtml(dateStr)}</p>
      <p>Location: ${escapeHtml(event.location || '')}</p>
      ${event.description ? `<p>${escapeHtml(event.description)}</p>` : ''}
    `,
  });
}

// ---------------------------------------------------------------------------
// sitemap.xml — dynamically generated from live Firestore data, so newly
// added musicians/blog posts/events show up automatically without a
// separate build step.
// ---------------------------------------------------------------------------
exports.sitemap = functions.https.onRequest(async (req, res) => {
  const baseUrl = 'https://www.lideh.co.tz';
  const staticPaths = ['/', '/musicians', '/events', '/blog', '/about', '/contact'];

  const [musiciansSnap, postsSnap, eventsSnap] = await Promise.all([
    db.collection('musicians').get(),
    db.collection('blogPosts').where('is_published', '==', true).get(),
    db.collection('events').get(),
  ]);

  const urls = [
    ...staticPaths,
    ...musiciansSnap.docs.map((d) => `/musicians/${d.id}`),
    ...postsSnap.docs.map((d) => `/blog/${d.id}`),
    ...eventsSnap.docs.map((d) => `/events/${d.id}`),
  ];

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((u) => `  <url><loc>${baseUrl}${u}</loc></url>`).join('\n')}
</urlset>`;

  res.set('Content-Type', 'application/xml');
  res.status(200).send(xml);
});
// ---------------------------------------------------------------------------
// Booking notifications
//
// Writes a notifications/{autoId} document for the recipient (used by
// the in-app notification bell/inbox), and best-effort sends a push
// notification via FCM if the recipient has a registered device token.
// A missing/stale FCM token never fails the whole trigger — the
// Firestore notification document is the source of truth; push is a
// bonus on top of it.
// ---------------------------------------------------------------------------
async function notifyUser({ userId, title, body, bookingId }) {
  await db.collection('notifications').add({
    user_id: userId,
    title,
    body,
    booking_id: bookingId,
    read: false,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const token = userDoc.exists ? userDoc.data().fcm_token : null;
    if (token) {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: { booking_id: bookingId || '' },
      });
    }
  } catch (e) {
    functions.logger.warn('FCM push failed (notification document was still saved)', e);
  }
}

exports.onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const bookingId = context.params.bookingId;

    // Always notify whichever party did NOT initiate the booking.
    const recipientId = booking.created_by === booking.musician_id ? booking.organizer_id : booking.musician_id;
    const isNotifyingMusician = recipientId === booking.musician_id;

    await notifyUser({
      userId: recipientId,
      title: isNotifyingMusician ? 'New Booking Request' : 'New Performance Application',
      body: isNotifyingMusician
        ? `You have a new booking request for "${booking.event_name}".`
        : `A musician applied to perform at "${booking.event_name}".`,
      bookingId,
    });
  });

exports.onBookingUpdated = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    if (before.status === after.status) return; // only react to actual status changes

    const messages = {
      accepted: {
        userId: after.organizer_id,
        title: 'Booking Accepted',
        body: `Your booking request for "${after.event_name}" was accepted.`,
      },
      declined: {
        userId: after.organizer_id,
        title: 'Booking Declined',
        body: `Your booking request for "${after.event_name}" was declined.`,
      },
      completed: {
        userId: after.organizer_id,
        title: 'Booking Completed',
        body: `"${after.event_name}" is marked complete. Leave a review for the musician!`,
      },
      cancelled: {
        userId: after.musician_id,
        title: 'Booking Cancelled',
        body: `The booking for "${after.event_name}" was cancelled.`,
      },
    };

    const message = messages[after.status];
    if (message) {
      await notifyUser({ ...message, bookingId });
    }
  });

// ---------------------------------------------------------------------------
// Main router — bot detection + snapshot serving for musician/blog/event/home
// ---------------------------------------------------------------------------
exports.ssrRouter = functions.https.onRequest(async (req, res) => {
  const userAgent = req.get('user-agent') || '';

  if (!isBot(userAgent)) {
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(getAppShellHtml());
    return;
  }

  const urlPath = req.path.replace(/\/+$/, '') || '/';
  let html = null;

  try {
    if (urlPath === '/') {
      html = await renderHome();
    } else if (urlPath.startsWith('/musicians/')) {
      html = await renderMusicianProfile(urlPath.split('/')[2]);
    } else if (urlPath.startsWith('/blog/')) {
      html = await renderBlogPost(urlPath.split('/')[2]);
    } else if (urlPath.startsWith('/events/')) {
      html = await renderEvent(urlPath.split('/')[2]);
    }
  } catch (e) {
    functions.logger.error('SSR render failed', e);
  }

  if (html) {
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } else {
    // Unknown/unsupported path, or the document didn't exist — fall
    // back to the real app shell rather than a bare error, since a
    // crawler hitting an edge case shouldn't get a broken response.
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(getAppShellHtml());
  }
});
