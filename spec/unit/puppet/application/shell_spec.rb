#!/usr/bin/env rspec

require 'spec_helper'
require 'puppet/application/shell'

describe "Puppet::Application::Shell" do
  it "should be a subclass of Puppet::Application::FaceBase" do
    Puppet::Application::Shell.superclass.should equal(Puppet::Application::FaceBase)
  end
end
