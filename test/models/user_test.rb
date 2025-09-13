require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert users(:one).valid?
  end

  test 'name presence' do
    u = User.new(email: 'x@example.com', password: 'password')
    assert_not u.valid?
    assert_includes u.errors[:name], "can't be blank"
  end

  test 'friendly_id slug updates when name changes' do
    u = users(:one)
    old_slug = u.slug
    u.update!(name: 'Alice Cooper')
    assert_not_equal old_slug, u.slug
  end

  test 'associations' do
    u = users(:one)
    assert_respond_to u, :projects
    assert_respond_to u, :domains
  end
end

