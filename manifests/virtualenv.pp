# == Define: pythonel::virtualenv
#
# Creates Python virtualenv.
#
# === Parameters
#
# [*ensure*]
#  present|absent. Default: present
#
# [*interpreter*]
#  Python interpreter to use. Default: system
#
# [*requirements_file*]
#  Path to pip requirements.txt file. Default: none
#
# [*systempkgs*]
#  Boolean. Create the virtuelenv with --system-site-packages. Default: false
#
# [*venv_dir*]
#  Directory to install virtualenv to. Default: $name
#
# [*pip_config_file*]
# pip.conf to use. Will set the environment variable PIP_CONFIG_FILE. Default: None
#
# [*owner*]
#  The owner of the virtualenv being manipulated. Default: root
#
# [*group*]
#  The group relating to the virtualenv being manipulated. Default: root
#
# [*mode*]
# Optionally specify directory mode. Default: 0755
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
# pythonel::virtualenv { '/var/www/project1':
#   interpreter  => 'system',
#   requirements => '/var/www/project1/requirements.txt',
#   systempkgs   => true,
# }

# pythonel::virtualenv { '/var/www/project2':
#   interpreter     => 'rh-python34-scl',
#   systempkgs      => false,
#   pip_config_file => '/var/www/project2/pip.conf'
# }
#
# === Authors
#
# Florian Sachs
#
# The original puppet-python module, on which this module is based,
# has been written by:
# Sergey Stankevich
# Shiva Poudel
#
define pythonel::virtualenv (
  $ensure            = present,
  $interpreter       = 'system',
  $requirements_file = false,
  $systempkgs        = false,
  $venv_dir          = $name,
  $mode              = '0755',
  $environment       = [],
  $path              = [ '/bin', '/usr/bin', '/usr/sbin', '/usr/local/bin' ],
  $cwd               = undef,
  $timeout           = 1800,
  $extra_pip_args    = '',
) {

  if $ensure == 'present' {
    $bindir                     = inline_template("<%= scope['pythonel::interpreter::${interpreter}::bindir'] %>")
    $python                     = inline_template("<%= scope['pythonel::interpreter::${interpreter}::python'] %>")
    $virtualenv                 = inline_template("<%= scope['pythonel::interpreter::${interpreter}::virtualenv'] %>")
    $pip                        = inline_template("<%= scope['pythonel::interpreter::${interpreter}::pip'] %>")
    $interpreter_extra_pip_args = inline_template("<%= scope['pythonel::interpreter::${interpreter}::extra_pip_args'] %>")
    $base_script_dir            = inline_template("<%= scope['pythonel::interpreter::${interpreter}::base_script_dir'] %>")
    $pythonel_helper            = '/usr/local/bin/pythonel_helper'

    # Ensure that the interpreter is installed before creating the virtal environment -> require this class
    $interpreter_class = "pythonel::interpreter::$interpreter"

    file { $venv_dir:
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => $mode
    }

    $_systempkgs = $systempkgs ? {
      true     => ' --system-site-packages ',
      default  => ''
    }

    $_extra_pip_args = "$interpreter_extra_pip_args $extra_pip_args"

    # set $env_pip_config_file
    $pip_config_file        = hiera("pythonel::interpreter::${interpreter}::pip_config_file", '')
    $global_pip_config_file = hiera("pythonel::interpreter::pip_config_file", '')
    $_pip_config_file = $pip_config_file ? {
        ''       => $global_pip_config_file,
        default  => $pip_config_file
    }
    $env_pip_config_file = $_pip_config_file ? {
        ''      => [],
        default => ["PIP_CONFIG_FILE=$_pip_config_file"]
    }
    # /set $env_pip_config_file
    $_environment = concat($environment, $env_pip_config_file)

    exec { "create_python_virtualenv_${venv_dir}":
      command     => "$pythonel_helper $virtualenv $_systempkgs $venv_dir",
      creates     => "${venv_dir}/bin/activate",
      unless      => "grep '^[\\t ]*VIRTUAL_ENV=[\\\\'\\\"]*${venv_dir}[\\\"\\\\'][\\t ]*$' ${venv_dir}/bin/activate", #Unless activate exists and VIRTUAL_ENV is correct we re-create the virtualenv
      environment => $_environment,
      cwd         => $cwd,
      path        => $path,
      require     => [File[$venv_dir, $pythonel_helper], Class[$interpreter_class], Anchor[$interpreter]],
      user        => $owner,
    }

    if $requirements_file {
      exec { "python_requirements_install_${requirements}_${venv_dir}":
        command     => "$pythonel_helper pip -v $venv_dir install -r $requirements_file $_extra_pip_args",
        onlyif      => "$pythonel_helper pip -v $venv_dir install -r $requirements_file $_extra_pip_args | grep -v 'Requirement already satisfied' | grep -v 'Cleaning up'",
        timeout     => $timeout,
        environment => $_environment,
        cwd         => $cwd,
        path        => $path,
        require     => [File[$venv_dir, $pythonel_helper], Class[$interpreter_class], Anchor[$interpreter], Exec["create_python_virtualenv_${venv_dir}"]],
        user        => $owner,
      }

    }
  } elsif $ensure == 'absent' {

    file { $venv_dir:
      ensure  => absent,
      force   => true,
      recurse => true,
      purge   => true,
    }

  }
}
