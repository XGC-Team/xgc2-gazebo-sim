# xgc2-gazebo-sim

This repository is the aggregate entrypoint for the XGC2 ROS Noetic Gazebo
Classic simulation suite.  Each simulator component is built and released by its
own child product repository; this repository publishes the installable meta
package:

```text
ros-noetic-xgc2-gazebo-sim
```

`ros-noetic-xgc2-gazebo-sim-all` is kept as a compatibility package that
depends on the main meta package.

## Child Packages

The main aggregate package depends on these child package names:

```text
ros-noetic-xgc2-gazebo-sim-manager
ros-noetic-xgc2-gazebo-sim-examples
ros-noetic-xgc2-gazebo-sim-visualization
ros-noetic-xgc2-gazebo-sim-vrpn-bridge
ros-noetic-xgc2-gazebo-sim-scout
ros-noetic-xgc2-gazebo-sim-px4-1-12
ros-noetic-xgc2-gazebo-sim-px4-1-14
ros-noetic-xgc2-gazebo-sim-fs150-sitl
ros-noetic-vrpn-client-ros
```

## Compatibility Rules

- Child repositories own their Debian package payloads and can publish compatible
  packaging revisions independently.
- Source checkouts for active pre-product iteration stay in the ROS1 dev
  workspace. This aggregate records compatible APT dependencies instead of
  duplicating those source packages.
- The aggregate package uses minimum child versions in `Depends`, so apt upgrades
  stale installed children when a quickstart needs newer launch/config assets.
- Child packages may pin internal split-package dependencies when payloads must
  match exactly, for example a PX4 Gazebo package depending on its matching PX4
  runtime package.
- Bump the child product version when that child package changes.
- Bump the aggregate product version when the dependency set, package naming, or
  compatibility contract changes.
- `.xgc2/release-set.yml` records the intended release set for orchestration,
  audit, and aggregate minimum-version dependencies.

The `1.1.0-37` aggregate requires `gazebo_sim_manager` and
`gazebo_sim_examples` `1.1.0-23` or newer. That tools release includes the
closed-loop FS150 NMPC command helper used after the simulation stack is ready:

```bash
rosrun gazebo_sim_examples uav_auto_takeoff_track.py --ns uav1 --height 3.0
```

The helper returns success only after takeoff, transition to `custom1`, and two
new successful NMPC debug samples have all been confirmed.

## Release

Each child repository owns its local `ci.yml` and `release.yml` workflows. The
top-level `xgc2-devops` release orchestrator reads product metadata, triggers the
child `release.yml` workflows by DAG layer, waits for the child packages to
appear in the APT repository, then triggers this aggregate repository release.
