#!/usr/bin/env rspec

require 'spec_helper'
require 'puppet/face'

describe Puppet::Face[:shell, '0.0.1'] do
  [:interact].each do |action|
    it { should be_action action }
    it { should respond_to action }
  end
end
