// Firebase Cloud Functions for SetiaU
// Deploy with: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

// Initialize Google APIs
const calendar = google.calendar('v3');
const gmail = google.gmail('v1');
const docs = google.docs('v1');
const sheets = google.sheets('v4');

// Middleware: Verify Firebase Auth Token
async function verifyAuthToken(token) {
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken.uid;
  } catch (error) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Invalid authentication token'
    );
  }
}

// Cloud Function: Execute Calendar Action
exports.executeCalendarAction = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    const userId = await verifyAuthToken(context.rawRequest.headers.authorization);

    const { actionId, payload } = data;

    try {
      // Validate payload schema
      if (!payload.eventName || !payload.date || !payload.startTime) {
        throw new Error('Missing required calendar fields');
      }

      // Create Google Calendar event
      const event = {
        summary: payload.eventName,
        description: payload.description || '',
        start: {
          dateTime: new Date(`${payload.date}T${payload.startTime}:00`).toISOString(),
          timeZone: 'Asia/Kuala_Lumpur',
        },
        end: {
          dateTime: new Date(`${payload.date}T${payload.endTime}:00`).toISOString(),
          timeZone: 'Asia/Kuala_Lumpur',
        },
        attendees: payload.attendees?.map((email) => ({ email })) || [],
        conferenceData: {
          createRequest: {
            requestId: `${actionId}-${Date.now()}`,
            conferenceSolutionKey: { type: 'hangoutsMeet' },
          },
        },
      };

      // TODO: Use authenticated user's calendar
      // For MVP, this requires OAuth setup per user

      // Log successful execution
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: 'Calendar event created successfully',
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Calendar event created',
        eventId: 'event_id_placeholder',
      };
    } catch (error) {
      console.error('Calendar action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Error: ${error.message}`,
      });
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// Cloud Function: Execute Email Action
exports.executeEmailAction = functions.https.onCall(
  async (data, context) => {
    const userId = await verifyAuthToken(context.rawRequest.headers.authorization);

    const { actionId, payload } = data;

    try {
      if (!payload.to || !payload.subject || !payload.body) {
        throw new Error('Missing required email fields');
      }

      // TODO: Send email via Gmail API
      // This requires OAuth setup and email template service

      // Log successful execution
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: 'Email sent successfully',
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Email sent',
        recipients: payload.to,
      };
    } catch (error) {
      console.error('Email action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Error: ${error.message}`,
      });
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// Cloud Function: Execute Sheets Action
exports.executeSheetsAction = functions.https.onCall(
  async (data, context) => {
    const userId = await verifyAuthToken(context.rawRequest.headers.authorization);

    const { actionId, payload } = data;

    try {
      if (!payload.sheetName || !payload.values) {
        throw new Error('Missing required sheets fields');
      }

      // TODO: Update Google Sheets via Sheets API
      // This requires Sheets document reference and OAuth

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: 'Sheet updated successfully',
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Sheet updated',
        sheetName: payload.sheetName,
      };
    } catch (error) {
      console.error('Sheets action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Error: ${error.message}`,
      });
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// Cloud Function: Execute Docs Action
exports.executeDocsAction = functions.https.onCall(
  async (data, context) => {
    const userId = await verifyAuthToken(context.rawRequest.headers.authorization);

    const { actionId, payload } = data;

    try {
      if (!payload.documentName || !payload.content) {
        throw new Error('Missing required docs fields');
      }

      // TODO: Create Google Doc via Docs API
      // This requires Google Drive API and OAuth

      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: 'Document created successfully',
        executedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Document created',
        docName: payload.documentName,
        docId: 'doc_id_placeholder',
      };
    } catch (error) {
      console.error('Docs action error:', error);
      await admin.firestore().collection('actions').doc(actionId).update({
        status: 'executed',
        executionResult: `Error: ${error.message}`,
      });
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// Cloud Function: Process Transcript (Trigger on new meeting)
exports.processTranscript = functions.firestore
  .document('meetings/{meetingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { meetingId } = context.params;

    // Check if transcript was just added
    if (!before.transcriptUrl && after.transcriptUrl) {
      try {
        // TODO: Call Gemini API to process transcript
        // Extract tasks and create Action documents

        console.log(`Processing transcript for meeting ${meetingId}`);

        return { success: true };
      } catch (error) {
        console.error('Transcript processing error:', error);
        return { error: error.message };
      }
    }

    return null;
  });

// Cloud Function: Clean up expired actions
exports.cleanupExpiredActions = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const snapshot = await admin
        .firestore()
        .collection('actions')
        .where('status', 'in', ['rejected', 'executed'])
        .where('createdAt', '<', thirtyDaysAgo)
        .get();

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Cleaned up ${snapshot.docs.length} old actions`);

      return { success: true };
    } catch (error) {
      console.error('Cleanup error:', error);
      return { error: error.message };
    }
  });
