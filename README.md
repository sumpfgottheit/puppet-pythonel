# Supported Platforms

- **Enterprise Linux 6**: RHEL6, CentOS6 and clones (not tested)
- **Enterprise Linux 7**: RHEL7, CentOS7 and clones (not tested)

# Why another Puppet-Python module?

* Support of **multiple Python interpreters**, including interpreters from **Software Collections** and the  **IUS** - repository.
* Fully support **Software Collections**, even within **virtualenvs**
* Can easily be used with your **own PyPi mirror** or **YUM mirror**
* Support for **RHEL6/CentOS6**

The [puppet-python module](https://forge.puppetlabs.com/stankevich/python), although great for most requirements, can't fullfill a few of my requirements:

- **RHEL6/CentOS6 Support**: We have a few hundret RHEL6 servers in our company. Bugs like [Issuse 173](https://github.com/stankevich/puppet-python/issues/173) make it difficult to use the origin module.
- **YUM Repository Management**: Our servers are not connected to the internet. Therefore we use a mirror of all YUM repositories we need. We define the YUM Repositories - Ressources once and every module, which needs a repository just needs to `realize` it. If a **RubyOnRails** application needs the **RedHatSoftwareCollections** and a **Python** app also needs this specific respository, the definition of `yumrepo`in each manifest will lead to an error. By defining the repositories once and just realizing it, I can work around this problem. Just don't do YUM-repository management!
- **Software Collections**: The support for SCLs grow steadily within the original repository, but it's not yet there, I think.

# Overview

Every Python interpreter ist defined within `manifest/interpreter/${interpreter}.pp`. As of now, there are 4 interpreters defined:
- **system**: The Python 2.6 interpreter of EL6
- **rh-python27-scl**: The Python 2.7 interpreter of RedHats Software Collections
- **rh-python34-scl**:The Python 3.4 interpreter of RedHats Software Collections
- **python35-scl**: The Python 3.5 interpreter from [IUS](http://ius.io)

To use on of the interpreters, just include it:
```puppet
include pythonel::interpreter::rh-python34-scl
```

By using the `include` construct, every interpreter can included by multiple applications without any problems. The interpreter-manifests installs the interpreter using the `package` ressource, but **without defining a yumrepo ressource**. If you define your repository once, you can put the `Yumrepo <|title = redhat-scl-el6 |>` in the interpreter manifest. The interpreters define some variables that are used by `virtualenv` and `pip` to adapt to the calling interpeter.

The resources `pythonel::pip` and `pythonel::virtualenv` work in a similar way to the original module. `pythonel::pip` has fewer options than the 
original module. This is intened. I think that a simpel requirements-file, that can be used with `pythonel::virtualenv` is better and easier than building
the logic using a puppet resource. Drop your requirements file into your application-directory and let `pythonel::virtualenv` pick it up.

## pythonel_helper
The biggest problem defining python environments via puppet ist the lack of information at catalog compile time. Which python version/pip version combination is available and needs which parameters. It's a big mess. By including a python interpreter, the file `/usr/local/bin/pythonel_helper` ist installed. This helper script takes care of all the crazy, local stuff and helps the `Exec` ressources to stay readable. When calling `pytophon::pip`, the helper-script is called on the node and enables the sofware collection if necessary.

# Usage

```puppet
  # Install the rh-python34-scl interpreter
  include pythonel::interpreter::rh-python34-scl
  
  # Create a virtualenv within /opt/virtualenvs/myapp with the correct interpreter
  # and install the modules from the requirements file
  pythonel::virtualenv { '/opt/virtualenvs/myapp':
    interpreter => 'rh-python34-scl',
    requirements_file => '/opt/myapp/requirements.txt',
    systempkgs => true,
  } ->
  # Install the colorama module into the directory
  # if no virtuelenv is give, install it systemwide
  pythonel::pip { 'myapp-colorama':
    package     => 'colorama',
    virtualenv  => '/opt/virtualenvs/myapp',
    interpreter => 'rh-python34-scl'
  }
```

# YumRepo handling

As our systems have no connection to the internet, the handling of YumRepositories painful. Every interpreter.pp has a section, that starts with 
```
    ################################
    # YumRepo and package handling #
    # Adapt to your needs          #
    ################################
```

Adapt the files and make sure, that the packages are installed.

# Configuration

Each of the `python/manifests/interpreter/${interpreter}.pp` manifests query 5 variables via `hiera`:
```puppet
$upgrade_pip            = hiera("pythonel::interpreter::${interpreter}::upgrade_pip", false)
$upgrade_virtualenv     = hiera("pythonel::interpreter::${interpreter}::upgrade_virtualenv", false)
$packages_ensure        = hiera("pythonel::interpreter::${interpreter}::packages_ensure", 'present')
$pip_config_file        = hiera("pythonel::interpreter::${interpreter}::pip_config_file", '')
$global_pip_config_file = hiera("pythonel::interpreter::pip_config_file", '')
```

Example: For the python interpreter `rh-python34-scl`, you can set the following configartions via hiera
```yaml
# run "pip install --upgrade pip" during installation of the python interpreter
pythonel::interpreter::rh-python34-scl::upgrade_pip: true/false
# run "pip install --upgrade virtualenv" during installation of the python interpreter
pythonel::interpreter::rh-python34-scl::upgrade_upgrade_virtualenv: true/false
# set package=>ensure to "latest" or "present"
pythonel::interpreter::rh-python34-scl::package_ensure: present/latest
# Set an explicit 'PIP_CONFIG_FILE' for this interpreter
pythonel::interpreter::rh-python34-scl::pip_config_file: /etc/pip-rh-python34-scl.conf
```

Often, you want to use a `PIP_CONFIG_FILE` for all interpreters on a system, for example to let it point to you internal Pypi-mirror. Use the `pythonel::interpreter::pip_config_file` hiera-variable. An interpreter-specific `PIP_CONFIG_FILE` has precedence over the global file.

```puppet
pythonel::interpreter::pip_config_file: /etc/pip.conf
```
If you manage the pip.conf via puppet, you can set the metaparameter `before => File['/usr/local/bin/pythonel_helper` to have your `pip.conf` inplace before the interpreter is configured. The file `/usr/local/bin/pppy_helper` is installed in `manifests/interpreter/prep.pp` and every `pip` or `virtualenv` call has a `require =>` to this file.

## Tests

Most of the logic is executed on the local node by `pythonel_helper`, so rspec-tests don't help much and there is no need for trivial tests. So no -
there are no tests.

## pythonel_helper - help
```
 # pythonel_helper

usage: pythonel_helper pip [-v virtualenv] [-s] PIP-ARGS
       pythonel_helper virtualenv [-s] VIRTUALENV-ARGS

pythonel_helper pip:
  Execute pip from the environment [-v]. If the environment is created
  using software collections (scl), enable the collection first.
  The [-s] "source" option sets the parameter --no-use-wheel|--no-binary :all:
  according to the used version of pip.
  If the "pip" command is used with full path and the path resides within a
  software collection, the scl is enabled.

pythonel_helper virtualenv:
  Create a new virtualenv. If the "virtualenv" command is used with full path 
  and the path resides within a software collection, the scl is enabled.
  The parameter [-s] enables the system-site-packages.


Options for "pip" command:
   -v virtualenv   The path to the virtualenv to use. 
   -s              Install source packages. adapts the arguments to add
                   "--no-use-wheel" or the new "--no-binary :all:" if 
                   possible. RHEL6/CentOS stock pip 1.3.1 doesn't have
                   whell support out of the box, so this option breaks
                   it anyways.

Options for "virtualenv" command:
    -s             Enable system-site-packages

Correctly uses SCLs (Software Collections) !!!

Examples:
  pythonel_helper pip install flask
    Install flask for the default system python interpreter

  pythonel_helper pip -v /myvenv -s flask
    Install flask for the Environment /myvenv and don't use binaries.
    SCLs are enabled if necessary

  pythonel_helper /opt/rh/rh-python34/root/usr/bin/pip install flask
    Install flask into the system-site-packages of the 
    rh-python34 scl interpreter.

  pythonel_helper virtualenv /myvenv
    Create the virtualenv /myvenv from the default virtualenv-command

  pythonel_helper /opt/rh/rh-python34/root/usr/bin/virtualenv  /myvenv
    Create the virtualenv /myvenv for the rh-python34 scl interpreter

