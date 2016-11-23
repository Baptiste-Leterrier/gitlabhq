RSpec.configure do |config|
  def builds_path
    Rails.root.join('tmp/tests/builds')
  end

  config.before(:suite) do
    Settings.gitlab_ci['builds_path'] = builds_path
  end

  config.before(:each) do
    FileUtils.mkdir_p(builds_path)
  end

  config.after(:each) do
    FileUtils.rm_rf(builds_path)
  end
end
