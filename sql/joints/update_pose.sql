UPDATE joint_pose
SET 
    name = :name,
    j1 = :j1,
    j2 = :j2,
    j3 = :j3,
    j4 = :j4,
    j5 = :j5,
    j6 = :j6,
    config = :config
WHERE name = :actualName
