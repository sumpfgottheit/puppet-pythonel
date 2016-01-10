class python::interpreter::rh-python34-scl {

	$interpreter = 'rh-python34-scl'
	$bindir      = '/opt/rh/rh-python34/root/usr/bin'
	$packages    = ['rh-python34', 'rh-python34-python-devel', 'rh-python34-python-pip', 'rh-python34-python-virtualenv']

	#
	# Only change if binaries are not called python, pip or virtualenv
	#
	$python 		    = "$bindir/python"
	$pip 				     = "$bindir/pip"
	$virtualenv      = "$bindir/virtualenv"
  $extra_pip_args  = ""
  $base_script_dir = ""


  #
  # Hardly need any changes from here..
  #
  $upgrade_pip            = hiera("python::interpreter::${interpreter}::upgrade_pip", false)
  $upgrade_virtualenv     = hiera("python::interpreter::${interpreter}::upgrade_virtualenv", false)
  $packages_ensure        = hiera("python::interpreter::${interpreter}::packages_ensure", 'present')
	$pip_config_file        = hiera("python::interpreter::${interpreter}::pip_config_file", '')
  $global_pip_config_file = hiera("python::interpreter::pip_config_file", '')

  $_pip_config_file = $pip_config_file ? {
    ''       => $global_pip_config_file,
    default  => $pip_config_file
  }
  $environment = $_pip_config_file ? {
    ''      => [],
    default => [ "PIP_CONFIG_FILE=$pip_config_file"]
  }

	include python::interpreter::prep # Define ppyp_helper
	package { $packages:
		ensure => $packages_ensure
	}

  if $upgrade_pip {
    exec { "upgrade-pip-$interpreter":
      command     => "/usr/local/bin/ppyp_helper $pip install --upgrade pip",
      environment => $environment,
      unless      => "/usr/local/bin/ppyp_helper $pip install --upgrade pip |grep 'Requirement already up-to-date: pip'",
      require     => [File['ppyp_helper'], Package[$packages]]
    }
  }
  if $upgrade_virtualenv {
    exec { "upgrade-virtualenv-$interpreter":
      command => "/usr/local/bin/ppyp_helper $pip install --upgrade virtualenv",
      environment => $environment,
      unless  => "/usr/local/bin/ppyp_helper $pip install --upgrade virtualenv |grep 'Requirement already up-to-date: virtualenv'",
      require => [File['ppyp_helper'], Package[$packages]]
    }
  }



}
