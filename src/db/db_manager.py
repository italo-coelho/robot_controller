import sqlite3
from pathlib import Path
from functools import lru_cache
from contextlib import contextmanager
from typing import Generator, Any

class DB_Manager:
    _custom_db_path = None  # class-level override shared by all instances

    @classmethod
    def set_custom_path(cls, path: str) -> None:
        cls._custom_db_path = Path(path)

    def __init__(self, db_name: str = "points.db"):
        self._base_dir = Path(__file__).resolve().parent
        self._sql_dir = self._base_dir / "../../sql"
        self._migrations_dir = self._sql_dir / "migrations"
        self._default_db_path = self._base_dir / db_name

    @property
    def _db_path(self):
        return DB_Manager._custom_db_path if DB_Manager._custom_db_path is not None else self._default_db_path

    @contextmanager
    def _connect(self) -> Generator[sqlite3.Connection, None, None]:
        connection = sqlite3.connect(self._db_path)
        connection.row_factory = sqlite3.Row
        try:
            yield connection
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            connection.close()

    @lru_cache(maxsize=128)
    def load_sql(self, *parts: str) -> str:
        sql_path = self._sql_dir.joinpath(*parts)
        if not sql_path.exists():
            raise FileNotFoundError(f"SQL file not found: {sql_path}")
        return sql_path.read_text(encoding="utf-8")

    def _get_all_migrations(self) -> list[Path]:
        """Retorna todas as migrations ordenadas"""
        migration_files = sorted(self._migrations_dir.glob("*.sql"))
        return migration_files

    def _get_latest_migration(self) -> Path | None:
        migration_files = self._get_all_migrations()
        return migration_files[-1] if migration_files else None

    def _column_exists(self, table_name: str, column_name: str) -> bool:
        if not table_name.replace("_", "").replace("-", "").isalnum():
            return False
        if not column_name.replace("_", "").replace("-", "").isalnum():
            return False
        
        with self._connect() as connection:
            cursor = connection.cursor()
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            return any(col[1] == column_name for col in columns)

    def _table_exists(self, table_name: str) -> bool:
        if not table_name.replace("_", "").replace("-", "").isalnum():
            return False

        with self._connect() as connection:
            cursor = connection.cursor()
            cursor.execute(
                "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
                (table_name,),
            )
            return cursor.fetchone() is not None

    def apply_latest_migration(self) -> None:
        latest = self._get_latest_migration()
        if not latest:
            print("[DB] No migration found.")
            return
        self._apply_migration(latest)

    def apply_all_migrations(self) -> None:
        """Aplica todas as migrations que ainda não foram aplicadas"""
        migrations = self._get_all_migrations()
        if not migrations:
            print("[DB] No migrations found.")
            return
        
        for migration in migrations:
            try:
                self._apply_migration(migration)
            except sqlite3.OperationalError as e:
                # Se a coluna já existe, ignora o erro
                if "duplicate column" in str(e).lower() or "already exists" in str(e).lower():
                    print(f"[DB] Migration {migration.name} already applied or column exists, skipping...")
                else:
                    raise

    def _apply_migration(self, migration_path: Path) -> None:
        """Aplica uma migration específica"""
        script = migration_path.read_text(encoding="utf-8")
        
        # Verificação especial para migration de adicionar coluna
        if "ADD COLUMN" in script.upper() and "config" in script:
            column_name = "config"
            if self._column_exists("tcp", column_name):
                print(f"[DB] Column {column_name} already exists, skipping migration {migration_path.name}")
                return
        
        with self._connect() as connection:
            try:
                connection.executescript(script)
                print(f"[DB] Applied migration: {migration_path.name}")
            except sqlite3.OperationalError as e:
                error_message = str(e).lower()
                # Se a coluna já existe, ignora o erro
                if "duplicate column" in error_message or "already exists" in error_message:
                    print(f"[DB] Migration {migration_path.name} - column already exists, skipping...")
                # Se a tabela não existe em um RENAME, ignora o erro
                elif "no such table" in error_message and "rename to" in script.lower():
                    print(f"[DB] Migration {migration_path.name} - table missing, skipping rename...")
                # Se o destino já existe em um RENAME, ignora o erro
                elif "another table or index with this name" in error_message and "rename to" in script.lower():
                    print(f"[DB] Migration {migration_path.name} - target already exists, skipping rename...")
                # Se a tabela não existe em um ADD COLUMN, ignora o erro
                elif "no such table" in error_message and "add column" in script.lower():
                    print(f"[DB] Migration {migration_path.name} - table missing, skipping add column...")
                else:
                    raise

    def execute(self, sql: str, params: dict[str, Any] | None = None) -> None:
        with self._connect() as connection:
            connection.execute(sql, params or {})

    def fetch_one(self, sql: str, params: dict[str, Any] | None = None) -> dict[str, Any] | None:
        with self._connect() as connection:
            result = connection.execute(sql, params or {}).fetchone()
            return dict(result) if result else None

    def fetch_all(self, sql: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
        with self._connect() as connection:
            rows = connection.execute(sql, params or {}).fetchall()
            return [dict(row) for row in rows]

    def init_database(self) -> None:
        print(f"[DB] Starting database: {self._db_path}")
        self.apply_all_migrations()
        print("[DB] Database ready")
