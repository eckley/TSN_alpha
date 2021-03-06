#
# Recurring Job using Delayed::Job
#
# Setup Your job the "plain-old" DJ (perform) way, include this module
# and Your handler will re-schedule itself every time it succeeds.
#
# Sample :
#
#     class MyJob < Delayed::BaseScheduledJob
#
#       run_every 1.day
#
#       def display_name
#         "MyJob"
#       end
#
#       def perform
#         # code to run ...
#       end
#
#    end
#
# inspired by http://rifkifauzi.wordpress.com/2010/07/29/8/
# then copied from https://gist.github.com/kares/1024726
#

module Delayed
  module ScheduledJob

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        @@logger = Delayed::Worker.logger
        cattr_reader :logger
      end
    end

    def perform_with_schedule
      run_time = Benchmark.realtime do
        perform_without_schedule
      end
      new_start_time = Time.now - run_time + self.class.run_interval
      #report to statsd
      $statsd.gauge("site_stats.background_jobs.#{self.class.to_s.underscore}",run_time)
      schedule! new_start_time unless self.options[:run_once]# note only schedule if job did not raise
    end

    # schedule this "repeating" job
    def schedule!(run_at = nil)
      run_at ||= self.class.run_at
      Delayed::Job.enqueue self, 0, run_at.utc
    end

    # re-schedule this job instance
    def reschedule!
      schedule! Time.now
    end


    module ClassMethods

      def method_added(name)
        if name.to_sym == :perform &&
            ! instance_methods(false).map(&:to_sym).include?(:perform_without_schedule)
          alias_method_chain :perform, :schedule
        end
      end
      #def name
      #  "scheduled_job_" + display_name
      #end
      def run_at
        run_interval.from_now
      end

      def run_interval
        @run_interval ||= 1.hour
      end

      def run_every(time)
        @run_interval = time
      end

      #
      def jobs
        Delayed::Job.where("handler LIKE ?", "%#{name}%")
      end
      def unschedule
        jobs.each {|j| j.destroy}
      end

      def schedule(run_at = nil)
        schedule!(run_at) unless scheduled?
      end

      def schedule!(run_at = nil)
        new.schedule!(run_at)
      end

      def scheduled?
        jobs.count > 0
      end

      def run_once(run_at = nil)
        run_at ||= Time.now
        new(run_once: true).schedule!(run_at) unless scheduled?
      end

    end

  end

end
