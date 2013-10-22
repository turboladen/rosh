# TODO: CLI shell
#   * Make adding shell commands more API-like.
#   * Handle wrong number of args by printing out usage


# TODO: Specs & Docs
#   * remote dir
#   * remote file
#   * remote link
#   x package_managers/apt
#   x package_managers/brew
#   x package_managers/dpkg
#   x package_managers/yum
#   x package_types/base
#   x package_types/brew
#   x package_types/deb
#   x package_types/rpm
#   * service_*/base
#   * service_*/init
#   * service_*/launch_ctl
#   * attributes
#   * file_system
#   * package
#   * package_manager
#   * group
#   * group_manager
#   * user
#   * user_manager

# TODO: API specs
#   x package managers
#   * service managers
#   * service types
#   * shells

# TODO: turn off logging in specs

# TODO: improve logging
#   * Use Shells::Base#good_info, #bad_info, #run_info

# TODO: fix test that's leaving ./test around

# TODO: Remove +status+ from PackageTypes::Base (check with screenplay first).
# TODO: Remove +architecture+ from PackageTypes::Base (check with screenplay first).
# TODO: Serialization of a full Host object (instead of just FileSystemObjects)
# TODO: Handle uninstalled package manager (i.e. brew)

# TODO: Use Shellwords.escape to escape paths that get passed to shell commands.

# TODO: Add IO and Enumerable methods to FileSystem.

# TODO: Add ssh manager for User.
