class python::interpreter::system {

	$interpreter = 'system'
	$packages = [ 'python', 'python-devel', 'python-pip' ]
	$bindir = '/usr/bin'
	#
	# No need to change from here
	#
	$python = "$bindir/python"
	$pip =  "$bindir/pip"
	$virtualenv = "$bindir/virtualenv"

	include python::interpreter::prep
	package { $packages:
		ensure => 'present'
	}
	exec { "upgrade-pip-$interpreter":
		command => "/usr/local/bin/ppyp_helper $pip install --upgrade pip",
		unless => "/usr/local/bin/ppyp_helper $pip install --upgrade pip |grep 'Requirement already up-to-date: pip'",
		require => [File['ppyp_helper'], Package[$packages]]
	}
	exec { "upgrade-virtualenv-$interpreter":
		command => "/usr/local/bin/ppyp_helper $pip install --upgrade virtualenv",
		unless => "/usr/local/bin/ppyp_helper $pip install --upgrade virtualenv |grep 'Requirement already up-to-date: virtualenv'",
		require => [File['ppyp_helper'], Package[$packages]]
	}



}
