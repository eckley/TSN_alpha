namespace :schedule_jobs do

  desc "starts up all scheduled jobs"
  task :start => :environment do
    #TestJob.schedule
    puts 'starting Main(Boinc => StatsGeneral => StatsAlliance) job'
    MainStatsJob.schedule Time.now
    puts 'starting Boinc Copy Update'
    BoincCopyJob.schedule Time.now
    puts 'starting Trophy Update'
    TrophiesJob.schedule Time.now
    puts 'starting elastic search check'
    ElasticSearchJob.schedule Time.now
    puts 'starting galaxy mosaic job'
    #sechudle for 7 days after the last mosaic or now
    puts 'starting galaxy mosiac job'
    last_mosaic = GalaxyMosaic.maximum(:created_at) || (Time.now - 7.days)
    new_mosaic_time = last_mosaic + 7.days
    GalaxyMosaicJob.schedule new_mosaic_time
    end
  desc "stops up all scheduled jobs"
  task :stop => :environment do
    #TestJob.unschedule
    puts 'stopping Boinc Update'
    BoincJob.unschedule
    puts 'stopping Boinc Copy Update'
    BoincCopyJob.unschedule
    puts 'stopping Trophy Update'
    TrophiesJob.unschedule
    puts 'stopping Nereus Update'
    NereusJob.unschedule
    puts 'stopping stats general Update'
    StatsGeneralJob.unschedule
    puts 'stopping stats alliances Update'
    StatsAlliancesJob.unschedule
    puts 'stopping Main job Update'
    MainStatsJob.unschedule
    puts 'starting elastic search check'
    ElasticSearchJob.unschedule
  end
end