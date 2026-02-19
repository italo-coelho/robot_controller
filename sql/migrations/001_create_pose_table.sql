CREATE TABLE IF NOT EXISTS tcp (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL,
  x          REAL NOT NULL,
  y          REAL NOT NULL,
  z          REAL NOT NULL,
  rx         REAL NOT NULL,
  ry         REAL NOT NULL,
  rz         REAL NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);
