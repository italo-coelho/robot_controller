from PySide6.QtCore import QObject, Slot, Signal, QTimer
from repository.position_repository import PositionRepository
from repository.positionJ_repository import PositionJRepository
from model.position_model import PositionModel
from model.positionJ_model import PositionJModel
from services.robot_service import RobotService

_SERVICE = RobotService()

class PositionController(QObject):
    posesLoaded = Signal(list)
    currentPoseLoaded = Signal(dict)
    currentJointPoseLoaded = Signal(dict)
    databaseChanged = Signal(str)   # emits the new db file path
    robotStatusChanged = Signal(bool, str)  # connected, ip
    robotStatesUpdated = Signal(dict)       # estop, collision, enable
    jogStateUpdated    = Signal(dict)       # tcp[6] + joints[6] from state pkg

    def __init__(self):
        super().__init__()
        self.repo = PositionRepository()
        self.repoJ = PositionJRepository()
        self._jog_timer = QTimer(self)
        self._jog_timer.setInterval(100)
        self._jog_timer.timeout.connect(self._poll_jog_state)
        self._jog_timer.start()

        self._status_timer = QTimer(self)
        self._status_timer.setInterval(200)
        self._status_timer.timeout.connect(self._poll_robot_states)
        self._status_timer.start()

    @Slot(str)
    def connect_robot(self, ip: str) -> None:
        """Attempt to connect (or reconnect) to the robot at the given IP."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            RobotSingletonRCP(ip)
            print(f"[PositionController] Robot connected at {ip}")
            self.robotStatusChanged.emit(True, ip)
        except Exception as e:
            print(f"[PositionController] Robot connection failed: {e}")
            self.robotStatusChanged.emit(False, ip)

    def _poll_robot_states(self) -> None:
        """Called by QTimer every 200 ms — reads robot_state_pkg directly."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            pkg = RobotSingletonRCP().robot_state_pkg
            self.robotStatesUpdated.emit({
                "estop":     int(pkg.EmergencyStop),
                "collision": int(pkg.collisionState),
                "enable":    int(pkg.rbtEnableState),
            })
        except Exception:
            pass

    def _poll_jog_state(self) -> None:
        """Called by QTimer every 100 ms — reads robot_state_pkg directly, no XML-RPC."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            pkg = RobotSingletonRCP().robot_state_pkg
            self.jogStateUpdated.emit({
                "tcp":    [float(pkg.tl_cur_pos[i]) for i in range(6)],
                "joints": [float(pkg.jt_cur_pos[i]) for i in range(6)],
            })
        except Exception:
            pass

    @Slot()
    def reset_all_error(self) -> None:
        """Clear all robot errors."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            robot = RobotSingletonRCP()
            robot.ResetAllError()
            print("[PositionController] ResetAllError called")
        except Exception as e:
            print(f"[PositionController] ResetAllError failed: {e}")

    @Slot(int)
    def robot_enable(self, state: int) -> None:
        """Enable (state=1) or disable (state=0) the robot."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            robot = RobotSingletonRCP()
            robot.RobotEnable(state)
            print(f"[PositionController] RobotEnable({state}) called")
        except Exception as e:
            print(f"[PositionController] RobotEnable failed: {e}")

    @Slot(int)
    def set_speed(self, speed: int) -> None:
        """Set robot speed (1-100%)."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            robot = RobotSingletonRCP()
            robot.SetSpeed(speed)
            print(f"[PositionController] Speed set to {speed}%")
        except Exception as e:
            print(f"[PositionController] Failed to set speed: {e}")

    @Slot(str)
    def set_database(self, path: str) -> None:
        """Switch to an external .db file and reload all poses."""
        from db.db_manager import DB_Manager
        DB_Manager.set_custom_path(path)
        db = DB_Manager()
        db.init_database()
        self.databaseChanged.emit(path)
        self.load_poses()
    
    @Slot()
    def get_current_pose(self): 
        position_model = _SERVICE.get_current_pose()
        if position_model:
            self.currentPoseLoaded.emit(position_model.as_dict())
    
    @Slot()
    def get_current_joint_pose(self): 
        position_model = _SERVICE.get_current_joint_pose()
        if position_model:
            self.currentJointPoseLoaded.emit(position_model.as_dict())

    @Slot(str, float, float, float, float, float, float)
    def move_j(self, name, x, y, z, rx, ry, rz): 
        points = PositionModel(
            id=None,
            name=name,
            x=x,
            y=y,
            z=z,
            rx=rx,
            ry=ry,
            rz=rz
        )

        _SERVICE.move(points)
    
    @Slot()
    def stop_motion(self):
        _SERVICE.stop_motion()

    @Slot(str, int, float)
    def jog_cartesian(self, axis: str, direction: int, step: float) -> None:
        """Jog in base-frame cartesian space.
        axis: 'x'|'y'|'z'|'rx'|'ry'|'rz', direction: 1 or -1, step: mm / degrees.
        Moves to current_pose + delta; call stop_motion() on button release."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            robot = RobotSingletonRCP()
            res = robot.GetActualTCPPose()
            if not isinstance(res, tuple):
                return
            _, pose = res
            target = [float(v) for v in pose[:6]]
            idx = {'x': 0, 'y': 1, 'z': 2, 'rx': 3, 'ry': 4, 'rz': 5}.get(axis, -1)
            if idx < 0:
                return
            target[idx] += direction * step
            cfg = robot.GetRobotCurJointsConfig()
            config = cfg[1] if isinstance(cfg, tuple) and cfg[0] == 0 else -1
            ik = robot.GetInverseKin(desc_pos=target, type=0, config=config)
            if isinstance(ik, tuple) and ik[0] == 0:
                robot.MoveJ(joint_pos=ik[1], tool=1, user=0, vel=100, blendT=0)
        except Exception as e:
            print(f"[PositionController] jog_cartesian failed: {e}")

    @Slot(int, int, float)
    def jog_joint(self, joint_idx: int, direction: int, step: float) -> None:
        """Jog a single joint. joint_idx: 0–5, direction: 1 or -1, step: degrees."""
        from utils.robot_singleton import RobotSingletonRCP
        try:
            robot = RobotSingletonRCP()
            res = robot.GetActualJointPosDegree(0)
            if not isinstance(res, tuple):
                return
            _, joints = res
            target = [float(j) for j in joints[:6]]
            target[joint_idx] += direction * step
            robot.MoveJ(joint_pos=target, tool=1, user=0, vel=100, blendT=0)
        except Exception as e:
            print(f"[PositionController] jog_joint failed: {e}")

    @Slot(str, float, float, float, float, float, float)
    def move_joints(self, name, j1, j2, j3, j4, j5, j6):
        points = PositionJModel(
            id=None,
            name=name,
            j1=j1,
            j2=j2,
            j3=j3,
            j4=j4,
            j5=j5,
            j6=j6
        )

        _SERVICE.move_joints(points)

    @Slot(str, str, str)
    def move_j_with_offset(self, name, base_csv, offset_csv):
        """base_csv: 'x,y,z,rx,ry,rz'  offset_csv: 'dx,dy,dz,drx,dry,drz'"""
        print(f"[CTRL] move_j_with_offset name={name} base={base_csv} offset={offset_csv}")
        b = [float(v) if v and v != 'NaN' else 0.0 for v in base_csv.split(",")]
        o = [float(v) if v and v != 'NaN' else 0.0 for v in offset_csv.split(",")]
        points = PositionModel(id=None, name=name,
                               x=b[0], y=b[1], z=b[2], rx=b[3], ry=b[4], rz=b[5],
                               dx=o[0], dy=o[1], dz=o[2], drx=o[3], dry=o[4], drz=o[5])
        _SERVICE.move_with_offset(points)

    @Slot(str, str, str)
    def move_joints_with_offset(self, name, base_csv, offset_csv):
        """base_csv: 'j1,j2,j3,j4,j5,j6'  offset_csv: 'dx,dy,dz,drx,dry,drz'"""
        print(f"[CTRL] move_joints_with_offset name={name} base={base_csv} offset={offset_csv}")
        b = [float(v) if v and v != 'NaN' else 0.0 for v in base_csv.split(",")]
        o = [float(v) if v and v != 'NaN' else 0.0 for v in offset_csv.split(",")]
        points = PositionJModel(id=None, name=name,
                                j1=b[0], j2=b[1], j3=b[2], j4=b[3], j5=b[4], j6=b[5],
                                dx=o[0], dy=o[1], dz=o[2], drx=o[3], dry=o[4], drz=o[5])
        _SERVICE.move_joints_with_offset(points)

    @Slot()
    def load_poses(self):
        cartesian_poses = self.repo.get_all_poses()
        joint_poses = self.repoJ.get_all_poses()
        
        # Combina ambas as listas e adiciona um campo 'type' para identificar
        all_poses = []
        for pose in cartesian_poses:
            pose_dict = pose.as_dict()
            pose_dict['type'] = 'cartesian'
            all_poses.append(pose_dict)
        
        for pose in joint_poses:
            pose_dict = pose.as_dict()
            pose_dict['type'] = 'joint'
            all_poses.append(pose_dict)
        
        self.posesLoaded.emit(all_poses)

    @Slot()
    def delete_all_poses(self):
        self.repo.delete_all_poses()
        self.repoJ.delete_all_poses()
        self.load_poses()

    @Slot(str)
    def delete_pose(self, name):
        # Tenta deletar de ambos os repositórios (pode não existir em um deles)
        try:
            self.repo.delete_pose(name)
        except:
            pass
        try:
            self.repoJ.delete_pose(name)
        except:
            pass
        self.load_poses()
    
    @Slot(str, str)
    def delete_pose_by_type(self, name, pose_type):
        if pose_type == "joint":
            self.repoJ.delete_pose(name)
        else:
            self.repo.delete_pose(name)
        self.load_poses()

    @Slot(str, float, float, float, float, float, float)
    def save_pose(self, name, x, y, z, rx, ry, rz):
        print(f"[POSITION_CONTROLLER] SALVAR - Tipo: CARTESIANO")
        print(f"[POSITION_CONTROLLER] Nome: {name}, X: {x}, Y: {y}, Z: {z}, RX: {rx}, RY: {ry}, RZ: {rz}")
        poses = self.repo.get_all_poses()
        for p in poses:
            if p.name == name:
                print(f"[POSITION_CONTROLLER] AVISO: Posição '{name}' já existe (cartesiano), não será salva")
                return

        config = -1
        try:
            from utils.robot_singleton import RobotSingletonRCP
            robot = RobotSingletonRCP()
            result = robot.GetRobotCurJointsConfig()
            if isinstance(result, tuple):
                error, data = result
                if error == 0:
                    config = data
        except Exception:
            pass

        pose = PositionModel(
            id=None,
            name=name,
            x=x,
            y=y,
            z=z,
            rx=rx,
            ry=ry,
            rz=rz,
            config=config,
            created_at=None
        )
        self.repo.insert_pose(pose)
        print(f"[POSITION_CONTROLLER] Posição cartesiana '{name}' salva com sucesso")
        self.load_poses()
    
    @Slot(str, float, float, float, float, float, float)
    def save_joint_pose(self, name, j1, j2, j3, j4, j5, j6): 
        print(f"[POSITION_CONTROLLER] SALVAR - Tipo: JUNTAS")
        print(f"[POSITION_CONTROLLER] Nome: {name}, J1: {j1}, J2: {j2}, J3: {j3}, J4: {j4}, J5: {j5}, J6: {j6}")
        poses = self.repoJ.get_all_poses()  
        for p in poses:
            if p.name == name:
                print(f"[POSITION_CONTROLLER] AVISO: Posição '{name}' já existe (juntas), não será salva")
                return
            
        pose = PositionJModel(
            id=None,
            name=name,
            j1=j1,
            j2=j2,
            j3=j3,
            j4=j4,
            j5=j5,
            j6=j6,
            created_at=None
        )
        self.repoJ.insert_pose(pose)
        print(f"[POSITION_CONTROLLER] Posição de juntas '{name}' salva com sucesso")
        self.load_poses()

    @Slot( str, str, float, float, float, float, float, float)
    def update_pose(self,actualName, name, x, y, z, rx, ry, rz):

        if actualName != name:
            poses = self.repo.get_all_poses()  
            for p in poses:
                if p.name == name:
                    print(f"[POSITION_CONTROLLER] AVISO: Nome '{name}' já existe (cartesiano), não será atualizado")
                    return
                
        pose = PositionModel(
            id=None,
            name=name,
            x=x, 
            y=y, 
            z=z,
            rx=rx, 
            ry=ry, 
            rz=rz
        )
        self.repo.update_pose(pose, actualName)
        print(f"[POSITION_CONTROLLER] Posição cartesiana '{actualName}' atualizada para '{name}' com sucesso")
        self.load_poses()

    @Slot(str, float, float, float, float, float, float)
    def update_pose_offset(self, actualName, dx, dy, dz, drx, dry, drz):
        pose = PositionModel(
            id=None,
            name=actualName,
            dx=dx,
            dy=dy,
            dz=dz,
            drx=drx,
            dry=dry,
            drz=drz
        )
        self.repo.update_offset(pose, actualName)
        print(f"[POSITION_CONTROLLER] Offset cartesiano '{actualName}' atualizado com sucesso")
        self.load_poses()
    
    @Slot( str, str, float, float, float, float, float, float)
    def update_joint_pose(self, actualName, name, j1, j2, j3, j4, j5, j6):
        print(f"[POSITION_CONTROLLER] ATUALIZAR - Tipo: JUNTAS")
        print(f"[POSITION_CONTROLLER] Nome atual: {actualName}, Novo nome: {name}")
        print(f"[POSITION_CONTROLLER] Valores: J1: {j1}, J2: {j2}, J3: {j3}, J4: {j4}, J5: {j5}, J6: {j6}")

        if actualName != name:
            poses = self.repoJ.get_all_poses()  
            for p in poses:
                if p.name == name:
                    print(f"[POSITION_CONTROLLER] AVISO: Nome '{name}' já existe (juntas), não será atualizado")
                    return
                
        pose = PositionJModel(
            id=None,
            name=name,
            j1=j1, 
            j2=j2, 
            j3=j3,
            j4=j4, 
            j5=j5, 
            j6=j6
        )
        self.repoJ.update_pose(pose, actualName)
        print(f"[POSITION_CONTROLLER] Posição de juntas '{actualName}' atualizada para '{name}' com sucesso")
        self.load_poses()

    @Slot(str, float, float, float, float, float, float)
    def update_joint_offset(self, actualName, dx, dy, dz, drx, dry, drz):
        pose = PositionJModel(
            id=None,
            name=actualName,
            dx=dx,
            dy=dy,
            dz=dz,
            drx=drx,
            dry=dry,
            drz=drz
        )
        self.repoJ.update_offset(pose, actualName)
        print(f"[POSITION_CONTROLLER] Offset de juntas '{actualName}' atualizado com sucesso")
        self.load_poses()

