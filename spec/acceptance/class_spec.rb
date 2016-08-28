require 'spec_helper_acceptance'

describe 'pythonel' do
  describe 'python35_ius' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      package {['centos-release-scl', 'epel-release']:
        ensure => 'present'
      }
      package {'ius-release':
        ensure   => 'present',
        provider => 'rpm',
        source   => "https://centos${::operatingsystemmajrelease}.iuscommunity.org/ius-release.rpm",
      }
      include pythonel::interpreter::python35_ius
      pythonel::virtualenv { '/tmp/myapp_python35_ius':
        interpreter => 'python35_ius',
        systempkgs  => true,
      } ->
      pythonel::pip { 'myapp-colorama':
        package     => 'colorama',
        virtualenv  => '/tmp/myapp_python35_ius',
        interpreter => 'python35_ius'
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end
    describe package('python35u') do
      it { is_expected.to be_installed }
    end
    describe virtualenv('/tmp/myapp_python35_ius') do
      it { should be_virtualenv }
      its(:pip_freeze) { should include('colorama') }
      its(:python_version) { should match /^3\.5/ }
    end 
  end

  describe 'rh_python34_scl' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      package {'centos-release-scl':
        ensure => 'present'
      }
      include pythonel::interpreter::rh_python34_scl
      pythonel::virtualenv { '/tmp/myapp_rh_python34_scl':
        interpreter => 'rh_python34_scl',
        systempkgs => true,
      } ->
      pythonel::pip { 'myapp-colorama':
        package     => 'colorama',
        virtualenv  => '/tmp/myapp_rh_python34_scl',
        interpreter => 'rh_python34_scl'
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    # we can't use virtualenv serverspec here because you need to run 'scl
    # enable rh-python34' before running any of the commands. the best we can do
    # is check the directory for things that should be there
    describe file('/tmp/myapp_rh_python34_scl') do
      it { should be_directory }
    end

    describe file('/tmp/myapp_rh_python34_scl/bin/python3') do
      it { should exist }
      it { should be_executable }
    end

    describe file('/tmp/myapp_rh_python34_scl/lib/python3.4/site-packages/colorama') do
      it { should be_directory }
    end
  end
end
