// Firebase Cloud Functions for SetiaU
// Deploy with: firebase deploy --only functions

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

const SERVICE_ACCOUNT_KEY = defineSecret('GOOGLE_SERVICE_ACCOUNT_KEY');

// Build a GoogleAuth client from the stored service account JSON secret
function getAuthClient(serviceAccountJson) {
  const key = JSON.parse(serviceAccountJson);
  return new google.auth.GoogleAuth({
    credentials: key,
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/documents',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive.file',
    ],
  });
}

// ─── Calendar ───────────────────────────────────────────────────────────────

exports.executeCalendarAction = onCall(
  { secrets: [SERVICE_ACCOUNT_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { actionId, payload } = request.data;

    if (!payload.eventName || !payload.date || !payload.startTime || !payload.endTime) {
      throw new HttpsError('invalid-argument', 'Missing required calendar fields.');
    }

    try {
      const auth = getAuthClient(SERVICE_ACCOUNT_KEY.value());
      const calendarClient = google.calendar({ version: 'v3', auth });

      const startDateTime = new Date(`${payload.date}T${payload.startTime}:00`);
      const endDateTime = new Date(`${payload.date}T${payload.endTime}:00`);

      const event = {
        summary: payload.eventName,
        description: payload.description || '',
        start: {
          dateTime: startDateTime.toISOString(),
          timeZone: 'Asia/Kuala_Lumpur',
        },
        end: {
          dateTime: endDateTime.toISOString(),
          timeZone: 'Asia/Kuala_Lumpur',
        },
        attendees: (payload.attendees || []).map((email) => ({ email })),
        conferenceData: {
          createRequest: {
            requestId: `${actionId}-${Date.now()}`,
            conferenceSolutionKey: { type: 'hangoutsMeet' },
          },
        },
      };

      const response = await calendarClient.events.insert({
        calendarId: payload.calendarId || 'primary',
        resource: event,
        conferenceDataVersion: 1,
        sendUpdates: 'all',
      });

      const createdEvent = response.data;
      const meetLink = createdEvent.hangoutLink || createdEvent.htmlLink;

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Calendar event created: "${createdEvent.summary}" on ${payload.date}. Link: ${meetLink}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { eventId: createdEvent.id, eventLink: createdEvent.htmlLink },
      });

      return {
        success: true,
        message: 'Calendar event created',
        eventId: createdEvent.id,
        eventLink: createdEvent.htmlLink,
        meetLink,
      };
    } catch (error) {
      console.error('Calendar action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'failed',
        executionResult: `Error: ${error.message}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new HttpsError('internal', error.message);
    }
  }
);

// ─── Gmail ───────────────────────────────────────────────────────────────────

exports.executeEmailAction = onCall(
  { secrets: [SERVICE_ACCOUNT_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { actionId, payload } = request.data;

    if (!payload.to || !payload.subject || !payload.body) {
      throw new HttpsError('invalid-argument', 'Missing required email fields.');
    }

    try {
      const auth = getAuthClient(SERVICE_ACCOUNT_KEY.value());
      const gmailClient = google.gmail({ version: 'v1', auth });

      const toAddresses = Array.isArray(payload.to) ? payload.to.join(', ') : payload.to;
      const ccAddresses =
        payload.cc && payload.cc.length > 0 ? payload.cc.join(', ') : null;

      const messageParts = [
        `To: ${toAddresses}`,
        ccAddresses ? `Cc: ${ccAddresses}` : null,
        `Subject: ${payload.subject}`,
        'Content-Type: text/plain; charset=utf-8',
        'MIME-Version: 1.0',
        '',
        payload.body,
      ].filter(Boolean);

      const rawMessage = messageParts.join('\r\n');
      const encodedMessage = Buffer.from(rawMessage)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '');

      const response = await gmailClient.users.messages.send({
        userId: 'me',
        resource: { raw: encodedMessage },
      });

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Email sent to ${toAddresses}. Subject: "${payload.subject}"`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { messageId: response.data.id },
      });

      return {
        success: true,
        message: 'Email sent',
        messageId: response.data.id,
        recipients: toAddresses,
      };
    } catch (error) {
      console.error('Email action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'failed',
        executionResult: `Error: ${error.message}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new HttpsError('internal', error.message);
    }
  }
);

// ─── Google Sheets ───────────────────────────────────────────────────────────

exports.executeSheetsAction = onCall(
  { secrets: [SERVICE_ACCOUNT_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { actionId, payload } = request.data;

    if (!payload.sheetName) {
      throw new HttpsError('invalid-argument', 'Missing required sheets fields.');
    }

    try {
      const auth = getAuthClient(SERVICE_ACCOUNT_KEY.value());
      const sheetsClient = google.sheets({ version: 'v4', auth });
      const driveClient = google.drive({ version: 'v3', auth });

      let spreadsheetId = payload.spreadsheetId;

      // Create a new spreadsheet if no existing ID is provided
      if (!spreadsheetId) {
        const createResponse = await sheetsClient.spreadsheets.create({
          resource: {
            properties: { title: payload.sheetName },
            sheets: [{ properties: { title: 'Sheet1' } }],
          },
        });
        spreadsheetId = createResponse.data.spreadsheetId;

        // Make it readable by anyone with the link
        await driveClient.permissions.create({
          fileId: spreadsheetId,
          resource: { role: 'writer', type: 'anyone' },
        });
      }

      const action = payload.action || 'append';
      const values = payload.values || payload.data?.values || [[]];
      const normalizedValues = Array.isArray(values[0]) ? values : [values];

      if (action === 'append') {
        await sheetsClient.spreadsheets.values.append({
          spreadsheetId,
          range: 'Sheet1',
          valueInputOption: 'USER_ENTERED',
          resource: { values: normalizedValues },
        });
      } else if (action === 'update' && payload.range) {
        await sheetsClient.spreadsheets.values.update({
          spreadsheetId,
          range: payload.range,
          valueInputOption: 'USER_ENTERED',
          resource: { values: normalizedValues },
        });
      }

      const sheetUrl = `https://docs.google.com/spreadsheets/d/${spreadsheetId}`;

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Sheet "${payload.sheetName}" updated. Link: ${sheetUrl}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { spreadsheetId, sheetUrl },
      });

      return { success: true, message: 'Sheet updated', spreadsheetId, sheetUrl };
    } catch (error) {
      console.error('Sheets action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'failed',
        executionResult: `Error: ${error.message}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new HttpsError('internal', error.message);
    }
  }
);

// ─── Google Docs ──────────────────────────────────────────────────────────────

exports.executeDocsAction = onCall(
  { secrets: [SERVICE_ACCOUNT_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { actionId, payload } = request.data;

    if (!payload.documentName || !payload.content) {
      throw new HttpsError('invalid-argument', 'Missing required docs fields.');
    }

    try {
      const auth = getAuthClient(SERVICE_ACCOUNT_KEY.value());
      const docsClient = google.docs({ version: 'v1', auth });
      const driveClient = google.drive({ version: 'v3', auth });

      // Create the document
      const createResponse = await docsClient.documents.create({
        resource: { title: payload.documentName },
      });
      const documentId = createResponse.data.documentId;

      // Insert content
      await docsClient.documents.batchUpdate({
        documentId,
        resource: {
          requests: [{ insertText: { location: { index: 1 }, text: payload.content } }],
        },
      });

      // Share with specific emails or make link-readable
      const sharingEmails = payload.sharing || [];
      if (sharingEmails.length > 0) {
        await Promise.all(
          sharingEmails.map((email) =>
            driveClient.permissions.create({
              fileId: documentId,
              resource: { role: 'writer', type: 'user', emailAddress: email },
              sendNotificationEmail: true,
            })
          )
        );
      } else {
        await driveClient.permissions.create({
          fileId: documentId,
          resource: { role: 'reader', type: 'anyone' },
        });
      }

      const docUrl = `https://docs.google.com/document/d/${documentId}`;

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Document "${payload.documentName}" created. Link: ${docUrl}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { documentId, docUrl },
      });

      return { success: true, message: 'Document created', documentId, docUrl };
    } catch (error) {
      console.error('Docs action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'failed',
        executionResult: `Error: ${error.message}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      throw new HttpsError('internal', error.message);
    }
  }
);

// ─── Firestore trigger: auto-dispatch when action status → 'approved' ────────

exports.onActionApproved = onDocumentUpdated(
  { document: 'actions/{actionId}', secrets: [SERVICE_ACCOUNT_KEY] },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (before.status === after.status || after.status !== 'approved') {
      return null;
    }

    const actionId = event.params.actionId;
    const { actionType, payload = {} } = after;

    console.log(`Action ${actionId} approved, type=${actionType}`);

    await admin.firestore().collection('actions').doc(actionId).update({
      status: 'executing',
    });

    try {
      const auth = getAuthClient(SERVICE_ACCOUNT_KEY.value());
      let result = {};

      if (actionType === 'calendar') {
        const calendarClient = google.calendar({ version: 'v3', auth });
        const startDT = new Date(`${payload.date}T${payload.startTime}:00`);
        const endDT = new Date(`${payload.date}T${payload.endTime}:00`);

        const response = await calendarClient.events.insert({
          calendarId: payload.calendarId || 'primary',
          conferenceDataVersion: 1,
          sendUpdates: 'all',
          resource: {
            summary: payload.eventName,
            description: payload.description || '',
            start: { dateTime: startDT.toISOString(), timeZone: 'Asia/Kuala_Lumpur' },
            end: { dateTime: endDT.toISOString(), timeZone: 'Asia/Kuala_Lumpur' },
            attendees: (payload.attendees || []).map((e) => ({ email: e })),
            conferenceData: {
              createRequest: {
                requestId: `${actionId}-auto`,
                conferenceSolutionKey: { type: 'hangoutsMeet' },
              },
            },
          },
        });

        result = {
          executionResult: `Event "${response.data.summary}" created on ${payload.date}. Link: ${response.data.htmlLink}`,
          metadata: { eventId: response.data.id, eventLink: response.data.htmlLink },
        };
      } else if (actionType === 'email') {
        const gmailClient = google.gmail({ version: 'v1', auth });
        const toAddr = Array.isArray(payload.to) ? payload.to.join(', ') : payload.to;
        const raw = Buffer.from(
          [`To: ${toAddr}`, `Subject: ${payload.subject}`, 'MIME-Version: 1.0', '', payload.body].join('\r\n')
        ).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

        const resp = await gmailClient.users.messages.send({ userId: 'me', resource: { raw } });
        result = {
          executionResult: `Email sent to ${toAddr}. Subject: "${payload.subject}"`,
          metadata: { messageId: resp.data.id },
        };
      } else if (actionType === 'sheets') {
        const sheetsClient = google.sheets({ version: 'v4', auth });
        const driveClient = google.drive({ version: 'v3', auth });
        let spreadsheetId = payload.spreadsheetId;

        if (!spreadsheetId) {
          const cr = await sheetsClient.spreadsheets.create({
            resource: { properties: { title: payload.sheetName }, sheets: [{ properties: { title: 'Sheet1' } }] },
          });
          spreadsheetId = cr.data.spreadsheetId;
          await driveClient.permissions.create({ fileId: spreadsheetId, resource: { role: 'writer', type: 'anyone' } });
        }

        const vals = payload.values || [[]];
        await sheetsClient.spreadsheets.values.append({
          spreadsheetId,
          range: 'Sheet1',
          valueInputOption: 'USER_ENTERED',
          resource: { values: Array.isArray(vals[0]) ? vals : [vals] },
        });

        const sheetUrl = `https://docs.google.com/spreadsheets/d/${spreadsheetId}`;
        result = { executionResult: `Sheet "${payload.sheetName}" updated. Link: ${sheetUrl}`, metadata: { spreadsheetId, sheetUrl } };
      } else if (actionType === 'docs') {
        const docsClient = google.docs({ version: 'v1', auth });
        const driveClient = google.drive({ version: 'v3', auth });

        const cr = await docsClient.documents.create({ resource: { title: payload.documentName } });
        const documentId = cr.data.documentId;
        await docsClient.documents.batchUpdate({
          documentId,
          resource: { requests: [{ insertText: { location: { index: 1 }, text: payload.content } }] },
        });
        await driveClient.permissions.create({ fileId: documentId, resource: { role: 'reader', type: 'anyone' } });

        const docUrl = `https://docs.google.com/document/d/${documentId}`;
        result = { executionResult: `Document "${payload.documentName}" created. Link: ${docUrl}`, metadata: { documentId, docUrl } };
      } else {
        result = { executionResult: `Unknown action type: ${actionType}` };
      }

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...result,
      });
    } catch (error) {
      console.error(`Auto-execution error for ${actionId}:`, error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'failed',
        executionResult: `Execution error: ${error.message}`,
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return null;
  }
);

// ─── Scheduled cleanup ────────────────────────────────────────────────────────

exports.cleanupExpiredActions = onSchedule('every 24 hours', async () => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const snapshot = await admin
      .firestore()
      .collection('actions')
      .where('status', 'in', ['rejected', 'executed', 'failed'])
      .where('createdAt', '<', thirtyDaysAgo)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`Cleaned up ${snapshot.docs.length} old actions`);
    return { success: true };
  } catch (error) {
    console.error('Cleanup error:', error);
    return { error: error.message };
  }
});
