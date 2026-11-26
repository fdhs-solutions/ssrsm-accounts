import db from '../config/db.js';

export const UserModel = {
  async findByUsernameOrEmail(identifier) {
    const result = await db.query(
      `SELECT
         users_id AS id,
         users_username AS username,
         users_email AS email,
         users_password_hash AS password_hash,
         users_role AS role,
         users_is_active AS is_active
       FROM users
       WHERE (LOWER(users_username) = LOWER($1) OR LOWER(users_email) = LOWER($1))
         AND users_is_delete = FALSE`,
      [identifier]
    );
    return result.rows[0] || null;
  },

  async findById(id) {
    const result = await db.query(
      `SELECT
         users_id AS id,
         users_username AS username,
         users_email AS email,
         users_password_hash AS password_hash,
         users_role AS role,
         users_is_active AS is_active
       FROM users
       WHERE users_id = $1 AND users_is_delete = FALSE`,
      [id]
    );
    return result.rows[0] || null;
  },

  async saveResetToken(userId, tokenHash, expiresAt) {
    await db.query(
      `UPDATE users
       SET users_reset_token_hash = $2,
           users_reset_token_expires_at = $3
       WHERE users_id = $1 AND users_is_delete = FALSE`,
      [userId, tokenHash, expiresAt]
    );
  },

  async findByValidResetToken(tokenHash) {
    const result = await db.query(
      `SELECT
         users_id AS id,
         users_username AS username,
         users_email AS email
       FROM users
       WHERE users_reset_token_hash = $1
         AND users_reset_token_expires_at > CURRENT_TIMESTAMP
         AND users_is_active = TRUE
         AND users_is_delete = FALSE`,
      [tokenHash]
    );
    return result.rows[0] || null;
  },

  async updatePassword(userId, passwordHash) {
    const result = await db.query(
      `UPDATE users
       SET users_password_hash = $2,
           users_reset_token_hash = NULL,
           users_reset_token_expires_at = NULL
       WHERE users_id = $1 AND users_is_delete = FALSE
       RETURNING users_id AS id, users_username AS username, users_email AS email`,
      [userId, passwordHash]
    );
    return result.rows[0] || null;
  },
};
