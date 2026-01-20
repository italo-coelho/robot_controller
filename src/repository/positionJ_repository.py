from db.db_manager import DB_Manager
from model.positionJ_model import PositionJModel

class PositionJRepository:
    def __init__(self):
        self.db = DB_Manager()

    def get_all_poses(self) -> list[PositionJModel]:
        sql = self.db.load_sql("joints", "select_all.sql")
        rows = self.db.fetch_all(sql)
        return [PositionJModel(**row) for row in rows]

    def insert_pose(self, pose: PositionJModel) -> None:
        sql = self.db.load_sql("joints", "insert_pose.sql")
        self.db.execute(sql, {
            "name": pose.name,  
            "j1": pose.j1,
            "j2": pose.j2,
            "j3": pose.j3,
            "j4": pose.j4,
            "j5": pose.j5,
            "j6": pose.j6,
            "config": pose.config
        })

    def delete_all_poses(self) -> None:
        sql = self.db.load_sql("joints", "delete_all.sql")
        self.db.execute(sql)
    
    def delete_pose(self, name) -> None:
        sql = self.db.load_sql("joints", "delete_pose.sql")
        self.db.execute(sql, {
            "name": name
        })
      
    def update_pose(self, pose: PositionJModel, actualName: str) -> None:
        sql = self.db.load_sql("joints", "update_pose.sql")
        self.db.execute(sql, {
            "actualName": actualName,
            "name": pose.name,
            "j1": pose.j1,
            "j2": pose.j2,
            "j3": pose.j3,
            "j4": pose.j4,
            "j5": pose.j5,
            "j6": pose.j6,
            "config": pose.config
        })
