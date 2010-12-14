require 'bundler'
Bundler::GemHelper.install_tasks

namespace :spec do
  DISPATCH_MSPEC = "./spec/dispatch.mspec"
  DEFAULT_OPTIONS = "-B #{DISPATCH_MSPEC}"
  
  def mspec(type, options, env = nil)
    sh "mspec #{type} #{DEFAULT_OPTIONS} #{ENV['opts']} #{options}"
  end
  
  desc "Run all specs. To run a specific file: rake spec:run[spec/queue_spec.rb]"
  task :run, :file do |t, args|
    mspec :run, args[:file] || "spec"
  end
  
end