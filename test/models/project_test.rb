require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert projects(:alpha_for_one).valid?
  end

  test 'requires repo_full_name' do
    p = Project.new(user: users(:one))
    assert_not p.valid?
    assert_includes p.errors[:repo_full_name], "can't be blank"
  end

  test 'uniqueness scoped to user' do
    u = users(:one)
    Project.create!(user: u, repo_full_name: 'alicehub/unique')
    dup = Project.new(user: u, repo_full_name: 'alicehub/unique')
    assert_not dup.valid?, 'duplicate should be invalid for same user'

    other_user = users(:two)
    ok = Project.new(user: other_user, repo_full_name: 'alicehub/unique')
    ok.validate
    assert_empty ok.errors[:repo_full_name], 'allowed for different user'
  end

  test 'topics serialized as JSON' do
    p = projects(:alpha_for_one)
    assert_kind_of Array, p.topics
  end
end

