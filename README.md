# Why another Puppet-Python module?

# Configuration

Each of the `python/manifests/interpreter/${interpreter}.pp` manifests query 5 variables via `hiera`:
```puppet
$upgrade_pip            = hiera("python::interpreter::${interpreter}::upgrade_pip", false)
$upgrade_virtualenv     = hiera("python::interpreter::${interpreter}::upgrade_virtualenv", false)
$packages_ensure        = hiera("python::interpreter::${interpreter}::packages_ensure", 'present')
$pip_config_file        = hiera("python::interpreter::${interpreter}::pip_config_file", '')
$global_pip_config_file = hiera("python::interpreter::pip_config_file", '')
```

Example: For the python interpreter `rh-python34-scl`, you can set the following configartions via hiera
```yaml
# run "pip install --upgrade pip" during installation of the python interpreter
python::interpreter::rh-python34-scl::upgrade_pip: true/false
# run "pip install --upgrade virtualenv" during installation of the python interpreter
python::interpreter::rh-python34-scl::upgrade_upgrade_virtualenv: true/false
# set package=>ensure to "latest" or "present"
python::interpreter::rh-python34-scl::package_ensure: present/latest
# Set an explicit 'PIP_CONFIG_FILE' for this interpreter
python::interpreter::rh-python34-scl::pip_config_file: /etc/pip-rh-python34-scl.conf
```

Often, you want to use a `PIP_CONFIG_FILE` for all interpreters on a system, for example to let it point to you internal Pypi-mirror. Use the `python::interpreter::pip_config_file` hiera-variable. An interpreter-specific `PIP_CONFIG_FILE` has precedence over the global file.

```puppet
python::interpreter::pip_config_file: /etc/pip.conf
```
If you manage the pip.conf via puppet, you can set the metaparameter `before => File['/usr/local/bin/ppyp_helper` to have your `pip.conf` inplace before the interpreter is configured. The file `/usr/local/bin/pppy_helper` is installed in `manifests/interpreter/prep.pp` and every `pip` or `virtualenv` call has a `require =>` to this file.


