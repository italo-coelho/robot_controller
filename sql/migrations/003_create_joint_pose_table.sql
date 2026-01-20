CREATE TABLE IF NOT EXISTS joint_pose (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  j1         REAL NOT NULL,
  j2         REAL NOT NULL,
  j3         REAL NOT NULL,
  j4         REAL NOT NULL,
  j5         REAL NOT NULL,
  j6         REAL NOT NULL,
  config     INTEGER NOT NULL DEFAULT -1,
  created_at TEXT DEFAULT (datetime('now'))
);
