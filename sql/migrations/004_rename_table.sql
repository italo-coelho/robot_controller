-- Tables were previously named cartesian_pose and joint_pose.
-- They are now created directly as tcp and joint in earlier migrations.
-- This migration renames them if the old names still exist (for legacy databases).

ALTER TABLE cartesian_pose RENAME TO tcp;
ALTER TABLE joint_pose RENAME TO joint;
