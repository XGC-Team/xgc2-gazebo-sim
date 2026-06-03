# xgc2-gazebo-sim

This repository is the aggregate entrypoint for the XGC2 ROS Noetic Gazebo
Classic simulation suite.  Each simulator component is built and released by its
own child product repository; this repository publishes the installable meta
package:

```text
ros-noetic-xgc2-gazebo-sim-all
```

## Child Packages

The aggregate package depends on these child package names:

```text
ros-noetic-xgc2-gazebo-sim-manager
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
- The aggregate package must not pin exact child versions in `Depends`; it only
  requires compatible package names.
- Child packages may pin internal split-package dependencies when payloads must
  match exactly, for example a PX4 Gazebo package depending on its matching PX4
  runtime package.
- Bump the child product version when that child package changes.
- Bump the aggregate product version when the dependency set, package naming, or
  compatibility contract changes.
- `.xgc2/release-set.yml` records the intended release set for orchestration and
  audit; it is not used to create strict apt version dependencies for users.

## Central Release

Use the `release-gazebo-sim-all` workflow in `compatible` mode.  It can trigger
child workflows, wait for the child packages to appear in the APT repository,
then publish the aggregate meta package.
