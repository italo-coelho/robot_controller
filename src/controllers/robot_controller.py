from typing import Optional
from services.robot_service import RobotService
from model.position_model import PositionModel
from PySide6.QtCore import QObject, Signal, Slot

class RobotController(QObject):
    campaignsChanged = Signal(list)

    def __init__(self):
        super().__init__()
        self.robotService = RobotService()

    @Slot(result="QVariantList")  # type: ignore
    def get_current_pose(self):
        
        return self.robotService.get_current_pose()
    
    @Slot(result="QVariantList") # type: ignore
    def get_sdk_version(self):
        return self.robotService.get_sdk_version()
    
    @Slot(result="QVariantList") # type: ignore
    def save_current_pose(self, robotModel: PositionModel):
        self.robotService.save_current_pose(robotModel)

    @Slot(result="QVariantList") # type: ignore
    def move_robot_J(self, points: PositionModel):
        self.robotService.move(points)

    @Slot(result="QVariantList") # type: ignore
    def get_pose_list(self, points: PositionModel):
        self.robotService.move(points)

