# xgc2-gazebo-sim

This repository is the source and compatibility catalog for the XGC2 ROS
Noetic Gazebo Classic simulation products. It does not publish an aggregate
Debian package.

Each child repository owns and releases its own package. Consumers install
only the products needed by the selected robot and workflow. The current
catalog includes scenes, camera, mecanum, Scout, PX4 SITL, FS150 SITL,
visualization, and the VRPN bridge.

The historical packages `ros-noetic-xgc2-gazebo-sim` and
`ros-noetic-xgc2-gazebo-sim-all` are frozen. They are not rebuilt, promoted,
or used as release gates.

`.xgc2/release-set.yml` remains the compatibility snapshot for auditing and
for selecting independent child products. Every child keeps its own `ci.yml`,
`release.yml`, product metadata, tests, and APT payload.

The `scenes` child owns two ROS packages:

- `gazebo_sim_worlds` contains reusable worlds and model assets.
- `xgc2_gazebo_scene` provides scene direction and obstacle control.

`examples/` is a launch-only child (`gazebo_sim_examples`). It is not in CI,
not in this release set, and not published to APT. Use it to start known
demos by composing the independent robot and controller products.

The retired `gazebo_sim_manager` package is not part of the product or
release graph. XGC2 owns process orchestration directly.
