#!/usr/bin/env rspec

require 'spec_helper'
require 'puppet/util/interactive_shell'

describe Puppet::Util::InteractiveShell do
  it 'should initialize with no arguments' do
    subject
  end

  context '#get_command' do
    it 'should read commands from stdin' do
      $stdin.expects(:readline).returns('foo')
      subject.get_command.should == 'foo'
    end

    it 'should return quit when EOF reached' do
      $stdin.expects(:readline).raises(EOFError)
      subject.get_command.should == 'quit'
    end
  end

  context '#interact' do
    it 'should have tests, but hard to test a loop like this'
  end

  context '#prompt' do
    it 'should return a basic prompt at initial context' do
      subject.expects(:print).with('/ > ')
      subject.prompt
    end

    it 'should print a different prompt based on context' do
      subject.context.cwd = ['package']
      subject.expects(:print).with('/package > ')
      subject.prompt
    end
  end

  context '#execute_shell_action' do
    it 'should execute the desired face action based on command' do
      Puppet::Face[:shell, '0.0.1'].expects(:ls).with('package',
        {:context => subject.context})
      subject.execute_shell_action('ls package')
    end

    it 'should return a meaningful console error if command does not exist' do
      Puppet::Face.expects(:find_action).with(:shell, 'foo')
      subject.expects(:puts).with('command not found: foo')
      subject.execute_shell_action('foo')
    end
  end
end
