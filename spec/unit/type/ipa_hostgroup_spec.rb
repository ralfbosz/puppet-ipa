#!/usr/bin/ruby -S rspec
#
#  Test the type interface of the ipa_group type.
#
#   Copyright 2016 JD Powell <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#
require 'spec_helper'
require 'type_spec_tests'

# Example:
#ipa_hostgroup { 'puppet_servers':
#  ensure      => 'present',
#  description => 'Puppet Servers',
#}

described_class = Puppet::Type.type(:ipa_hostgroup)

describe described_class, 'type' do
  it_behaves_like 'has ensurable', described_class
  it_behaves_like 'has properties',  described_class,
   [ :description, ]
  it_behaves_like 'has a name', described_class
end
