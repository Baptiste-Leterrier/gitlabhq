require 'prometheus/client'
require 'prometheus/client/support/unicorn'

Prometheus::Client.configure do |config|
  config.logger = Rails.logger

  config.initial_mmap_file_size = 4 * 1024
  config.multiprocess_files_dir = ENV['prometheus_multiproc_dir']

  if Rails.env.development? || Rails.env.test?
    config.multiprocess_files_dir ||= Rails.root.join('tmp/prometheus_multiproc_dir')
  end

  config.pid_provider = -> do
    wid = Prometheus::Client::Support::Unicorn.worker_id
    wid = Process.pid if wid.nil?
    if wid.nil?
      "process_pid_#{Process.pid}"
    else
      "worker_id_#{wid}"
    end
  end
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Gitlab::Metrics::SidekiqMetricsExporter.instance.start
  end
end

if Gitlab::Metrics.prometheus_metrics_enabled?
  unless Sidekiq.server?
    Gitlab::Metrics::Samplers::UnicornSampler.initialize_instance(Settings.monitoring.unicorn_sampler_interval).start
  end

  Gitlab::Metrics::Samplers::RubySampler.initialize_instance(Settings.monitoring.ruby_sampler_interval).start
end
