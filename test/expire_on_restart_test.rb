require 'test_helper'

class RestartExpiratorTest < ActiveSupport::TestCase
  include ExpireOnRestart

  def setup
    path = File.join(Rails.root, 'tmp', '.expire_on_restart')
    File.delete(path) if File.exist?(path)
    @expirator = RestartExpirator.instance
  end

  test "is a singleton" do
    assert RestartExpirator.included_modules.include?(Singleton)
  end

  test "#add creates a file named .expire_on_restart in tmp directory if none exists" do
    assert !File.exist?(File.join(Rails.root, 'tmp', '.expire_on_restart'))
    @expirator.add('some_file')
    assert File.exist?(File.join(Rails.root, 'tmp', '.expire_on_restart'))
  end

  test "#add with a one file" do
    @expirator.add('some_file')
    assert @expirator.files_to_expire.include?('some_file')
  end

  test "#add with multiple files" do
    @expirator.add('some_file', 'another_file')

    assert @expirator.files_to_expire.include?('some_file')
    assert @expirator.files_to_expire.include?('another_file')
  end

  test "#add with array" do
    @expirator.add(['some_file', 'another_file'])

    assert @expirator.files_to_expire.include?('some_file')
    assert @expirator.files_to_expire.include?('another_file')
  end

  test "#add multiple times" do
    @expirator.add('some_file')
    @expirator.add('another_file')

    assert @expirator.files_to_expire.include?('some_file')
    assert @expirator.files_to_expire.include?('another_file')
  end

  test "#expire_marked_files deletes the marked files" do
    File.open(File.join(Rails.root, 'tmp', '.expire_on_restart'), 'w') { |f| f.write("tmp/f0\ntmp/f1") }

    path = File.join(Rails.root, 'tmp', 'f0')
    File.new(File.join(Rails.root, 'tmp', 'f0'), 'w')
    assert File.exist?(path)

    path = File.join(Rails.root, 'tmp', 'f1')
    File.new(File.join(Rails.root, 'tmp', 'f1'), 'w')
    assert File.exist?(path)

    @expirator.expire_marked_files
    assert !File.exist?(File.join(Rails.root, 'tmp', 'f0'))
    assert !File.exist?(File.join(Rails.root, 'tmp', 'f1'))
  end

  test "#expire_marked_files deletes the .expire_on_restart file" do
    path = File.join(Rails.root, 'tmp', '.expire_on_restart')
    File.open(path, 'w') { |f| f.write("tmp/f0\ntmp/f1") }
    @expirator.expire_marked_files
    assert !File.exist?(path)
  end

  test "#files_to_expire returns the files to expire" do
    path = File.join(Rails.root, 'tmp', '.expire_on_restart')
    File.open(path, 'w') { |f| f.write("tmp/f0\ntmp/f1") }
    assert_equal ['tmp/f0', 'tmp/f1'], @expirator.files_to_expire
  end
end

class ExpirationHelperTest < ActiveSupport::TestCase
  include ExpireOnRestart::ExpirationHelper

  def setup
    path = File.join(Rails.root, 'tmp', '.expire_on_restart')
    File.delete(path) if File.exist?(path)
    @expirator = ExpireOnRestart::RestartExpirator.instance
  end

  test "#expire_on_restart appends a file to expire to the .expire_on_restart file" do
    @expirator.expects(:add).with('some_file')
    expire_on_restart('some_file')
  end

  test "#expire_on_restart with multiple files" do
    @expirator.expects(:add).with('some_file', 'another_file')
    expire_on_restart('some_file', 'another_file')
  end
end

class ActionViewExtensionTest < ActionView::TestCase
  include ActionView::Helpers::AssetTagHelper

  def setup
    path = File.join(Rails.root, 'tmp', '.expire_on_restart')
    File.delete(path) if File.exist?(path)
    @expirator = ExpireOnRestart::RestartExpirator.instance
  end

  test "#javascript_include_tag with :cache => true" do
    javascript_include_tag(:all, :cache => true)
    assert @expirator.files_to_expire.include?(File.join('public', 'javascripts', 'all.js'))
  end

  test "#javascript_include_tag with :cache => 'my_cache" do
    javascript_include_tag(:all, :cache => 'my_cache')
    assert @expirator.files_to_expire.include?(File.join('public', 'javascripts', 'my_cache.js'))
  end

  test "#stylesheet_link_tag with :cache => true" do
    stylesheet_link_tag(:all, :cache => true)
    assert @expirator.files_to_expire.include?(File.join('public', 'stylesheets', 'all.css'))
  end

  test "#stylesheet_link_tag with :cache => 'my_cache" do
    stylesheet_link_tag(:all, :cache => 'my_cache')
    assert @expirator.files_to_expire.include?(File.join('public', 'stylesheets', 'my_cache.css'))
  end

  test "#expire_on_restart with arbitrary files" do
    expire_on_restart('file')
    assert @expirator.files_to_expire.include?('file')

    expire_on_restart('another_file', 'one_more_file')
    assert @expirator.files_to_expire.include?('another_file')
    assert @expirator.files_to_expire.include?('one_more_file')
  end
end

class ActionControllerExtensionTest < ActiveSupport::TestCase
  def setup
    path = File.join(Rails.root, 'tmp', '.expire_on_restart')
    File.delete(path) if File.exist?(path)
    @expirator = ExpireOnRestart::RestartExpirator.instance
    @controller = ApplicationController.new
  end

  test "#expire_on_restart with arbitrary files" do
    @controller.expire_on_restart('file')
    assert @expirator.files_to_expire.include?('file')

    @controller.expire_on_restart('another_file', 'one_more_file')
    assert @expirator.files_to_expire.include?('another_file')
    assert @expirator.files_to_expire.include?('one_more_file')
  end
end
