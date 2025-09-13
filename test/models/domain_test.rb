require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert domains(:one_domain).valid?
  end

  test 'requires host' do
    d = Domain.new(user: users(:one))
    assert_not d.valid?
    assert_includes d.errors[:host], "can't be blank"
  end

  test 'uniqueness of host' do
    Domain.create!(user: users(:one), host: 'dup.example.com')
    dup = Domain.new(user: users(:two), host: 'dup.example.com')
    assert_not dup.valid?
  end
end

