# Reports the amount of time each Rake task section took when trace is enabled.
module TraceRakeTask
  def execute(*args)
    start = Time.now
    super(*args)
    printf("** Finished %s [%.1f sec]\n", name, Time.now - start)
  end
end
Rake::Task.prepend TraceRakeTask if Rake.application.options.trace
