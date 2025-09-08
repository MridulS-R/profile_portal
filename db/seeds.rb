
if User.count.zero?
  u = User.create!(email: "admin@example.com", password: "password", name: "Site Owner", github_username: ENV.fetch("SITE_OWNER_GITHUB", "octocat"))
  puts "Created default user: #{u.email} / password"
end
