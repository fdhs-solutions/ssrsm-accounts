import nodemailer from 'nodemailer';
import { env } from '../config/env.js';
import { logger } from '../config/logger.js';

let transporter = null;

function getTransporter() {
  if (env.isTest) return null;
  if (transporter) return transporter;
  if (!env.smtp.host || !env.smtp.user || !env.smtp.pass) return null;

  transporter = nodemailer.createTransport({
    pool: true,
    host: env.smtp.host,
    port: env.smtp.port,
    secure: env.smtp.secure,
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
    auth: {
      user: env.smtp.user,
      pass: env.smtp.pass,
    },
  });

  return transporter;
}

export const EmailService = {
  async sendPasswordResetEmail({ to, username, resetToken }) {
    const mailTransporter = getTransporter();

    if (!mailTransporter) {
      logger.info(
        { to, username, resetCode: resetToken },
        'SMTP credentials not configured; password reset code generated for local development'
      );
      return { delivered: false, devMode: true };
    }

    await mailTransporter.sendMail({
      from: env.smtp.from,
      to,
      subject: 'SSRSM Accounts - Password Reset Code',
      text: `Hello ${username},\n\nYour SSRSM Accounts password reset code is: ${resetToken}\n\nThis code is valid for 15 minutes. Enter it in the SSRSM Accounts app to set a new password.\n\nIf you did not request this, please ignore this email.`,
      html: `<p>Hello <strong>${username}</strong>,</p>
             <p>Your SSRSM Accounts password reset code is:</p>
             <p style="font-size: 24px; font-weight: bold; letter-spacing: 4px; color: #1F4E79;">${resetToken}</p>
             <p>This code is valid for <strong>15 minutes</strong>. Enter it in the SSRSM Accounts app to set a new password.</p>
             <p>If you did not request this, please ignore this email.</p>`,
    });

    return { delivered: true, devMode: false };
  },

  async sendPasswordResetNotification({ username, newPassword }) {
    const to = env.adminNotifyEmail;
    if (!to) return { delivered: false };

    const mailTransporter = getTransporter();
    if (!mailTransporter) {
      logger.info(
        { to, username },
        'SMTP credentials not configured; admin password-reset notification skipped in local dev'
      );
      return { delivered: false, devMode: true };
    }

    await mailTransporter.sendMail({
      from: env.smtp.from,
      to,
      subject: `SSRSM Accounts - Password Reset Alert (${username})`,
      text: `Hello Admin,\n\nThe password for SSRSM Accounts user "${username}" has been reset.\n\nNew Password: ${newPassword}\nTime: ${new Date().toISOString()}`,
      html: `<p>Hello Admin,</p>
             <p>The password for SSRSM Accounts user <strong>${username}</strong> has been reset.</p>
             <p><strong>New Password:</strong> <code>${newPassword}</code></p>
             <p><small>Time: ${new Date().toISOString()}</small></p>`,
    });

    return { delivered: true, devMode: false };
  },
};
