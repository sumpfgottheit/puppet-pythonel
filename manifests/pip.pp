# == Define: python::pip
#
# Executes pip install in an virtualenv
#
# === Parameters
#
# [*virtualenv*]
#  The virtualenv to execute pip in. Can be undef if no virtualenv is used. Default: undef
#
# [*interpreter*]
#  Python interpreter to use. The interpreters are defined in manifests/interpreter/${interpreter}.pp
#  Default: system
#
# [*pip_config_file*]
# pip.conf to use. Will set the environment variable PIP_CONFIG_FILE. Default: undef
#
# [*environment*]
#  Additional environment variables required to install the packages.
#
# [*path*]
#  Specifies the PATH variable. Default: [ '/bin', '/usr/bin', '/usr/sbin' ]
#
# [*cwd*]
#  The directory from which to run the "pip install" command. Default: undef
#
# [*timeout*]
#  The maximum time in seconds the "pip install" command should take. Default: 1800
#
# [*extra_pip_args*]
#  Extra arguments to pass to pip after requirements file.  Default: blank
#
# === Examples
#
#  python::pip { 'project1-colorama':
#    package     => 'colorama',
#    virtualenv  => '/opt/virtualenvs/project1',
#    interpreter => 'rh-python34-scl'
#  }
# === Authors
#
# Florian Sachs
#
define python::pip (
  $package           = $name,
  $virtualenv        = undef,
  $interpreter       = undef,
  $pip_config_file   = undef,
  $environment       = [],
  $path              = [ '/bin', '/usr/bin', '/usr/sbin', '/usr/local/bin' ],
  $cwd               = undef,
  $timeout           = 1800,
  $extra_pip_args    = '',
) {

  $bindir                     = inline_template("<%= scope['python::interpreter::${interpreter}::bindir'] %>")
  $python                     = inline_template("<%= scope['python::interpreter::${interpreter}::python'] %>")
  $pip                        = inline_template("<%= scope['python::interpreter::${interpreter}::pip'] %>")
  $interpreter_extra_pip_args = inline_template("<%= scope['python::interpreter::${interpreter}::extra_pip_args'] %>")
  $base_script_dir            = inline_template("<%= scope['python::interpreter::${interpreter}::base_script_dir'] %>")
  $ppyp_helper                = '/usr/local/bin/ppyp_helper'

  # Ensure that the interpreter is installed before creating the virtal environment -> require this class
  $interpreter_class = "python::interpreter::$interpreter"

  $_environment = $pip_config_file ? {
    undef   => $environment,
    default => concat($environment, "PIP_CONFIG_FILE=$pip_config_file")
  }

  $_extra_pip_args = $base_script_dir ? {
    ""      => "$interpreter_extra_pip_args $extra_pip_args",
    default => "--install-option='--install-scripts=$base_script_dir' $interpreter_extra_pip_args $extra_pip_args"
  }

  $_pip = $virtualenv ? {
    undef   => "$pip",                # Without virtualenv, use "base"-pip of provided interpreter
    default => "pip -v $virtualenv"   # Just call the pip within the virtualenv. The ppyp_helper takes care of scl
  }

  exec { "pip_install_${name}_${interpreter}_${virtualenv}":
    command     => "$ppyp_helper $_pip install $package $_extra_pip_args",
    path        => $path,
    cwd         => $cwd,
    environment => $_environment,
    require     => [File[$ppyp_helper], Class[$interpreter_class]],
  }

}
